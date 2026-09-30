import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.117.2";

const cors={
  "Access-Control-Allow-Origin":"*",
  "Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type"
};
const json=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{...cors,"Content-Type":"application/json"}});

Deno.serve(async(req)=>{
  if(req.method==="OPTIONS") return new Response("ok",{headers:cors});
  if(req.method!=="POST") return json({error:"Method not allowed"},405);
  try{
    const auth=req.headers.get("Authorization")||"";
    if(!auth.startsWith("Bearer ")) return json({error:"Authentication required"},401);

    const url=Deno.env.get("SUPABASE_URL")!;
    const anon=Deno.env.get("SUPABASE_ANON_KEY")!;
    const service=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const userClient=createClient(url,anon,{global:{headers:{Authorization:auth}}});
    const admin=createClient(url,service);

    const body=await req.json();
    const orderId=body?.order_id;
    const successUrl=body?.success_url;
    const cancelUrl=body?.cancel_url;
    if(!orderId||!successUrl||!cancelUrl) return json({error:"order_id, success_url and cancel_url are required"},400);
    if(new URL(successUrl).protocol!=="https:"||new URL(cancelUrl).protocol!=="https:") return json({error:"Payment return URLs must use HTTPS"},400);

    const gatewayBase=(Deno.env.get("PAYMENT_GATEWAY_BASE_URL")||"").replace(/\/$/,"");
    const gatewayKey=Deno.env.get("PAYMENT_GATEWAY_API_KEY")||"";
    const yocoSecret=Deno.env.get("YOCO_SECRET_KEY")||"";
    const provider=gatewayBase&&gatewayKey?"custom":yocoSecret?"yoco":"";

    if(!provider) return json({error:"No payment gateway is configured yet."},503);

    const {data,error}=await userClient.rpc("prepare_payment_session",{p_order_id:orderId,p_provider:provider});
    if(error) throw error;

    if(provider==="custom"){
      const webhookUrl=url+"/functions/v1/payment-webhook";
      const response=await fetch(gatewayBase+"/v1/checkout/sessions",{
        method:"POST",
        signal:AbortSignal.timeout(15000),
        headers:{
          "Authorization":"Bearer "+gatewayKey,
          "Content-Type":"application/json",
          "Idempotency-Key":data.idempotency_key
        },
        body:JSON.stringify({
          amount_minor:Math.round(Number(data.amount)*100),
          currency:data.currency||"ZAR",
          merchant_reference:String(data.payment_id),
          order_reference:String(data.order_number),
          success_url:successUrl,
          cancel_url:cancelUrl,
          webhook_url:webhookUrl,
          metadata:{
            order_id:data.order_id,
            payment_id:data.payment_id,
            order_number:String(data.order_number),
            source:"SHESHA"
          }
        })
      });
      const result=await response.json().catch(()=>({}));
      if(!response.ok) return json({error:result?.message||result?.error||"Payment gateway could not create a checkout session"},502);

      const redirectUrl=result.checkout_url||result.redirect_url||result.redirectUrl;
      const providerReference=result.id||result.session_id||result.reference||null;
      if(!redirectUrl||new URL(redirectUrl).protocol!=="https:") return json({error:"Payment gateway did not return a secure checkout URL"},502);

      const {error:updateError}=await admin.from("payments").update({
        status:"processing",
        provider_reference:providerReference,
        metadata:{gateway_session:result,provider:"mobicom_pay"}
      }).eq("id",data.payment_id).in("status",["pending","processing"]);
      if(updateError) throw new Error("Could not save the payment session. Please try again.");

      return json({redirectUrl,id:providerReference,provider:"mobicom_pay"});
    }

    const response=await fetch("https://payments.yoco.com/api/checkouts",{
      method:"POST",
        signal:AbortSignal.timeout(15000),
      headers:{"Authorization":"Bearer "+yocoSecret,"Content-Type":"application/json"},
      body:JSON.stringify({
        amount:Math.round(Number(data.amount)*100),
        currency:data.currency||"ZAR",
        successUrl:successUrl,
        cancelUrl:cancelUrl,
        metadata:{orderId:data.order_id,paymentId:data.payment_id,orderNumber:String(data.order_number)}
      })
    });
    const result=await response.json().catch(()=>({}));
    if(!response.ok) return json({error:result?.message||"Fallback checkout could not be created"},502);
    const redirectUrl=result.redirectUrl||result.redirect_url;
    if(!redirectUrl||new URL(redirectUrl).protocol!=="https:") return json({error:"Fallback gateway did not return a secure checkout URL"},502);

    const {error:updateError}=await admin.from("payments").update({
      status:"processing",
      provider_reference:result.id||null,
      metadata:{gateway_session:result,provider:"yoco"}
    }).eq("id",data.payment_id).in("status",["pending","processing"]);
      if(updateError) throw new Error("Could not save the payment session. Please try again.");

    return json({redirectUrl,id:result.id,provider:"yoco"});
  }catch(e){
    if(e instanceof Error && ["TimeoutError","AbortError"].includes(e.name)) return json({error:"Payment gateway timed out. Please retry from your orders."},504);
    return json({error:e instanceof Error?e.message:"Payment error"},400);
  }
});