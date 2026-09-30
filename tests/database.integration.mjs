import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {PGlite} from '@electric-sql/pglite';

await test('fresh schema, customer access, onboarding, stock holds and payment transitions',async(t)=>{
 const db=new PGlite();
 const ids=Array.from({length:6},(_,i)=>'00000000-0000-4000-8000-'+String(i+1).padStart(12,'0'));
 const [owner,a,b,admin,driver,newOwner]=ids;
 const scalar=async(sql,args=[])=>Object.values((await db.query(sql,args)).rows[0])[0];
 const as=async(uid,fn,role='authenticated')=>{await db.query("select set_config('request.jwt.claim.sub',$1,false)",[uid||'']);await db.exec('set role '+role);try{return await fn()}finally{await db.exec('reset role')}};
 try{
  await db.exec("create role anon; create role authenticated; create role service_role bypassrls; create schema auth; create table auth.users(id uuid primary key,raw_user_meta_data jsonb default '{}',phone text); create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$; grant usage on schema auth to anon,authenticated,service_role;");
  await db.exec(await readFile(new URL('../supabase/bootstrap/install.sql',import.meta.url),'utf8'));
  console.log('Database schema and migrations loaded');
  for(const id of ids)await db.query('insert into auth.users(id) values($1)',[id]);
  await db.query("insert into public.user_roles(user_id,role) values($1,'admin')",[admin]);
  const merchant=await scalar("insert into merchants(owner_id,name,slug,status) values($1,'Test store','test-store','approved') returning id",[owner]);
  const branch=await scalar("insert into merchant_branches(merchant_id,name,address_line,town,is_open) values($1,'Main','Test address','Test town',true) returning id",[merchant]);
  const product=await scalar("insert into products(merchant_id,name,price,stock_quantity,track_stock,extras) values($1,'Test product',10,5,true,$2) returning id",[merchant,[{label:'Cheese',price_delta:2}]]);
  let order,payment;
  await t.test('policy helpers allow intended reads and hide private payout fields',async()=>{
   assert.equal(await as(null,()=>scalar('select count(*)::int from products'), 'anon'),1);
   await assert.rejects(()=>as(null,()=>db.query('select payout_details from merchants'),'anon'),/permission denied/);
   assert.equal(await as(a,()=>scalar('select count(*)::int from profiles')),1);
   await assert.rejects(()=>as(a,()=>scalar('select public.admin_set_driver_approval($1,true)',[driver])),/admin required/);
  });
  await t.test('approval fields and payment records cannot be changed directly',async()=>{
   await assert.rejects(()=>as(owner,()=>db.query("update merchants set status='approved' where id=$1",[merchant])),/permission denied/);
   await assert.rejects(()=>as(a,()=>db.query("update payments set status='paid'")),/permission denied/);
   await as(driver,()=>scalar("select submit_driver_application('bicycle',null)"));
   await assert.rejects(()=>as(driver,()=>db.query('update drivers set approved=true where user_id=$1',[driver])),/permission denied/);
  });
  await t.test('merchant application saves store and branch together and cannot self approve',async()=>{
   const details={name:'New store',owner_name:'Test owner',phone:'0123456789',email:'test@example.invalid',address_line:'Test address',town:'Test town',province:'Limpopo',account_last4:'1234',terms:true,category:'Hardware'};
   const mid=await as(newOwner,()=>scalar('select submit_merchant_application($1)',[details]));
   assert.equal(await scalar('select status from merchants where id=$1',[mid]),'submitted');
   assert.equal(await scalar('select count(*)::int from merchant_branches where merchant_id=$1',[mid]),1);
   assert.equal(await as(null,()=>scalar('select count(*)::int from merchants'),'anon'),1);
   await assert.rejects(()=>as(newOwner,()=>scalar('select submit_merchant_application($1)',[details])),/already have a store/);
  });
  await t.test('atomic cart updates use merchant option prices and enforce ownership',async()=>{
   const item=await as(a,()=>scalar('select add_cart_product($1,$2)',[product,[{group:'Extra',label:'Cheese',price_delta:-999}]]));
   await as(a,()=>scalar('select add_cart_product($1,$2)',[product,[{group:'Extra',label:'Cheese',price_delta:-999}]]));
   assert.equal(await scalar('select quantity from cart_items where id=$1',[item]),2);
   assert.equal(Number(await scalar('select option_price_delta from cart_items where id=$1',[item])),2);
   await assert.rejects(()=>as(b,()=>scalar('select set_cart_item_quantity($1,0)',[item])),/not found/);
   const plain=await as(a,()=>scalar('select add_cart_product($1)',[product]));
   await as(a,()=>scalar('select set_cart_item_quantity($1,3)',[plain]));
  });
  await t.test('checkout holds stock across variants and other customers',async()=>{
   await assert.rejects(()=>as(a,()=>scalar('select checkout_cart_v2($1,null)',[branch])),/invalid fulfilment/);
   await assert.rejects(()=>as(a,()=>scalar("select checkout_cart_confirmed($1,'pickup',53)",[branch])),/Prices changed/);
   assert.equal(await scalar('select count(*)::int from orders'),0);
   order=await as(a,()=>scalar("select checkout_cart_confirmed($1,'pickup',54)",[branch]));
   assert.equal(Number(await scalar('select total from orders where id=$1',[order])),54);
   await as(b,()=>scalar('select add_cart_product($1)',[product]));
   await assert.rejects(()=>as(b,()=>scalar("select checkout_cart_v2($1,'pickup')",[branch])),/Not enough stock/);
   payment=(await as(a,()=>scalar("select prepare_payment_session($1,'custom')",[order]))).payment_id;
  });
  await t.test('payment deducts all variants exactly once and duplicate notifications are harmless',async()=>{
   await scalar("select apply_payment_event($1,'provider-1','paid','event-1','payment.paid')",[payment]);
   assert.equal(await scalar('select stock_quantity from products where id=$1',[product]),0);
   const duplicate=await scalar("select apply_payment_event($1,'provider-1','paid','event-1','payment.paid')",[payment]);
   assert.equal(duplicate.duplicate,true);
   await scalar("select apply_payment_event($1,'provider-1','paid','event-2','payment.paid')",[payment]);
   assert.equal(await scalar('select stock_quantity from products where id=$1',[product]),0);
   await assert.rejects(()=>scalar("select apply_payment_event($1,'provider-1','failed','event-3','payment.failed')",[payment]),/invalid payment transition/);
  });
  await t.test('additional payment is flagged and its refund does not refund the fulfilled order',async()=>{
   const extra=await scalar("insert into payments(order_id,provider,amount,idempotency_key) values($1,'custom',54,'second') returning id",[order]);
   await scalar("select apply_payment_event($1,'provider-2','paid','event-4','payment.paid')",[extra]);
   assert.equal((await scalar('select metadata from payments where id=$1',[extra])).reconciliation_required,true);
   await scalar("select apply_payment_event($1,'provider-2','refunded','event-5','payment.refunded')",[extra]);
   assert.equal(await scalar('select status from orders where id=$1',[order]),'paid');
  });
  await t.test('expired holds can be retried only when stock is available',async()=>{
   await db.query('update products set stock_quantity=1 where id=$1',[product]);
   const second=await as(b,()=>scalar("select checkout_cart_v2($1,'pickup')",[branch]));
   await db.query("update orders set inventory_hold_until=now()-interval '1 second' where id=$1",[second]);
   await db.query('update products set stock_quantity=0 where id=$1',[product]);
   await assert.rejects(()=>as(b,()=>scalar("select prepare_payment_session($1,'custom')",[second])),/out of stock/);
  });
  await t.test('late paid receipt is recorded and a stock shortfall requires restocking',async()=>{
   const lateOrder=await scalar("select id from orders where customer_id=$1 and status='pending_payment' order by created_at desc limit 1",[b]);
   const latePayment=await scalar("insert into payments(order_id,provider,amount,status,idempotency_key) values($1,'custom',10,'cancelled','late') returning id",[lateOrder]);
   await scalar("select apply_payment_event($1,'late-provider','paid','late-event','payment.paid')",[latePayment]);
   assert.equal(await scalar('select status from orders where id=$1',[lateOrder]),'paid');
   assert.equal((await scalar('select inventory_issue from orders where id=$1',[lateOrder]))[0].quantity,1);
   await assert.rejects(()=>as(owner,()=>scalar("select merchant_advance_order($1,'merchant_confirmed')",[lateOrder])),/inventory review/);
   await assert.rejects(()=>as(admin,()=>scalar('select admin_resolve_inventory_issue($1)',[lateOrder])),/Restock/);
   await db.query('update products set stock_quantity=2 where id=$1',[product]);
   await as(admin,()=>scalar('select admin_resolve_inventory_issue($1)',[lateOrder]));
   assert.equal(await scalar('select stock_quantity from products where id=$1',[product]),1);
   await as(owner,()=>scalar("select merchant_advance_order($1,'merchant_confirmed')",[lateOrder]));
  });
  await t.test('offered drivers can read offered orders but suspended and busy drivers cannot accept',async()=>{
   const delivery=await scalar("insert into orders(customer_id,merchant_id,branch_id,status,subtotal,total) values($1,$2,$3,'ready_for_pickup',10,10) returning id",[a,merchant,branch]);
   const offer=await scalar("insert into dispatch_offers(order_id,driver_id,status,expires_at) values($1,$2,'offered',now()+interval '10 minutes') returning id",[delivery,driver]);
   assert.equal(await as(driver,()=>scalar('select count(*)::int from orders where id=$1',[delivery])),1);
   await assert.rejects(()=>as(driver,()=>scalar('select respond_dispatch_offer($1,true)',[offer])),/approved available driver/);
   await db.query("update drivers set approved=true,state='available' where user_id=$1",[driver]);
   await as(driver,()=>scalar('select respond_dispatch_offer($1,true)',[offer]));
   await assert.rejects(()=>as(driver,()=>scalar('select set_driver_availability(true)')),/active delivery/);
   const other=await scalar("insert into orders(customer_id,merchant_id,branch_id,status,subtotal,total) values($1,$2,$3,'ready_for_pickup',10,10) returning id",[a,merchant,branch]);
   const secondOffer=await scalar("insert into dispatch_offers(order_id,driver_id,status,expires_at) values($1,$2,'offered',now()+interval '10 minutes') returning id",[other,driver]);
   await assert.rejects(()=>as(driver,()=>scalar('select respond_dispatch_offer($1,true)',[secondOffer])),/approved available driver/);
  });
 }finally{await db.close()}
});
