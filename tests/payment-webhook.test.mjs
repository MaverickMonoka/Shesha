import test from 'node:test';
import assert from 'node:assert/strict';
import {createHmac,webcrypto} from 'node:crypto';
import {readFile} from 'node:fs/promises';
import {transform} from 'esbuild';
const source=(await readFile(new URL('../supabase/functions/payment-webhook/index.ts',import.meta.url),'utf8')).replace(/^import .*;$/gm,'');
const {code}=await transform(source,{loader:'ts',format:'cjs'});
function setup({rpcError=null}={}){
 let handler;const calls=[];const env={PAYMENT_GATEWAY_WEBHOOK_SECRET:'test-secret',SUPABASE_URL:'https://test.supabase.co',SUPABASE_SERVICE_ROLE_KEY:'test'};
 const client={from:()=>({select:()=>({eq:()=>({maybeSingle:async()=>({data:{id:'payment',amount:10,currency:'ZAR',status:'processing'}})})})}),rpc:async(name,args)=>{calls.push({name,args});return {data:{ok:true},error:rpcError}}};
 Function('Deno','createClient','crypto',code)({env:{get:key=>env[key]},serve:fn=>handler=fn},()=>client,webcrypto);
 return {handler,calls};
}
const input={event_id:'event-1',event_type:'payment.paid',data:{merchant_reference:'payment',id:'processor-1',status:'paid',amount_minor:1000,currency:'ZAR'}};
function request(body=input,signatureOverride){const raw=JSON.stringify(body);const signature=signatureOverride??'sha256='+createHmac('sha256','test-secret').update(raw).digest('hex');return new Request('https://edge.example',{method:'POST',headers:{'x-mobicom-signature':signature},body:raw})}
test('authentic exact payment events reach the transactional payment handler',async()=>{const {handler,calls}=setup();assert.equal((await handler(request())).status,200);assert.equal(calls.length,1);assert.equal(calls[0].args.p_status,'paid');});
test('invalid or missing signatures cannot change payment state',async()=>{const {handler,calls}=setup();assert.equal((await handler(request(input,'sha256=invalid'))).status,401);assert.equal((await handler(request(input,''))).status,401);assert.equal(calls.length,0);});
test('missing, fractional, or incorrect amount and missing currency are rejected',async()=>{const {handler,calls}=setup();for(const data of [{...input.data,amount_minor:undefined},{...input.data,amount_minor:1000.5},{...input.data,amount_minor:999},{...input.data,currency:undefined},{...input.data,currency:'USD'}])assert.equal((await handler(request({...input,data}))).status,400);assert.equal(calls.length,0);});
test('unknown status is rejected rather than silently becoming pending',async()=>{const {handler,calls}=setup();assert.equal((await handler(request({...input,data:{...input.data,status:'unknown'}}))).status,400);assert.equal(calls.length,0);});
test('cancelled events retain their meaning',async()=>{const {handler,calls}=setup();assert.equal((await handler(request({...input,data:{...input.data,status:'cancelled'}}))).status,200);assert.equal(calls[0].args.p_status,'cancelled');});
test('database errors produce a retryable response',async()=>{const {handler}=setup({rpcError:{message:'temporarily unavailable'}});assert.equal((await handler(request())).status,503);});
