import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const json=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{"Content-Type":"application/json"}});
const hex=(bytes:ArrayBuffer)=>[...new Uint8Array(bytes)].map(b=>b.toString(16).padStart(2,"0")).join("");
const safeEqual=(a:string,b:string)=>{
  if(a.length!==b.length) return false;
  let out=0;
  for(let i=0;i<a.length;i++) out|=a.charCodeAt(i)^b.charCodeAt(i);
  return out===0;
};

Deno.serve(async(req)=>{
  if(req.method!=="POST") return json({error:"Method not allowed"},405);
  try{
    const secret=Deno.env.get("PAYMENT_GATEWAY_WEBHOOK_SECRET")||"";
    if(!secret) return json({error:"Webhook secret is not configured"},503);

    const raw=await req.text();
    const suppliedRaw=req.headers.get("x-mobicom-signature")||req.headers.get("x-gateway-signature")||req.headers.get("x-shesha-signature")||"";
    const supplied=suppliedRaw.replace(/^sha256=/i,"").trim().toLowerCase();
    if(!supplied) return json({error:"Missing webhook signature"},401);

    const key=await crypto.subtle.importKey("raw",new TextEncoder().encode(secret),{name:"HMAC",hash:"SHA-256"},false,["sign"]);
    const expected=hex(await crypto.subtle.sign("HMAC",key,new TextEncoder().encode(raw)));
    if(!safeEqual(expected,supplied)) return json({error:"Invalid webhook signature"},401);

    const body=JSON.parse(raw);
    const data=body?.data||body;
    const eventId=String(body?.event_id||body?.id||req.headers.get("x-gateway-event-id")||"");
    const eventType=String(body?.event_type||body?.type||req.headers.get("x-mobicom-event")||"payment.updated");
    const paymentId=String(data?.merchant_reference||data?.payment_id||data?.metadata?.payment_id||"");
    const providerReference=data?.id||data?.provider_reference||data?.reference||null;
    const statusRaw=String(data?.status||body?.status||"").toLowerCase();

    if(!eventId||!paymentId) return json({error:"Webhook event_id and merchant_reference are required"},400);

    const url=Deno.env.get("SUPABASE_URL")!;
    const service=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const admin=createClient(url,service);

    const {data:payment,error:paymentError}=await admin.from("payments").select("id,amount,currency,status").eq("id",paymentId).maybeSingle();
    if(paymentError||!payment) return json({error:"Payment not found"},404);

    if(data?.currency && String(data.currency).toUpperCase()!==String(payment.currency).toUpperCase()) return json({error:"Currency mismatch"},400);
    if(data?.amount_minor!==undefined){
      const expectedMinor=Math.round(Number(payment.amount)*100);
      if(Number(data.amount_minor)!==expectedMinor) return json({error:"Amount mismatch"},400);
    }

    let mapped:"pending"|"processing"|"paid"|"failed"|"cancelled"|"refunded"|"partially_refunded";
    if(["paid","succeeded","successful","complete","completed"].includes(statusRaw)) mapped="paid";
    else if(["failed","declined","error"].includes(statusRaw)) mapped="failed";
    else if(["cancelled","canceled","voided"].includes(statusRaw)) mapped="cancelled";
    else if(["refunded"].includes(statusRaw)) mapped="refunded";
    else if(["partially_refunded","partial_refund"].includes(statusRaw)) mapped="partially_refunded";
    else if(["processing","authorizing","authorised","authorized"].includes(statusRaw)) mapped="processing";
    else mapped="pending";

    const {data:result,error}=await admin.rpc("apply_payment_event",{
      p_payment_id:paymentId,
      p_provider_reference:providerReference,
      p_status:mapped,
      p_event_id:eventId,
      p_event_type:eventType,
      p_payload:body
    });
    if(error) throw error;

    return json({received:true,...result});
  }catch(e){
    return json({error:e instanceof Error?e.message:"Webhook error"},400);
  }
});