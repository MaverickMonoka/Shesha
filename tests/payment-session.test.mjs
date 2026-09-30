import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {transform} from 'esbuild';

const source=(await readFile(new URL('../supabase/functions/create-payment-session/index.ts',import.meta.url),'utf8')).replace(/^import .*;$/gm,'');
const {code}=await transform(source,{loader:'ts',format:'cjs'});
function setup({updateError=null,redirect='https://pay.example/checkout',fetchError=null}={}){
  let handler;const filters=[];
  const env={SUPABASE_URL:'https://test.supabase.co',SUPABASE_ANON_KEY:'test',SUPABASE_SERVICE_ROLE_KEY:'test',PAYMENT_GATEWAY_BASE_URL:'https://gateway.example',PAYMENT_GATEWAY_API_KEY:'test'};
  const client={rpc:async()=>({data:{payment_id:'payment',amount:12.50,currency:'ZAR',idempotency_key:'key',order_id:'order',order_number:'123'},error:null}),from:()=>({update:()=>({eq:()=>({in:async(column,values)=>{filters.push({column,values});return {error:updateError}}})})})};
  const fetch=async(_url,options)=>{assert.ok(options.signal);assert.equal(JSON.parse(options.body).amount_minor,1250);if(fetchError)throw fetchError;return Response.json({checkout_url:redirect,id:'session'})};
  Function('Deno','createClient','fetch',code)({env:{get:key=>env[key]},serve:fn=>handler=fn},()=>client,fetch);
  return {handler,filters};
}
const request=(overrides={})=>new Request('https://edge.example',{method:'POST',headers:{Authorization:'Bearer test','Content-Type':'application/json'},body:JSON.stringify({order_id:'order',success_url:'https://shop.example/orders',cancel_url:'https://shop.example/orders',...overrides})});
test('session uses trusted amount and cannot overwrite paid or failed payments',async()=>{const {handler,filters}=setup();const response=await handler(request());assert.equal(response.status,200);assert.deepEqual(filters,[{column:'status',values:['pending','processing']}]);});
test('payment storage failure is reported',async()=>{const {handler}=setup({updateError:{message:'failed'}});assert.equal((await handler(request())).status,400);});
test('insecure return and checkout URLs are rejected',async()=>{assert.equal((await setup().handler(request({success_url:'http://shop.example'}))).status,400);assert.equal((await setup({redirect:'http://pay.example'}).handler(request())).status,502);});
test('provider timeout returns a retryable timeout response',async()=>{const error=new Error('timeout');error.name='TimeoutError';assert.equal((await setup({fetchError:error}).handler(request())).status,504);});
test('wrong method and missing authentication are rejected',async()=>{const {handler}=setup();assert.equal((await handler(new Request('https://edge.example'))).status,405);assert.equal((await handler(new Request('https://edge.example',{method:'POST'}))).status,401);});
