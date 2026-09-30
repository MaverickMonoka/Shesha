-- Fix policy helper access while keeping privileged operations behind checked RPCs.
grant execute on function public.is_admin(), public.can_manage_merchant(uuid) to anon, authenticated;
revoke truncate, references, trigger on all tables in schema public from anon, authenticated;
revoke insert, update, delete on all tables in schema public from anon;
revoke insert, update, delete on public.drivers, public.orders, public.order_items, public.payments, public.payment_events, public.dispatch_offers, public.deliveries, public.user_roles from authenticated;
revoke insert, update, delete on public.merchants from authenticated;
grant update(name,slug,description,category,logo_url,banner_url,phone,email,merchant_mode,supports_pickup,supports_delivery,whatsapp_number,township_section,landmark,ordering_features) on public.merchants to authenticated;
grant update(vehicle_type,vehicle_registration) on public.drivers to authenticated;
revoke select on public.merchants from anon, authenticated;
grant select(id,name,slug,description,category,status,logo_url,banner_url,phone,email,merchant_mode,supports_pickup,supports_delivery,whatsapp_number,township_section,landmark,is_demo) on public.merchants to anon, authenticated;
grant select(owner_id,created_at,updated_at) on public.merchants to authenticated;

drop policy "products public read" on public.products;
create policy "products public read" on public.products for select using (
  (is_active and exists(select 1 from public.merchants m where m.id=merchant_id and m.status='approved'))
  or public.can_manage_merchant(merchant_id)
);
drop policy "branches public read" on public.merchant_branches;
create policy "branches public read" on public.merchant_branches for select using (
  (is_active and exists(select 1 from public.merchants m where m.id=merchant_id and m.status='approved'))
  or public.can_manage_merchant(merchant_id)
);

alter table public.orders add column inventory_hold_until timestamptz;
alter table public.orders alter column inventory_hold_until set default (now()+interval '45 minutes');
alter table public.orders add column inventory_issue jsonb not null default '[]';
create index orders_active_inventory_holds_idx on public.orders(inventory_hold_until) where status='pending_payment';

create or replace function public.submit_merchant_application(p_details jsonb)
returns uuid language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); mid uuid; business_name text:=trim(p_details->>'name');
begin
 if uid is null then raise exception 'Authentication required'; end if;
 perform 1 from public.profiles where id=uid for update;
 if exists(select 1 from public.merchants where owner_id=uid) then raise exception 'You already have a store. Open your merchant centre.'; end if;
 if jsonb_typeof(p_details) is distinct from 'object' or coalesce((p_details->>'terms')::boolean,false) is not true then raise exception 'Confirm your application details'; end if;
 if coalesce(business_name,'')='' or coalesce(trim(p_details->>'owner_name'),'')='' or coalesce(trim(p_details->>'phone'),'')='' or coalesce(trim(p_details->>'email'),'')='' or coalesce(trim(p_details->>'address_line'),'')='' or coalesce(trim(p_details->>'town'),'')='' then raise exception 'Complete your business and location details'; end if;
 if coalesce(p_details->>'account_last4','') !~ '^[0-9]{4}$' then raise exception 'Enter the last four account digits'; end if;
 insert into public.merchants(owner_id,name,slug,category,phone,email,owner_name,registration_number,merchant_mode,whatsapp_number,status,terms_accepted_at,onboarding_completed_at,payout_details)
 values(uid,business_name,trim(both '-' from regexp_replace(lower(business_name),'[^a-z0-9]+','-','g'))||'-'||substr(gen_random_uuid()::text,1,8),p_details->>'category',p_details->>'phone',p_details->>'email',p_details->>'owner_name',nullif(p_details->>'registration_number',''),p_details->>'category',p_details->>'phone','submitted',now(),now(),jsonb_build_object('bank_name',p_details->>'bank_name','account_holder',p_details->>'account_holder','account_last4',p_details->>'account_last4'))
 returning id into mid;
 insert into public.merchant_branches(merchant_id,name,address_line,suburb_village,town,province,landmark,phone,is_open,is_active)
 values(mid,business_name||' Main',p_details->>'address_line',p_details->>'suburb_village',p_details->>'town',p_details->>'province',nullif(p_details->>'landmark',''),coalesce(nullif(p_details->>'branch_phone',''),p_details->>'phone'),true,true);
 return mid;
end $$;
create or replace function public.submit_driver_application(p_vehicle text,p_registration text default null)
returns void language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid();
begin
 if uid is null then raise exception 'Authentication required'; end if;
 if p_vehicle is null or p_vehicle not in ('scooter','motorcycle','bicycle','car','bakkie','tuk-tuk') then raise exception 'Invalid vehicle type'; end if;
 perform 1 from public.profiles where id=uid for update;
 if exists(select 1 from public.drivers where user_id=uid and approved) then raise exception 'You are already approved. Open the driver centre.'; end if;
 insert into public.drivers(user_id,vehicle_type,vehicle_registration)
 values(uid,p_vehicle,nullif(trim(p_registration),''))
 on conflict(user_id) do update set vehicle_type=excluded.vehicle_type,vehicle_registration=excluded.vehicle_registration;
end $$;

create or replace function public.add_cart_product(p_product_id uuid,p_options jsonb default '[]')
returns uuid language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); product public.products; cart public.carts; cleaned jsonb; delta numeric; item_id uuid;
begin
 if uid is null then raise exception 'Authentication required'; end if;
 perform 1 from public.profiles where id=uid for update;
 select * into product from public.products where id=p_product_id and is_active;
 if product.id is null or not exists(select 1 from public.merchants where id=product.merchant_id and status='approved') then raise exception 'Product is unavailable'; end if;
 delta:=public.validated_option_delta(p_options,product.preparation_options,product.extras,product.pack_sizes);
 select coalesce(jsonb_agg(jsonb_build_object('group',choice->>'group','label',choice->>'label','price_delta',coalesce((configured->>'price_delta')::numeric,0)) order by choice->>'group',choice->>'label'),'[]')
 into cleaned
 from jsonb_array_elements(p_options) choice
 cross join lateral jsonb_array_elements(case choice->>'group' when 'Preparation' then product.preparation_options when 'Pack size' then product.pack_sizes else product.extras end) configured
 where configured->>'label'=choice->>'label';
 insert into public.carts(customer_id,merchant_id) values(uid,product.merchant_id) on conflict(customer_id) do nothing;
 select * into cart from public.carts where customer_id=uid for update;
 if cart.merchant_id is not null and cart.merchant_id<>product.merchant_id and exists(select 1 from public.cart_items where cart_id=cart.id) then raise exception 'Your cart has items from another store. Complete or empty it first.'; end if;
 update public.carts set merchant_id=product.merchant_id,updated_at=now() where id=cart.id;
 insert into public.cart_items(cart_id,product_id,quantity,selected_options,variant_key,option_price_delta)
 values(cart.id,p_product_id,1,cleaned,cleaned::text,delta)
 on conflict(cart_id,product_id,variant_key) do update set quantity=public.cart_items.quantity+1
 returning id into item_id;
 return item_id;
end $$;
create or replace function public.set_cart_item_quantity(p_item_id uuid,p_quantity integer)
returns void language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); v_cart_id uuid;
begin
 if uid is null then raise exception 'Authentication required'; end if;
 if p_quantity is null or p_quantity<0 or p_quantity>1000 then raise exception 'Invalid quantity'; end if;
 select c.id into v_cart_id from public.carts c where c.customer_id=uid for update;
 if v_cart_id is null or not exists(select 1 from public.cart_items where id=p_item_id and public.cart_items.cart_id=v_cart_id) then raise exception 'Cart item not found'; end if;
 if p_quantity=0 then delete from public.cart_items where id=p_item_id;
 else update public.cart_items set quantity=p_quantity where id=p_item_id; end if;
 if not exists(select 1 from public.cart_items ci where ci.cart_id=v_cart_id) then update public.carts set merchant_id=null where id=v_cart_id; end if;
end $$;

CREATE OR REPLACE FUNCTION public.checkout_cart_v2(p_branch_id uuid, p_fulfillment text, p_address_id uuid DEFAULT NULL::uuid, p_notes text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_uid uuid:=auth.uid(); v_cart public.carts; v_address public.addresses; v_branch public.merchant_branches; v_zone public.delivery_zones;
  v_sub numeric(12,2); v_order uuid; v_min numeric(12,2); v_delivery_fee numeric(12,2):=0; v_distance numeric;
begin
  if v_uid is null then raise exception 'authentication required'; end if;
  if p_fulfillment is null or p_fulfillment not in ('delivery','pickup') then raise exception 'invalid fulfilment type'; end if;
  select * into v_cart from public.carts where customer_id=v_uid for update;
  if v_cart.id is null or v_cart.merchant_id is null then raise exception 'cart is empty'; end if;
  select * into v_branch from public.merchant_branches where id=p_branch_id and merchant_id=v_cart.merchant_id and is_active;
  if v_branch.id is null then raise exception 'invalid branch'; end if;
  if not v_branch.is_open then raise exception 'This store is currently closed. Try again when the merchant reopens.'; end if;
  if not exists(select 1 from public.merchants where id=v_cart.merchant_id and status='approved') then raise exception 'This store is not approved for orders'; end if;
  v_min:=v_branch.min_order;
  perform 1 from public.products p where p.id in (select product_id from public.cart_items where cart_id=v_cart.id) order by p.id for update;
  if p_fulfillment='delivery' then
    if not exists(select 1 from public.merchants where id=v_cart.merchant_id and supports_delivery) then raise exception 'This merchant does not offer delivery'; end if;
    select * into v_address from public.addresses where id=p_address_id and customer_id=v_uid;
    if v_address.id is null then raise exception 'delivery address required'; end if;
    if v_address.latitude is not null and v_address.longitude is not null and v_branch.latitude is not null and v_branch.longitude is not null then
      v_distance:=6371*acos(least(1,greatest(-1,sin(radians(v_address.latitude))*sin(radians(v_branch.latitude))+cos(radians(v_address.latitude))*cos(radians(v_branch.latitude))*cos(radians(v_address.longitude-v_branch.longitude)))));
    end if;
    select * into v_zone from public.delivery_zones dz
    where dz.is_active and (dz.town is null or lower(dz.town)=lower(coalesce(v_address.town,'')))
      and (dz.province is null or lower(dz.province)=lower(coalesce(v_address.province,'')))
      and (v_distance is null or dz.max_distance_km is null or v_distance<=dz.max_distance_km)
    order by case when dz.town is not null then 0 else 1 end,case when dz.province is not null then 0 else 1 end limit 1;
    if v_zone.id is null then raise exception 'Delivery is not available at this address yet. Choose pickup or another address.'; end if;
    v_delivery_fee:=round(v_zone.base_fee+case when v_distance is not null then v_zone.per_km_fee*v_distance else 0 end,2);
  else
    if not exists(select 1 from public.merchants where id=v_cart.merchant_id and supports_pickup) then raise exception 'This merchant does not offer pickup'; end if;
  end if;
  -- Reject the entire cart when any item is unavailable; do not silently drop items.
 if exists (
   select 1 from public.cart_items ci left join public.products p on p.id=ci.product_id
   where ci.cart_id=v_cart.id and (p.id is null or p.merchant_id<>v_cart.merchant_id or not p.is_active or ci.quantity<=0)
 ) then raise exception 'Some cart items are unavailable. Please update your cart.'; end if;
 if exists (
   select 1 from public.cart_items ci join public.products p on p.id=ci.product_id
   where ci.cart_id=v_cart.id and p.track_stock
   group by p.id,p.stock_quantity having sum(ci.quantity)>coalesce(p.stock_quantity,0)-coalesce((select sum(oi.quantity) from public.order_items oi join public.orders o on o.id=oi.order_id where oi.product_id=p.id and o.status='pending_payment' and o.inventory_hold_until>now()),0)
 ) then raise exception 'Not enough stock for this cart. Please reduce quantities.'; end if;
 -- Trigger reprices existing carts using current merchant configuration.
 update public.cart_items set selected_options=selected_options where cart_id=v_cart.id;
 select coalesce(sum((p.price+ci.option_price_delta)*ci.quantity),0) into v_sub
  from public.cart_items ci join public.products p on p.id=ci.product_id
  where ci.cart_id=v_cart.id and p.merchant_id=v_cart.merchant_id and p.is_active and (not p.track_stock or coalesce(p.stock_quantity,0)>=ci.quantity);
  if v_sub<=0 then raise exception 'no valid cart items'; end if;
  if v_sub<v_min then raise exception 'minimum order not met'; end if;
  insert into public.orders(customer_id,merchant_id,branch_id,delivery_address_id,status,subtotal,delivery_fee,service_fee,discount,total,notes,delivery_address_snapshot,fulfillment_type)
  values(v_uid,v_cart.merchant_id,p_branch_id,case when p_fulfillment='delivery' then p_address_id else null end,'pending_payment',v_sub,v_delivery_fee,0,0,v_sub+v_delivery_fee,p_notes,
    case when p_fulfillment='delivery' then to_jsonb(v_address) else '{}'::jsonb end,p_fulfillment) returning id into v_order;
  insert into public.order_items(order_id,product_id,product_name,sku,quantity,unit_price,options_snapshot,line_total)
  select v_order,p.id,p.name,p.sku,ci.quantity,p.price+ci.option_price_delta,ci.selected_options,(p.price+ci.option_price_delta)*ci.quantity
  from public.cart_items ci join public.products p on p.id=ci.product_id
  where ci.cart_id=v_cart.id and p.merchant_id=v_cart.merchant_id and p.is_active and (not p.track_stock or coalesce(p.stock_quantity,0)>=ci.quantity);
  insert into public.order_status_history(order_id,new_status,actor_id,note) values(v_order,'pending_payment',v_uid,'Checkout created: '||p_fulfillment);
  delete from public.cart_items where cart_id=v_cart.id;
  update public.carts set merchant_id=null,updated_at=now() where id=v_cart.id;
  return v_order;
end $function$
;
CREATE OR REPLACE FUNCTION public.prepare_payment_session(p_order_id uuid, p_provider text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_uid uuid:=auth.uid();
  v_order public.orders;
  v_payment public.payments;
  v_key text;
begin
  if v_uid is null then raise exception 'authentication required'; end if;
  if p_provider is null or p_provider not in ('custom','yoco') then raise exception 'invalid payment provider'; end if;

  select * into v_order
  from public.orders
  where id=p_order_id and customer_id=v_uid and status='pending_payment'
  for update;

  if v_order.id is null then raise exception 'payable order not found'; end if;
  perform 1 from public.products p where p.id in (select product_id from public.order_items where order_id=p_order_id) order by p.id for update;
  if exists (
    select 1 from public.order_items oi join public.products p on p.id=oi.product_id where oi.order_id=p_order_id and p.track_stock
    group by p.id,p.stock_quantity
    having sum(oi.quantity)>coalesce(p.stock_quantity,0)-coalesce((select sum(other.quantity) from public.order_items other join public.orders o on o.id=other.order_id where other.product_id=p.id and o.id<>p_order_id and o.status='pending_payment' and o.inventory_hold_until>now()),0)
  ) then raise exception 'Some items are now out of stock. Contact the store or place a new order.'; end if;
  update public.orders set inventory_hold_until=now()+interval '45 minutes' where id=p_order_id;

  select * into v_payment
  from public.payments
  where order_id=p_order_id
    and provider=p_provider
    and status in ('pending','processing')
  order by created_at desc
  limit 1;

  if v_payment.id is null then
    v_key := 'shesha:'||p_order_id::text||':'||p_provider||':'||gen_random_uuid()::text;
    insert into public.payments(order_id,provider,amount,currency,status,idempotency_key)
    values(p_order_id,p_provider,v_order.total,v_order.currency,'pending',v_key)
    returning * into v_payment;
  end if;

  return jsonb_build_object(
    'payment_id',v_payment.id,
    'order_id',v_order.id,
    'order_number',v_order.order_number,
    'amount',v_order.total,
    'currency',v_order.currency,
    'idempotency_key',v_payment.idempotency_key,
    'provider',v_payment.provider
  );
end $function$
;
create or replace function public.checkout_cart(p_address_id uuid,p_branch_id uuid,p_notes text default null)
returns uuid language sql security invoker set search_path='' as $$
 select public.checkout_cart_v2(p_branch_id,'delivery',p_address_id,p_notes)
$$;
CREATE OR REPLACE FUNCTION public.apply_payment_event(p_payment_id uuid, p_provider_reference text, p_status payment_status, p_event_id text, p_event_type text, p_payload jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_payment public.payments;
  v_order public.orders;
  v_existing bigint;
  v_transition_ok boolean:=false;
  v_was_paid boolean:=false;
  v_item record; v_available integer; v_issues jsonb:='[]';
begin
  select id into v_existing
  from public.payment_events
  where provider_event_id=p_event_id;

  if v_existing is not null then
    return jsonb_build_object('ok',true,'duplicate',true);
  end if;

  select * into v_payment
  from public.payments
  where id=p_payment_id
  for update;

  if v_payment.id is null then raise exception 'payment not found'; end if;
  -- Recheck after the row lock so simultaneous duplicate callbacks are harmless.
  if exists(select 1 from public.payment_events where provider_event_id=p_event_id) then
    return jsonb_build_object('ok',true,'duplicate',true);
  end if;
  if p_event_id is null or p_event_id='' then raise exception 'event id required'; end if;

  v_was_paid := v_payment.status in ('paid','partially_refunded','refunded');

  v_transition_ok :=
    p_status = v_payment.status
    or (v_payment.status='pending' and p_status in ('processing','paid','failed','cancelled'))
    or (v_payment.status='processing' and p_status in ('paid','failed','cancelled'))
    or (v_payment.status in ('failed','cancelled') and p_status='paid')
    or (v_payment.status='paid' and p_status in ('partially_refunded','refunded'))
    or (v_payment.status='partially_refunded' and p_status='refunded');

  if not v_transition_ok then
    raise exception 'invalid payment transition: % -> %',v_payment.status,p_status;
  end if;

  update public.payments
  set provider_reference=case when v_was_paid then provider_reference else coalesce(p_provider_reference,provider_reference) end,
      status=p_status,
      updated_at=now(),
      metadata=coalesce(metadata,'{}'::jsonb) ||
        jsonb_build_object('last_event_type',p_event_type,'last_event_at',now())
  where id=v_payment.id
  returning * into v_payment;

  insert into public.payment_events(payment_id,provider_event_id,event_type,payload)
  values(v_payment.id,p_event_id,p_event_type,coalesce(p_payload,'{}'::jsonb));

  select * into v_order
  from public.orders
  where id=v_payment.order_id
  for update;

  if p_status='paid' and not v_was_paid and v_order.status='pending_payment' then
    -- Lock products in a stable order; aggregate all variants before decrementing.
    perform 1 from public.products p where p.id in (select product_id from public.order_items where order_id=v_order.id) order by p.id for update;
    for v_item in
      select p.id,p.name,coalesce(p.stock_quantity,0) as available,sum(oi.quantity)::integer as quantity
      from public.order_items oi join public.products p on p.id=oi.product_id
      where oi.order_id=v_order.id and p.track_stock group by p.id,p.name,p.stock_quantity
    loop
      v_available:=v_item.available;
      if v_available<v_item.quantity then
        v_issues:=v_issues||jsonb_build_array(jsonb_build_object('product_id',v_item.id,'product_name',v_item.name,'quantity',v_item.quantity-v_available));
      end if;
      update public.products set stock_quantity=greatest(0,v_available-v_item.quantity),updated_at=now() where id=v_item.id;
    end loop;
    update public.orders set status='paid',inventory_hold_until=null,inventory_issue=v_issues,updated_at=now() where id=v_order.id;
    insert into public.order_status_history(order_id,previous_status,new_status,note)
    values(v_order.id,'pending_payment','paid','Payment confirmed by gateway');
    if jsonb_array_length(v_issues)>0 then
      insert into public.notifications(user_id,title,body)
      select user_id,'Paid order needs stock review','Order #'||v_order.order_number||' has a stock shortfall. Restock or arrange a refund before fulfilment.'
      from public.user_roles where role in ('admin','super_admin') group by user_id;
    end if;
  elsif p_status='paid' and ((not v_was_paid and v_order.status<>'pending_payment') or (v_was_paid and p_provider_reference is distinct from v_payment.provider_reference)) then
    update public.payments set metadata=metadata||jsonb_build_object('reconciliation_required',true,'additional_provider_reference',p_provider_reference) where id=v_payment.id;
    insert into public.notifications(user_id,title,body)
    select user_id,'Payment reconciliation required','Order #'||v_order.order_number||' received an additional or late payment. Review before refunding.'
    from public.user_roles where role in ('admin','super_admin') group by user_id;
  elsif p_status='refunded' and v_order.status not in ('cancelled','refunded') and not exists(select 1 from public.payments where order_id=v_order.id and id<>v_payment.id and status in ('paid','partially_refunded')) then
    update public.orders set status='refunded',updated_at=now() where id=v_order.id;
    insert into public.order_status_history(order_id,previous_status,new_status,note)
    values(v_order.id,v_order.status,'refunded','Payment refunded by gateway');
  end if;

  return jsonb_build_object(
    'ok',true,
    'duplicate',false,
    'order_id',v_order.id,
    'order_status',(select status from public.orders where id=v_order.id),
    'payment_status',v_payment.status
  );
end
$function$
;
create or replace function public.admin_resolve_inventory_issue(p_order_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare o public.orders; issue jsonb;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Administrator access required'; end if;
 select * into o from public.orders where id=p_order_id for update;
 if o.id is null or o.status<>'paid' then raise exception 'Paid order required'; end if;
 perform 1 from public.products p where p.id in (select (value->>'product_id')::uuid from jsonb_array_elements(o.inventory_issue)) order by p.id for update;
 for issue in select value from jsonb_array_elements(o.inventory_issue) loop
   update public.products set stock_quantity=stock_quantity-(issue->>'quantity')::integer,updated_at=now()
   where id=(issue->>'product_id')::uuid and stock_quantity>=(issue->>'quantity')::integer;
   if not found then raise exception 'Restock the missing items before resolving this order'; end if;
 end loop;
 update public.orders set inventory_issue='[]',updated_at=now() where id=p_order_id;
 insert into public.audit_logs(actor_id,action,entity_type,entity_id,metadata)
 values(auth.uid(),'inventory_issue_resolved','order',p_order_id,jsonb_build_object('shortfall',o.inventory_issue));
end $$;
CREATE OR REPLACE FUNCTION public.merchant_advance_order(p_order_id uuid, p_status order_status)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  o public.orders%rowtype;
  allowed boolean:=false;
begin
  select * into o from public.orders where id=p_order_id for update;
  if o.id is null then raise exception 'Order not found'; end if;
  if not public.can_manage_merchant(o.merchant_id) then raise exception 'Not authorised for this merchant'; end if;
  if jsonb_array_length(o.inventory_issue)>0 then raise exception 'This paid order needs inventory review before fulfilment'; end if;

  allowed := (o.status='paid' and p_status='merchant_confirmed')
          or (o.status='merchant_confirmed' and p_status='preparing')
          or (o.status='preparing' and p_status='ready_for_pickup');
  if not allowed then raise exception 'Invalid merchant order transition from % to %',o.status,p_status; end if;

  update public.orders set status=p_status,updated_at=now() where id=p_order_id;
  insert into public.order_status_history(order_id,previous_status,new_status,actor_id,note)
  values(p_order_id,o.status,p_status,auth.uid(),'Merchant fulfilment update');

  if p_status='ready_for_pickup' and coalesce(o.fulfillment_type,'delivery')='delivery' then
    insert into public.dispatch_offers(order_id,driver_id,status,expires_at)
    select p_order_id,d.user_id,'offered',now()+interval '10 minutes'
    from public.drivers d
    where d.approved and d.state='available'
    order by d.created_at
    limit 10
    on conflict(order_id,driver_id) do nothing;
  end if;
end $function$
;
-- Public policy helper functions only return booleans. Mutating RPCs require a session and ownership.
revoke execute on function public.submit_merchant_application(jsonb),public.submit_driver_application(text,text),public.add_cart_product(uuid,jsonb),public.set_cart_item_quantity(uuid,integer),public.admin_resolve_inventory_issue(uuid) from public,anon;
grant execute on function public.submit_merchant_application(jsonb),public.submit_driver_application(text,text),public.add_cart_product(uuid,jsonb),public.set_cart_item_quantity(uuid,integer),public.admin_resolve_inventory_issue(uuid) to authenticated,service_role;
revoke execute on function public.validate_cart_item_price() from public,anon,authenticated;
-- Enable the actual tables used by the app's realtime subscriptions.
do $$
declare relation text;
begin
 if exists(select 1 from pg_publication where pubname='supabase_realtime') then
  foreach relation in array array['orders','notifications','driver_locations'] loop
   if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename=relation) then
    execute format('alter publication supabase_realtime add table public.%I',relation);
   end if;
  end loop;
 end if;
end $$;
