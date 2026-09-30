begin;
-- FRESH SUPABASE PROJECT ONLY. Never run against an existing database.
-- Atomic schema-only installation; no business/customer data or secrets.
-- Schema-only baseline exported from SHESHA on 2026-09-30.
-- FRESH SUPABASE PROJECT ONLY. This contains no customer data or credentials.
-- Apply this instead of historical migrations, then apply migrations dated after this baseline.
set local check_function_bodies = off;
set local search_path = public;
create type public."app_role" as enum ('customer','merchant_owner','merchant_staff','driver','admin','super_admin');
create type public."driver_state" as enum ('offline','available','offered_job','assigned','at_pickup','delivering');
create type public."merchant_status" as enum ('draft','submitted','under_review','approved','rejected','suspended');
create type public."order_status" as enum ('pending_payment','paid','merchant_confirmed','preparing','ready_for_pickup','driver_assigned','picked_up','out_for_delivery','delivered','cancelled','refunded');
create type public."payment_status" as enum ('pending','processing','paid','failed','cancelled','refunded','partially_refunded');
create table public."addresses" (
 "id" uuid not null,
 "customer_id" uuid not null,
 "label" text not null,
 "address_line" text not null,
 "suburb_village" text,
 "town" text,
 "province" text,
 "postal_code" text,
 "landmark" text,
 "instructions" text,
 "latitude" numeric(9,6),
 "longitude" numeric(9,6),
 "is_default" boolean not null,
 "created_at" timestamp with time zone not null
);
create table public."audit_logs" (
 "id" bigint generated always as identity not null,
 "actor_id" uuid,
 "action" text not null,
 "entity_type" text not null,
 "entity_id" text,
 "metadata" jsonb not null,
 "created_at" timestamp with time zone not null
);
create table public."cart_items" (
 "id" uuid not null,
 "cart_id" uuid not null,
 "product_id" uuid not null,
 "quantity" integer not null,
 "created_at" timestamp with time zone not null,
 "selected_options" jsonb not null,
 "variant_key" text not null,
 "option_price_delta" numeric(12,2) not null
);
create table public."carts" (
 "id" uuid not null,
 "customer_id" uuid not null,
 "merchant_id" uuid,
 "created_at" timestamp with time zone not null,
 "updated_at" timestamp with time zone not null
);
create table public."deliveries" (
 "id" uuid not null,
 "order_id" uuid not null,
 "driver_id" uuid,
 "pickup_at" timestamp with time zone,
 "delivered_at" timestamp with time zone,
 "proof_url" text,
 "created_at" timestamp with time zone not null
);
create table public."delivery_events" (
 "id" bigint generated always as identity not null,
 "delivery_id" uuid not null,
 "event_type" text not null,
 "latitude" numeric(9,6),
 "longitude" numeric(9,6),
 "metadata" jsonb not null,
 "created_at" timestamp with time zone not null
);
create table public."delivery_zones" (
 "id" uuid not null,
 "name" text not null,
 "town" text,
 "province" text,
 "base_fee" numeric(12,2) not null,
 "per_km_fee" numeric(12,2) not null,
 "max_distance_km" numeric(8,2),
 "is_active" boolean not null
);
create table public."dispatch_offers" (
 "id" uuid not null,
 "order_id" uuid not null,
 "driver_id" uuid not null,
 "status" text not null,
 "offered_at" timestamp with time zone not null,
 "expires_at" timestamp with time zone,
 "responded_at" timestamp with time zone
);
create table public."driver_locations" (
 "driver_id" uuid not null,
 "latitude" numeric(9,6) not null,
 "longitude" numeric(9,6) not null,
 "accuracy_m" numeric(8,2),
 "heading" numeric(6,2),
 "updated_at" timestamp with time zone not null
);
create table public."drivers" (
 "user_id" uuid not null,
 "state" driver_state not null,
 "vehicle_type" text,
 "vehicle_registration" text,
 "approved" boolean not null,
 "current_zone_id" uuid,
 "created_at" timestamp with time zone not null
);
create table public."merchant_branches" (
 "id" uuid not null,
 "merchant_id" uuid not null,
 "name" text not null,
 "address_line" text not null,
 "suburb_village" text,
 "town" text,
 "province" text,
 "landmark" text,
 "latitude" numeric(9,6),
 "longitude" numeric(9,6),
 "phone" text,
 "is_open" boolean not null,
 "is_active" boolean not null,
 "min_order" numeric(12,2) not null,
 "created_at" timestamp with time zone not null
);
create table public."merchant_hours" (
 "id" uuid not null,
 "branch_id" uuid not null,
 "day_of_week" smallint not null,
 "opens_at" time without time zone,
 "closes_at" time without time zone,
 "is_closed" boolean not null
);
create table public."merchant_staff" (
 "merchant_id" uuid not null,
 "user_id" uuid not null,
 "is_active" boolean not null,
 "created_at" timestamp with time zone not null
);
create table public."merchants" (
 "id" uuid not null,
 "owner_id" uuid,
 "name" text not null,
 "slug" text not null,
 "description" text,
 "category" text,
 "status" merchant_status not null,
 "logo_url" text,
 "banner_url" text,
 "phone" text,
 "email" text,
 "commission_rate" numeric(5,2) not null,
 "created_at" timestamp with time zone not null,
 "updated_at" timestamp with time zone not null,
 "registration_number" text,
 "owner_name" text,
 "onboarding_completed_at" timestamp with time zone,
 "terms_accepted_at" timestamp with time zone,
 "payout_details" jsonb not null,
 "merchant_mode" text,
 "supports_pickup" boolean not null,
 "supports_delivery" boolean not null,
 "whatsapp_number" text,
 "township_section" text,
 "landmark" text,
 "ordering_features" jsonb not null,
 "is_demo" boolean not null
);
create table public."notifications" (
 "id" uuid not null,
 "user_id" uuid not null,
 "channel" text not null,
 "title" text not null,
 "body" text not null,
 "read_at" timestamp with time zone,
 "created_at" timestamp with time zone not null
);
create table public."order_items" (
 "id" uuid not null,
 "order_id" uuid not null,
 "product_id" uuid,
 "product_name" text not null,
 "sku" text,
 "quantity" integer not null,
 "unit_price" numeric(12,2) not null,
 "options_snapshot" jsonb not null,
 "line_total" numeric(12,2) not null
);
create table public."order_status_history" (
 "id" bigint generated always as identity not null,
 "order_id" uuid not null,
 "previous_status" order_status,
 "new_status" order_status not null,
 "actor_id" uuid,
 "note" text,
 "created_at" timestamp with time zone not null
);
create table public."orders" (
 "id" uuid not null,
 "order_number" bigint generated always as identity not null,
 "customer_id" uuid not null,
 "merchant_id" uuid not null,
 "branch_id" uuid not null,
 "driver_id" uuid,
 "delivery_address_id" uuid,
 "status" order_status not null,
 "currency" character(3) not null,
 "subtotal" numeric(12,2) not null,
 "delivery_fee" numeric(12,2) not null,
 "service_fee" numeric(12,2) not null,
 "discount" numeric(12,2) not null,
 "total" numeric(12,2) not null,
 "notes" text,
 "delivery_address_snapshot" jsonb not null,
 "created_at" timestamp with time zone not null,
 "updated_at" timestamp with time zone not null,
 "fulfillment_type" text not null
);
create table public."payment_events" (
 "id" bigint generated always as identity not null,
 "payment_id" uuid,
 "provider_event_id" text,
 "event_type" text not null,
 "payload" jsonb not null,
 "created_at" timestamp with time zone not null
);
create table public."payments" (
 "id" uuid not null,
 "order_id" uuid not null,
 "provider" text not null,
 "provider_reference" text,
 "status" payment_status not null,
 "amount" numeric(12,2) not null,
 "currency" character(3) not null,
 "idempotency_key" text,
 "metadata" jsonb not null,
 "created_at" timestamp with time zone not null,
 "updated_at" timestamp with time zone not null
);
create table public."platform_settings" (
 "key" text not null,
 "value" jsonb not null,
 "updated_at" timestamp with time zone not null
);
create table public."product_categories" (
 "id" uuid not null,
 "merchant_id" uuid not null,
 "name" text not null,
 "sort_order" integer not null,
 "is_active" boolean not null
);
create table public."product_options" (
 "id" uuid not null,
 "product_id" uuid not null,
 "name" text not null,
 "price_delta" numeric(12,2) not null,
 "is_active" boolean not null
);
create table public."products" (
 "id" uuid not null,
 "merchant_id" uuid not null,
 "category_id" uuid,
 "name" text not null,
 "description" text,
 "image_url" text,
 "price" numeric(12,2) not null,
 "sku" text,
 "stock_quantity" integer,
 "track_stock" boolean not null,
 "is_active" boolean not null,
 "created_at" timestamp with time zone not null,
 "updated_at" timestamp with time zone not null,
 "unit_label" text,
 "preparation_options" jsonb not null,
 "extras" jsonb not null,
 "pack_sizes" jsonb not null,
 "is_special" boolean not null,
 "special_label" text
);
create table public."profiles" (
 "id" uuid not null,
 "first_name" text,
 "last_name" text,
 "phone" text,
 "avatar_url" text,
 "created_at" timestamp with time zone not null,
 "updated_at" timestamp with time zone not null
);
create table public."promotion_redemptions" (
 "id" uuid not null,
 "promotion_id" uuid not null,
 "customer_id" uuid not null,
 "order_id" uuid not null,
 "created_at" timestamp with time zone not null
);
create table public."promotions" (
 "id" uuid not null,
 "code" text not null,
 "merchant_id" uuid,
 "discount_type" text not null,
 "value" numeric(12,2) not null,
 "starts_at" timestamp with time zone,
 "ends_at" timestamp with time zone,
 "usage_limit" integer,
 "is_active" boolean not null
);
create table public."refunds" (
 "id" uuid not null,
 "payment_id" uuid not null,
 "amount" numeric(12,2) not null,
 "provider_reference" text,
 "reason" text,
 "created_at" timestamp with time zone not null
);
create table public."user_roles" (
 "user_id" uuid not null,
 "role" app_role not null,
 "created_at" timestamp with time zone not null
);
CREATE OR REPLACE FUNCTION public.admin_set_driver_approval(p_driver_id uuid, p_approved boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if not public.is_admin() then raise exception 'admin required'; end if;
 update public.drivers set approved=p_approved,state=case when p_approved then state else 'offline'::public.driver_state end where user_id=p_driver_id;
 if not found then raise exception 'driver not found'; end if;
 insert into public.audit_logs(actor_id,action,entity_type,entity_id,metadata) values(auth.uid(),'driver_approval_changed','driver',p_driver_id,jsonb_build_object('approved',p_approved));
end $function$
;
CREATE OR REPLACE FUNCTION public.admin_set_merchant_status(p_merchant_id uuid, p_status merchant_status)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if not public.is_admin() then raise exception 'admin required'; end if;
 if p_status not in ('approved','rejected','suspended','under_review') then raise exception 'invalid merchant status'; end if;
 update public.merchants set status=p_status,updated_at=now() where id=p_merchant_id;
 if not found then raise exception 'merchant not found'; end if;
 insert into public.audit_logs(actor_id,action,entity_type,entity_id,metadata) values(auth.uid(),'merchant_status_changed','merchant',p_merchant_id,jsonb_build_object('status',p_status));
end $function$
;
CREATE OR REPLACE FUNCTION public.advance_delivery(p_order_id uuid, p_status order_status)
 RETURNS order_status
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_uid uuid:=auth.uid(); v_current public.order_status;
begin
 if v_uid is null then raise exception 'authentication required'; end if;
 select status into v_current from public.orders where id=p_order_id and driver_id=v_uid for update;
 if v_current is null then raise exception 'assigned order required'; end if;
 if not ((v_current='driver_assigned' and p_status='picked_up') or (v_current='picked_up' and p_status='out_for_delivery') or (v_current='out_for_delivery' and p_status='delivered')) then raise exception 'invalid delivery transition'; end if;
 update public.orders set status=p_status,updated_at=now() where id=p_order_id;
 insert into public.order_status_history(order_id,previous_status,new_status,actor_id,note) values(p_order_id,v_current,p_status,v_uid,'Driver delivery update');
 if p_status='picked_up' then update public.deliveries set pickup_at=coalesce(pickup_at,now()) where order_id=p_order_id and driver_id=v_uid;
 elsif p_status='delivered' then update public.deliveries set delivered_at=now() where order_id=p_order_id and driver_id=v_uid; update public.drivers set state='available' where user_id=v_uid; end if;
 return p_status;
end $function$
;
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

  v_was_paid := v_payment.status in ('paid','partially_refunded','refunded');

  v_transition_ok :=
    p_status = v_payment.status
    or (v_payment.status='pending' and p_status in ('processing','paid','failed','cancelled'))
    or (v_payment.status='processing' and p_status in ('paid','failed','cancelled'))
    or (v_payment.status='paid' and p_status in ('partially_refunded','refunded'))
    or (v_payment.status='partially_refunded' and p_status='refunded');

  if not v_transition_ok then
    raise exception 'invalid payment transition: % -> %',v_payment.status,p_status;
  end if;

  update public.payments
  set provider_reference=coalesce(p_provider_reference,provider_reference),
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

  if p_status='paid' and not v_was_paid then
    update public.products p
    set stock_quantity=greatest(0,coalesce(p.stock_quantity,0)-oi.quantity),
        updated_at=now()
    from public.order_items oi
    where oi.order_id=v_order.id
      and oi.product_id=p.id
      and p.track_stock;

    if v_order.status='pending_payment' then
      update public.orders set status='paid',updated_at=now() where id=v_order.id;
      insert into public.order_status_history(order_id,previous_status,new_status,note)
      values(v_order.id,'pending_payment','paid','Payment confirmed by gateway');
    end if;
  elsif p_status='refunded' and v_order.status not in ('cancelled','refunded') then
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
CREATE OR REPLACE FUNCTION public.can_manage_merchant(mid uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select public.is_admin() or exists(select 1 from public.merchants m where m.id=mid and m.owner_id=auth.uid())
 or exists(select 1 from public.merchant_staff s where s.merchant_id=mid and s.user_id=auth.uid() and s.is_active)
$function$
;
CREATE OR REPLACE FUNCTION public.checkout_cart(p_address_id uuid, p_branch_id uuid, p_notes text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_uid uuid:=auth.uid(); v_cart public.carts; v_address public.addresses; v_sub numeric(12,2); v_order uuid; v_min numeric(12,2);
begin
 if v_uid is null then raise exception 'authentication required'; end if;
 select * into v_cart from public.carts where customer_id=v_uid for update;
 if v_cart.id is null or v_cart.merchant_id is null then raise exception 'cart is empty'; end if;
 select * into v_address from public.addresses where id=p_address_id and customer_id=v_uid;
 if v_address.id is null then raise exception 'invalid address'; end if;
 select min_order into v_min from public.merchant_branches where id=p_branch_id and merchant_id=v_cart.merchant_id and is_active;
 if not found then raise exception 'invalid branch'; end if;
 select coalesce(sum(p.price*ci.quantity),0) into v_sub from public.cart_items ci join public.products p on p.id=ci.product_id
 where ci.cart_id=v_cart.id and p.merchant_id=v_cart.merchant_id and p.is_active and (not p.track_stock or coalesce(p.stock_quantity,0)>=ci.quantity);
 if v_sub<=0 then raise exception 'no valid cart items'; end if;
 if v_sub<v_min then raise exception 'minimum order not met'; end if;
 insert into public.orders(customer_id,merchant_id,branch_id,delivery_address_id,subtotal,delivery_fee,service_fee,discount,total,notes,delivery_address_snapshot)
 values(v_uid,v_cart.merchant_id,p_branch_id,p_address_id,v_sub,0,0,0,v_sub,p_notes,to_jsonb(v_address)) returning id into v_order;
 insert into public.order_items(order_id,product_id,product_name,sku,quantity,unit_price,line_total)
 select v_order,p.id,p.name,p.sku,ci.quantity,p.price,p.price*ci.quantity from public.cart_items ci join public.products p on p.id=ci.product_id
 where ci.cart_id=v_cart.id and p.merchant_id=v_cart.merchant_id and p.is_active and (not p.track_stock or coalesce(p.stock_quantity,0)>=ci.quantity);
 insert into public.order_status_history(order_id,new_status,actor_id,note) values(v_order,'pending_payment',v_uid,'Checkout created');
 delete from public.cart_items where cart_id=v_cart.id; update public.carts set merchant_id=null,updated_at=now() where id=v_cart.id;
 return v_order;
end $function$
;
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
  if p_fulfillment not in ('delivery','pickup') then raise exception 'invalid fulfilment type'; end if;
  select * into v_cart from public.carts where customer_id=v_uid for update;
  if v_cart.id is null or v_cart.merchant_id is null then raise exception 'cart is empty'; end if;
  select * into v_branch from public.merchant_branches where id=p_branch_id and merchant_id=v_cart.merchant_id and is_active;
  if v_branch.id is null then raise exception 'invalid branch'; end if;
  if not v_branch.is_open then raise exception 'This store is currently closed. Try again when the merchant reopens.'; end if;
  v_min:=v_branch.min_order;
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
   group by p.id,p.stock_quantity having sum(ci.quantity)>coalesce(p.stock_quantity,0)
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
CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 insert into public.profiles(id,first_name,last_name,phone) values(new.id,new.raw_user_meta_data->>'first_name',new.raw_user_meta_data->>'last_name',new.phone)
 on conflict(id) do nothing;
 insert into public.user_roles(user_id,role) values(new.id,'customer') on conflict do nothing;
 return new;
end $function$
;
CREATE OR REPLACE FUNCTION public.has_role(r app_role)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select exists(select 1 from public.user_roles where user_id=auth.uid() and role=r)
$function$
;
CREATE OR REPLACE FUNCTION public.is_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select public.has_role('admin') or public.has_role('super_admin')
$function$
;
CREATE OR REPLACE FUNCTION public.mark_all_notifications_read()
 RETURNS void
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  update public.notifications
  set read_at=coalesce(read_at,now())
  where user_id=auth.uid() and read_at is null;
$function$
;
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
CREATE OR REPLACE FUNCTION public.merchant_complete_pickup(p_order_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare o public.orders%rowtype;
begin
  select * into o from public.orders where id=p_order_id for update;
  if o.id is null then raise exception 'Order not found'; end if;
  if not public.can_manage_merchant(o.merchant_id) then raise exception 'Not authorised for this merchant'; end if;
  if o.fulfillment_type<>'pickup' or o.status<>'ready_for_pickup' then
    raise exception 'Pickup order is not ready for collection';
  end if;

  update public.orders set status='delivered',updated_at=now() where id=p_order_id;
  insert into public.order_status_history(order_id,previous_status,new_status,actor_id,note)
  values(p_order_id,'ready_for_pickup','delivered',auth.uid(),'Customer collected pickup order');
end $function$
;
CREATE OR REPLACE FUNCTION public.notify_order_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_title text;
  v_body text;
begin
  if tg_op='UPDATE' and new.status is distinct from old.status then
    v_title := case new.status
      when 'paid' then 'Payment confirmed'
      when 'merchant_confirmed' then 'Order accepted'
      when 'preparing' then 'Your order is being prepared'
      when 'ready_for_pickup' then case when new.fulfillment_type='pickup' then 'Ready for collection' else 'Ready for a driver' end
      when 'driver_assigned' then 'Driver assigned'
      when 'picked_up' then 'Driver has your order'
      when 'out_for_delivery' then 'On the way'
      when 'delivered' then case when new.fulfillment_type='pickup' then 'Order collected' else 'Delivered' end
      when 'cancelled' then 'Order cancelled'
      when 'refunded' then 'Payment refunded'
      else 'Order update'
    end;
    v_body := 'Order #'||new.order_number||' is now '||replace(new.status::text,'_',' ')||'.';
    insert into public.notifications(user_id,channel,title,body)
    values(new.customer_id,'in_app',v_title,v_body);
  end if;

  if tg_op='UPDATE' and new.driver_id is distinct from old.driver_id and new.driver_id is not null then
    insert into public.notifications(user_id,channel,title,body)
    values(new.driver_id,'in_app','New SHESHA delivery','Order #'||new.order_number||' has been assigned to you.');
  end if;

  return new;
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
  if coalesce(trim(p_provider),'')='' then raise exception 'payment provider required'; end if;

  select * into v_order
  from public.orders
  where id=p_order_id and customer_id=v_uid and status='pending_payment'
  for update;

  if v_order.id is null then raise exception 'payable order not found'; end if;

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
CREATE OR REPLACE FUNCTION public.prepare_yoco_payment(p_order_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_uid uuid:=auth.uid(); v_order public.orders; v_payment uuid;
begin
 if v_uid is null then raise exception 'authentication required'; end if;
 select * into v_order from public.orders where id=p_order_id and customer_id=v_uid and status='pending_payment' for update;
 if v_order.id is null then raise exception 'payable order not found'; end if;
 select id into v_payment from public.payments where order_id=p_order_id and status in ('pending','processing') order by created_at desc limit 1;
 if v_payment is null then
   insert into public.payments(order_id,provider,amount,currency,status) values(p_order_id,'yoco',v_order.total,v_order.currency,'pending') returning id into v_payment;
 end if;
 return jsonb_build_object('payment_id',v_payment,'order_id',v_order.id,'order_number',v_order.order_number,'amount',v_order.total,'currency',v_order.currency);
end $function$
;
CREATE OR REPLACE FUNCTION public.quote_delivery_fee(p_branch_id uuid, p_address_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_uid uuid:=auth.uid();
  a public.addresses;
  b public.merchant_branches;
  z public.delivery_zones;
  v_distance numeric;
  v_fee numeric(12,2);
begin
  if v_uid is null then raise exception 'authentication required'; end if;
  select * into a from public.addresses where id=p_address_id and customer_id=v_uid;
  if a.id is null then raise exception 'delivery address required'; end if;
  select * into b from public.merchant_branches where id=p_branch_id and is_active;
  if b.id is null then raise exception 'invalid branch'; end if;

  if a.latitude is not null and a.longitude is not null and b.latitude is not null and b.longitude is not null then
    v_distance := 6371 * acos(least(1,greatest(-1,
      sin(radians(a.latitude))*sin(radians(b.latitude))+
      cos(radians(a.latitude))*cos(radians(b.latitude))*cos(radians(a.longitude-b.longitude))
    )));
  end if;

  select * into z
  from public.delivery_zones dz
  where dz.is_active
    and (dz.town is null or lower(dz.town)=lower(coalesce(a.town,'')))
    and (dz.province is null or lower(dz.province)=lower(coalesce(a.province,'')))
    and (v_distance is null or dz.max_distance_km is null or v_distance<=dz.max_distance_km)
  order by
    case when dz.town is not null then 0 else 1 end,
    case when dz.province is not null then 0 else 1 end
  limit 1;

  if z.id is null then
    return jsonb_build_object('serviceable',false,'fee',null,'distance_km',v_distance,'zone',null);
  end if;

  v_fee := z.base_fee + case when v_distance is not null then z.per_km_fee*v_distance else 0 end;
  return jsonb_build_object('serviceable',true,'fee',round(v_fee,2),'distance_km',case when v_distance is null then null else round(v_distance,1) end,'zone',z.name);
end $function$
;
CREATE OR REPLACE FUNCTION public.respond_dispatch_offer(p_offer_id uuid, p_accept boolean)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_uid uuid:=auth.uid(); v_offer public.dispatch_offers; v_delivery uuid;
begin
 if v_uid is null then raise exception 'authentication required'; end if;
 select * into v_offer from public.dispatch_offers
 where id=p_offer_id and driver_id=v_uid and status='offered'
 and (expires_at is null or expires_at>now()) for update;
 if v_offer.id is null then raise exception 'offer unavailable'; end if;
 if not p_accept then
   update public.dispatch_offers set status='rejected',responded_at=now() where id=p_offer_id;
   return null;
 end if;
 update public.orders set driver_id=v_uid,status='driver_assigned',updated_at=now()
 where id=v_offer.order_id and driver_id is null and status='ready_for_pickup';
 if not found then raise exception 'order already assigned or unavailable'; end if;
 update public.dispatch_offers set status='accepted',responded_at=now() where id=p_offer_id;
 update public.dispatch_offers set status='expired',responded_at=now()
 where order_id=v_offer.order_id and id<>p_offer_id and status='offered';
 insert into public.deliveries(order_id,driver_id) values(v_offer.order_id,v_uid)
 on conflict(order_id) do update set driver_id=excluded.driver_id returning id into v_delivery;
 update public.drivers set state='assigned' where user_id=v_uid;
 insert into public.order_status_history(order_id,previous_status,new_status,actor_id,note)
 values(v_offer.order_id,'ready_for_pickup','driver_assigned',v_uid,'Driver accepted dispatch');
 return v_delivery;
end $function$
;
CREATE OR REPLACE FUNCTION public.set_driver_availability(p_available boolean)
 RETURNS driver_state
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_uid uuid:=auth.uid(); v_state public.driver_state;
begin
 if v_uid is null then raise exception 'authentication required'; end if;
 if not exists(select 1 from public.drivers where user_id=v_uid and approved) then raise exception 'approved driver required'; end if;
 v_state:=case when p_available then 'available'::public.driver_state else 'offline'::public.driver_state end;
 update public.drivers set state=v_state where user_id=v_uid;
 return v_state;
end $function$
;
CREATE OR REPLACE FUNCTION public.validate_cart_item_price()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare product public.products;
begin
  select * into product from public.products where id = new.product_id;
  if product.id is null or not product.is_active then raise exception 'Product is unavailable'; end if;
  if new.quantity is null or new.quantity <= 0 then raise exception 'Invalid quantity'; end if;
  new.option_price_delta := public.validated_option_delta(coalesce(new.selected_options,'[]'),product.preparation_options,product.extras,product.pack_sizes);
  if product.price + new.option_price_delta < 0 then raise exception 'Invalid product price'; end if;
  return new;
end $function$
;
CREATE OR REPLACE FUNCTION public.validated_option_delta(p_options jsonb, p_preparation jsonb, p_extras jsonb, p_packs jsonb)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO ''
AS $function$
declare
  choice jsonb; configured jsonb; candidates jsonb; total numeric := 0;
  seen text[] := '{}'; identity text; prep_count integer := 0; pack_count integer := 0;
begin
  if jsonb_typeof(p_options) is distinct from 'array' then raise exception 'Invalid product options'; end if;
  for choice in select value from jsonb_array_elements(p_options) loop
    identity := (choice->>'group') || ':' || (choice->>'label');
    if identity is null or identity = any(seen) then raise exception 'Duplicate or invalid product option'; end if;
    seen := array_append(seen, identity);
    case choice->>'group'
      when 'Preparation' then candidates := coalesce(p_preparation,'[]'); prep_count := prep_count+1;
      when 'Extra' then candidates := coalesce(p_extras,'[]');
      when 'Pack size' then candidates := coalesce(p_packs,'[]'); pack_count := pack_count+1;
      else raise exception 'Unknown product option group';
    end case;
    select value into configured from jsonb_array_elements(candidates) where value->>'label' = choice->>'label' limit 1;
    if configured is null then raise exception 'Product options have changed. Please update your cart.'; end if;
    total := total + coalesce((configured->>'price_delta')::numeric,0);
  end loop;
  if prep_count > 1 or pack_count > 1
    or (jsonb_array_length(coalesce(p_preparation,'[]')) > 0 and prep_count <> 1)
    or (jsonb_array_length(coalesce(p_packs,'[]')) > 0 and pack_count <> 1)
  then raise exception 'Choose one preparation and pack option where available'; end if;
  return total;
end $function$
;
alter table public."addresses" alter column "id" set default gen_random_uuid();
alter table public."addresses" alter column "label" set default 'Home'::text;
alter table public."addresses" alter column "is_default" set default false;
alter table public."addresses" alter column "created_at" set default now();
alter table public."audit_logs" alter column "metadata" set default '{}'::jsonb;
alter table public."audit_logs" alter column "created_at" set default now();
alter table public."cart_items" alter column "id" set default gen_random_uuid();
alter table public."cart_items" alter column "created_at" set default now();
alter table public."cart_items" alter column "selected_options" set default '[]'::jsonb;
alter table public."cart_items" alter column "variant_key" set default ''::text;
alter table public."cart_items" alter column "option_price_delta" set default 0;
alter table public."carts" alter column "id" set default gen_random_uuid();
alter table public."carts" alter column "created_at" set default now();
alter table public."carts" alter column "updated_at" set default now();
alter table public."deliveries" alter column "id" set default gen_random_uuid();
alter table public."deliveries" alter column "created_at" set default now();
alter table public."delivery_events" alter column "metadata" set default '{}'::jsonb;
alter table public."delivery_events" alter column "created_at" set default now();
alter table public."delivery_zones" alter column "id" set default gen_random_uuid();
alter table public."delivery_zones" alter column "base_fee" set default 0;
alter table public."delivery_zones" alter column "per_km_fee" set default 0;
alter table public."delivery_zones" alter column "is_active" set default true;
alter table public."dispatch_offers" alter column "id" set default gen_random_uuid();
alter table public."dispatch_offers" alter column "status" set default 'offered'::text;
alter table public."dispatch_offers" alter column "offered_at" set default now();
alter table public."driver_locations" alter column "updated_at" set default now();
alter table public."drivers" alter column "state" set default 'offline'::driver_state;
alter table public."drivers" alter column "approved" set default false;
alter table public."drivers" alter column "created_at" set default now();
alter table public."merchant_branches" alter column "id" set default gen_random_uuid();
alter table public."merchant_branches" alter column "is_open" set default true;
alter table public."merchant_branches" alter column "is_active" set default true;
alter table public."merchant_branches" alter column "min_order" set default 0;
alter table public."merchant_branches" alter column "created_at" set default now();
alter table public."merchant_hours" alter column "id" set default gen_random_uuid();
alter table public."merchant_hours" alter column "is_closed" set default false;
alter table public."merchant_staff" alter column "is_active" set default true;
alter table public."merchant_staff" alter column "created_at" set default now();
alter table public."merchants" alter column "id" set default gen_random_uuid();
alter table public."merchants" alter column "status" set default 'draft'::merchant_status;
alter table public."merchants" alter column "commission_rate" set default 0;
alter table public."merchants" alter column "created_at" set default now();
alter table public."merchants" alter column "updated_at" set default now();
alter table public."merchants" alter column "payout_details" set default '{}'::jsonb;
alter table public."merchants" alter column "supports_pickup" set default true;
alter table public."merchants" alter column "supports_delivery" set default true;
alter table public."merchants" alter column "ordering_features" set default '{}'::jsonb;
alter table public."merchants" alter column "is_demo" set default false;
alter table public."notifications" alter column "id" set default gen_random_uuid();
alter table public."notifications" alter column "channel" set default 'in_app'::text;
alter table public."notifications" alter column "created_at" set default now();
alter table public."order_items" alter column "id" set default gen_random_uuid();
alter table public."order_items" alter column "options_snapshot" set default '[]'::jsonb;
alter table public."order_status_history" alter column "created_at" set default now();
alter table public."orders" alter column "id" set default gen_random_uuid();
alter table public."orders" alter column "status" set default 'pending_payment'::order_status;
alter table public."orders" alter column "currency" set default 'ZAR'::bpchar;
alter table public."orders" alter column "delivery_fee" set default 0;
alter table public."orders" alter column "service_fee" set default 0;
alter table public."orders" alter column "discount" set default 0;
alter table public."orders" alter column "delivery_address_snapshot" set default '{}'::jsonb;
alter table public."orders" alter column "created_at" set default now();
alter table public."orders" alter column "updated_at" set default now();
alter table public."orders" alter column "fulfillment_type" set default 'delivery'::text;
alter table public."payment_events" alter column "payload" set default '{}'::jsonb;
alter table public."payment_events" alter column "created_at" set default now();
alter table public."payments" alter column "id" set default gen_random_uuid();
alter table public."payments" alter column "status" set default 'pending'::payment_status;
alter table public."payments" alter column "currency" set default 'ZAR'::bpchar;
alter table public."payments" alter column "metadata" set default '{}'::jsonb;
alter table public."payments" alter column "created_at" set default now();
alter table public."payments" alter column "updated_at" set default now();
alter table public."platform_settings" alter column "updated_at" set default now();
alter table public."product_categories" alter column "id" set default gen_random_uuid();
alter table public."product_categories" alter column "sort_order" set default 0;
alter table public."product_categories" alter column "is_active" set default true;
alter table public."product_options" alter column "id" set default gen_random_uuid();
alter table public."product_options" alter column "price_delta" set default 0;
alter table public."product_options" alter column "is_active" set default true;
alter table public."products" alter column "id" set default gen_random_uuid();
alter table public."products" alter column "track_stock" set default false;
alter table public."products" alter column "is_active" set default true;
alter table public."products" alter column "created_at" set default now();
alter table public."products" alter column "updated_at" set default now();
alter table public."products" alter column "preparation_options" set default '[]'::jsonb;
alter table public."products" alter column "extras" set default '[]'::jsonb;
alter table public."products" alter column "pack_sizes" set default '[]'::jsonb;
alter table public."products" alter column "is_special" set default false;
alter table public."profiles" alter column "created_at" set default now();
alter table public."profiles" alter column "updated_at" set default now();
alter table public."promotion_redemptions" alter column "id" set default gen_random_uuid();
alter table public."promotion_redemptions" alter column "created_at" set default now();
alter table public."promotions" alter column "id" set default gen_random_uuid();
alter table public."promotions" alter column "value" set default 0;
alter table public."promotions" alter column "is_active" set default true;
alter table public."refunds" alter column "id" set default gen_random_uuid();
alter table public."refunds" alter column "created_at" set default now();
alter table public."user_roles" alter column "role" set default 'customer'::app_role;
alter table public."user_roles" alter column "created_at" set default now();
alter table public."profiles" add constraint "profiles_pkey" PRIMARY KEY (id);
alter table public."user_roles" add constraint "user_roles_pkey" PRIMARY KEY (user_id, role);
alter table public."addresses" add constraint "addresses_pkey" PRIMARY KEY (id);
alter table public."merchants" add constraint "merchants_commission_rate_check" CHECK (((commission_rate >= (0)::numeric) AND (commission_rate <= (100)::numeric)));
alter table public."merchants" add constraint "merchants_pkey" PRIMARY KEY (id);
alter table public."merchants" add constraint "merchants_slug_key" UNIQUE (slug);
alter table public."merchant_staff" add constraint "merchant_staff_pkey" PRIMARY KEY (merchant_id, user_id);
alter table public."merchant_branches" add constraint "merchant_branches_min_order_check" CHECK ((min_order >= (0)::numeric));
alter table public."merchant_branches" add constraint "merchant_branches_pkey" PRIMARY KEY (id);
alter table public."product_categories" add constraint "product_categories_pkey" PRIMARY KEY (id);
alter table public."products" add constraint "products_price_check" CHECK ((price >= (0)::numeric));
alter table public."products" add constraint "products_pkey" PRIMARY KEY (id);
alter table public."product_options" add constraint "product_options_pkey" PRIMARY KEY (id);
alter table public."delivery_zones" add constraint "delivery_zones_base_fee_check" CHECK ((base_fee >= (0)::numeric));
alter table public."delivery_zones" add constraint "delivery_zones_per_km_fee_check" CHECK ((per_km_fee >= (0)::numeric));
alter table public."delivery_zones" add constraint "delivery_zones_pkey" PRIMARY KEY (id);
alter table public."drivers" add constraint "drivers_pkey" PRIMARY KEY (user_id);
alter table public."driver_locations" add constraint "driver_locations_pkey" PRIMARY KEY (driver_id);
alter table public."orders" add constraint "orders_subtotal_check" CHECK ((subtotal >= (0)::numeric));
alter table public."orders" add constraint "orders_delivery_fee_check" CHECK ((delivery_fee >= (0)::numeric));
alter table public."orders" add constraint "orders_service_fee_check" CHECK ((service_fee >= (0)::numeric));
alter table public."orders" add constraint "orders_discount_check" CHECK ((discount >= (0)::numeric));
alter table public."orders" add constraint "orders_total_check" CHECK ((total >= (0)::numeric));
alter table public."orders" add constraint "orders_pkey" PRIMARY KEY (id);
alter table public."orders" add constraint "orders_order_number_key" UNIQUE (order_number);
alter table public."order_items" add constraint "order_items_quantity_check" CHECK ((quantity > 0));
alter table public."order_items" add constraint "order_items_unit_price_check" CHECK ((unit_price >= (0)::numeric));
alter table public."order_items" add constraint "order_items_line_total_check" CHECK ((line_total >= (0)::numeric));
alter table public."order_items" add constraint "order_items_pkey" PRIMARY KEY (id);
alter table public."order_status_history" add constraint "order_status_history_pkey" PRIMARY KEY (id);
alter table public."payments" add constraint "payments_amount_check" CHECK ((amount >= (0)::numeric));
alter table public."payments" add constraint "payments_pkey" PRIMARY KEY (id);
alter table public."payments" add constraint "payments_idempotency_key_key" UNIQUE (idempotency_key);
alter table public."refunds" add constraint "refunds_amount_check" CHECK ((amount > (0)::numeric));
alter table public."refunds" add constraint "refunds_pkey" PRIMARY KEY (id);
alter table public."dispatch_offers" add constraint "dispatch_offers_status_check" CHECK ((status = ANY (ARRAY['offered'::text, 'accepted'::text, 'rejected'::text, 'expired'::text])));
alter table public."dispatch_offers" add constraint "dispatch_offers_pkey" PRIMARY KEY (id);
alter table public."dispatch_offers" add constraint "dispatch_offers_order_id_driver_id_key" UNIQUE (order_id, driver_id);
alter table public."deliveries" add constraint "deliveries_pkey" PRIMARY KEY (id);
alter table public."deliveries" add constraint "deliveries_order_id_key" UNIQUE (order_id);
alter table public."notifications" add constraint "notifications_pkey" PRIMARY KEY (id);
alter table public."platform_settings" add constraint "platform_settings_pkey" PRIMARY KEY (key);
alter table public."audit_logs" add constraint "audit_logs_pkey" PRIMARY KEY (id);
alter table public."carts" add constraint "carts_pkey" PRIMARY KEY (id);
alter table public."carts" add constraint "carts_customer_id_key" UNIQUE (customer_id);
alter table public."cart_items" add constraint "cart_items_quantity_check" CHECK ((quantity > 0));
alter table public."cart_items" add constraint "cart_items_pkey" PRIMARY KEY (id);
alter table public."payment_events" add constraint "payment_events_pkey" PRIMARY KEY (id);
alter table public."payment_events" add constraint "payment_events_provider_event_id_key" UNIQUE (provider_event_id);
alter table public."delivery_events" add constraint "delivery_events_pkey" PRIMARY KEY (id);
alter table public."merchant_hours" add constraint "merchant_hours_day_of_week_check" CHECK (((day_of_week >= 0) AND (day_of_week <= 6)));
alter table public."merchant_hours" add constraint "merchant_hours_pkey" PRIMARY KEY (id);
alter table public."merchant_hours" add constraint "merchant_hours_branch_id_day_of_week_key" UNIQUE (branch_id, day_of_week);
alter table public."promotions" add constraint "promotions_discount_type_check" CHECK ((discount_type = ANY (ARRAY['fixed'::text, 'percent'::text, 'free_delivery'::text])));
alter table public."promotions" add constraint "promotions_pkey" PRIMARY KEY (id);
alter table public."promotions" add constraint "promotions_code_key" UNIQUE (code);
alter table public."promotion_redemptions" add constraint "promotion_redemptions_pkey" PRIMARY KEY (id);
alter table public."promotion_redemptions" add constraint "promotion_redemptions_promotion_id_order_id_key" UNIQUE (promotion_id, order_id);
alter table public."merchants" add constraint "merchants_owner_or_demo_check" CHECK ((is_demo OR (owner_id IS NOT NULL)));
alter table public."orders" add constraint "orders_fulfillment_type_check" CHECK ((fulfillment_type = ANY (ARRAY['delivery'::text, 'pickup'::text])));
alter table public."cart_items" add constraint "cart_items_cart_product_variant_key" UNIQUE (cart_id, product_id, variant_key);
alter table public."profiles" add constraint "profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public."user_roles" add constraint "user_roles_user_id_fkey" FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table public."addresses" add constraint "addresses_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table public."merchants" add constraint "merchants_owner_id_fkey" FOREIGN KEY (owner_id) REFERENCES profiles(id);
alter table public."merchant_staff" add constraint "merchant_staff_merchant_id_fkey" FOREIGN KEY (merchant_id) REFERENCES merchants(id) ON DELETE CASCADE;
alter table public."merchant_staff" add constraint "merchant_staff_user_id_fkey" FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table public."merchant_branches" add constraint "merchant_branches_merchant_id_fkey" FOREIGN KEY (merchant_id) REFERENCES merchants(id) ON DELETE CASCADE;
alter table public."product_categories" add constraint "product_categories_merchant_id_fkey" FOREIGN KEY (merchant_id) REFERENCES merchants(id) ON DELETE CASCADE;
alter table public."products" add constraint "products_merchant_id_fkey" FOREIGN KEY (merchant_id) REFERENCES merchants(id) ON DELETE CASCADE;
alter table public."products" add constraint "products_category_id_fkey" FOREIGN KEY (category_id) REFERENCES product_categories(id) ON DELETE SET NULL;
alter table public."product_options" add constraint "product_options_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE;
alter table public."drivers" add constraint "drivers_user_id_fkey" FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table public."drivers" add constraint "drivers_current_zone_id_fkey" FOREIGN KEY (current_zone_id) REFERENCES delivery_zones(id);
alter table public."driver_locations" add constraint "driver_locations_driver_id_fkey" FOREIGN KEY (driver_id) REFERENCES drivers(user_id) ON DELETE CASCADE;
alter table public."delivery_events" add constraint "delivery_events_delivery_id_fkey" FOREIGN KEY (delivery_id) REFERENCES deliveries(id) ON DELETE CASCADE;
alter table public."orders" add constraint "orders_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES profiles(id);
alter table public."orders" add constraint "orders_merchant_id_fkey" FOREIGN KEY (merchant_id) REFERENCES merchants(id);
alter table public."orders" add constraint "orders_branch_id_fkey" FOREIGN KEY (branch_id) REFERENCES merchant_branches(id);
alter table public."orders" add constraint "orders_driver_id_fkey" FOREIGN KEY (driver_id) REFERENCES drivers(user_id);
alter table public."orders" add constraint "orders_delivery_address_id_fkey" FOREIGN KEY (delivery_address_id) REFERENCES addresses(id);
alter table public."order_items" add constraint "order_items_order_id_fkey" FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE;
alter table public."order_items" add constraint "order_items_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL;
alter table public."order_status_history" add constraint "order_status_history_order_id_fkey" FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE;
alter table public."order_status_history" add constraint "order_status_history_actor_id_fkey" FOREIGN KEY (actor_id) REFERENCES profiles(id);
alter table public."payments" add constraint "payments_order_id_fkey" FOREIGN KEY (order_id) REFERENCES orders(id);
alter table public."refunds" add constraint "refunds_payment_id_fkey" FOREIGN KEY (payment_id) REFERENCES payments(id);
alter table public."dispatch_offers" add constraint "dispatch_offers_order_id_fkey" FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE;
alter table public."dispatch_offers" add constraint "dispatch_offers_driver_id_fkey" FOREIGN KEY (driver_id) REFERENCES drivers(user_id);
alter table public."deliveries" add constraint "deliveries_order_id_fkey" FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE;
alter table public."deliveries" add constraint "deliveries_driver_id_fkey" FOREIGN KEY (driver_id) REFERENCES drivers(user_id);
alter table public."notifications" add constraint "notifications_user_id_fkey" FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table public."audit_logs" add constraint "audit_logs_actor_id_fkey" FOREIGN KEY (actor_id) REFERENCES profiles(id);
alter table public."carts" add constraint "carts_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table public."carts" add constraint "carts_merchant_id_fkey" FOREIGN KEY (merchant_id) REFERENCES merchants(id) ON DELETE CASCADE;
alter table public."cart_items" add constraint "cart_items_cart_id_fkey" FOREIGN KEY (cart_id) REFERENCES carts(id) ON DELETE CASCADE;
alter table public."cart_items" add constraint "cart_items_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE;
alter table public."payment_events" add constraint "payment_events_payment_id_fkey" FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE CASCADE;
alter table public."merchant_hours" add constraint "merchant_hours_branch_id_fkey" FOREIGN KEY (branch_id) REFERENCES merchant_branches(id) ON DELETE CASCADE;
alter table public."promotions" add constraint "promotions_merchant_id_fkey" FOREIGN KEY (merchant_id) REFERENCES merchants(id) ON DELETE CASCADE;
alter table public."promotion_redemptions" add constraint "promotion_redemptions_promotion_id_fkey" FOREIGN KEY (promotion_id) REFERENCES promotions(id);
alter table public."promotion_redemptions" add constraint "promotion_redemptions_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES profiles(id);
alter table public."promotion_redemptions" add constraint "promotion_redemptions_order_id_fkey" FOREIGN KEY (order_id) REFERENCES orders(id);
CREATE INDEX idx_product_options_product ON public.product_options USING btree (product_id);
CREATE INDEX idx_refunds_payment ON public.refunds USING btree (payment_id);
CREATE INDEX idx_dispatch_driver_status ON public.dispatch_offers USING btree (driver_id, status);
CREATE INDEX idx_deliveries_driver ON public.deliveries USING btree (driver_id);
CREATE INDEX idx_addresses_customer ON public.addresses USING btree (customer_id);
CREATE INDEX idx_orders_customer_created ON public.orders USING btree (customer_id, created_at DESC);
CREATE INDEX idx_orders_merchant_status ON public.orders USING btree (merchant_id, status);
CREATE INDEX idx_orders_driver_status ON public.orders USING btree (driver_id, status);
CREATE INDEX idx_orders_branch ON public.orders USING btree (branch_id);
CREATE INDEX idx_orders_delivery_address ON public.orders USING btree (delivery_address_id);
CREATE INDEX idx_merchant_staff_user ON public.merchant_staff USING btree (user_id);
CREATE INDEX idx_branches_merchant ON public.merchant_branches USING btree (merchant_id);
CREATE INDEX idx_categories_merchant ON public.product_categories USING btree (merchant_id);
CREATE INDEX idx_drivers_zone ON public.drivers USING btree (current_zone_id);
CREATE INDEX idx_order_items_order ON public.order_items USING btree (order_id);
CREATE INDEX idx_order_items_product ON public.order_items USING btree (product_id);
CREATE INDEX idx_order_history_order ON public.order_status_history USING btree (order_id);
CREATE INDEX idx_order_history_actor ON public.order_status_history USING btree (actor_id);
CREATE INDEX idx_payments_order ON public.payments USING btree (order_id);
CREATE UNIQUE INDEX payments_provider_reference_unique ON public.payments USING btree (provider, provider_reference) WHERE (provider_reference IS NOT NULL);
CREATE INDEX idx_notifications_user ON public.notifications USING btree (user_id);
CREATE INDEX idx_audit_actor ON public.audit_logs USING btree (actor_id);
CREATE INDEX idx_payment_events_payment ON public.payment_events USING btree (payment_id);
CREATE INDEX idx_delivery_events_delivery ON public.delivery_events USING btree (delivery_id);
CREATE INDEX idx_products_merchant_active ON public.products USING btree (merchant_id, is_active);
CREATE INDEX idx_products_category ON public.products USING btree (category_id);
CREATE INDEX idx_carts_merchant ON public.carts USING btree (merchant_id);
CREATE INDEX idx_promotions_merchant ON public.promotions USING btree (merchant_id);
CREATE INDEX idx_promotion_redemptions_customer ON public.promotion_redemptions USING btree (customer_id);
CREATE INDEX idx_promotion_redemptions_order ON public.promotion_redemptions USING btree (order_id);
CREATE INDEX idx_merchants_owner ON public.merchants USING btree (owner_id);
CREATE INDEX idx_cart_items_cart ON public.cart_items USING btree (cart_id);
CREATE INDEX idx_cart_items_product ON public.cart_items USING btree (product_id);
alter table public."addresses" enable row level security;
revoke all on public."addresses" from anon, authenticated;
alter table public."audit_logs" enable row level security;
revoke all on public."audit_logs" from anon, authenticated;
alter table public."cart_items" enable row level security;
revoke all on public."cart_items" from anon, authenticated;
alter table public."carts" enable row level security;
revoke all on public."carts" from anon, authenticated;
alter table public."deliveries" enable row level security;
revoke all on public."deliveries" from anon, authenticated;
alter table public."delivery_events" enable row level security;
revoke all on public."delivery_events" from anon, authenticated;
alter table public."delivery_zones" enable row level security;
revoke all on public."delivery_zones" from anon, authenticated;
alter table public."dispatch_offers" enable row level security;
revoke all on public."dispatch_offers" from anon, authenticated;
alter table public."driver_locations" enable row level security;
revoke all on public."driver_locations" from anon, authenticated;
alter table public."drivers" enable row level security;
revoke all on public."drivers" from anon, authenticated;
alter table public."merchant_branches" enable row level security;
revoke all on public."merchant_branches" from anon, authenticated;
alter table public."merchant_hours" enable row level security;
revoke all on public."merchant_hours" from anon, authenticated;
alter table public."merchant_staff" enable row level security;
revoke all on public."merchant_staff" from anon, authenticated;
alter table public."merchants" enable row level security;
revoke all on public."merchants" from anon, authenticated;
alter table public."notifications" enable row level security;
revoke all on public."notifications" from anon, authenticated;
alter table public."order_items" enable row level security;
revoke all on public."order_items" from anon, authenticated;
alter table public."order_status_history" enable row level security;
revoke all on public."order_status_history" from anon, authenticated;
alter table public."orders" enable row level security;
revoke all on public."orders" from anon, authenticated;
alter table public."payment_events" enable row level security;
revoke all on public."payment_events" from anon, authenticated;
alter table public."payments" enable row level security;
revoke all on public."payments" from anon, authenticated;
alter table public."platform_settings" enable row level security;
revoke all on public."platform_settings" from anon, authenticated;
alter table public."product_categories" enable row level security;
revoke all on public."product_categories" from anon, authenticated;
alter table public."product_options" enable row level security;
revoke all on public."product_options" from anon, authenticated;
alter table public."products" enable row level security;
revoke all on public."products" from anon, authenticated;
alter table public."profiles" enable row level security;
revoke all on public."profiles" from anon, authenticated;
alter table public."promotion_redemptions" enable row level security;
revoke all on public."promotion_redemptions" from anon, authenticated;
alter table public."promotions" enable row level security;
revoke all on public."promotions" from anon, authenticated;
alter table public."refunds" enable row level security;
revoke all on public."refunds" from anon, authenticated;
alter table public."user_roles" enable row level security;
revoke all on public."user_roles" from anon, authenticated;
create policy "profile self read" on public."profiles" as PERMISSIVE for SELECT to public using (((id = auth.uid()) OR is_admin()));
create policy "profile self update" on public."profiles" as PERMISSIVE for UPDATE to public using (((id = auth.uid()) OR is_admin())) with check (((id = auth.uid()) OR is_admin()));
create policy "roles self read" on public."user_roles" as PERMISSIVE for SELECT to public using (((user_id = auth.uid()) OR is_admin()));
create policy "addresses owner" on public."addresses" as PERMISSIVE for ALL to public using (((customer_id = auth.uid()) OR is_admin())) with check (((customer_id = auth.uid()) OR is_admin()));
create policy "approved merchants public read" on public."merchants" as PERMISSIVE for SELECT to public using (((status = 'approved'::merchant_status) OR can_manage_merchant(id)));
create policy "merchant managers update" on public."merchants" as PERMISSIVE for UPDATE to public using (can_manage_merchant(id)) with check (can_manage_merchant(id));
create policy "branches public read" on public."merchant_branches" as PERMISSIVE for SELECT to public using ((is_active OR can_manage_merchant(merchant_id)));
create policy "branches manager write" on public."merchant_branches" as PERMISSIVE for ALL to public using (can_manage_merchant(merchant_id)) with check (can_manage_merchant(merchant_id));
create policy "categories public read" on public."product_categories" as PERMISSIVE for SELECT to public using ((is_active OR can_manage_merchant(merchant_id)));
create policy "categories manager write" on public."product_categories" as PERMISSIVE for ALL to public using (can_manage_merchant(merchant_id)) with check (can_manage_merchant(merchant_id));
create policy "products public read" on public."products" as PERMISSIVE for SELECT to public using ((is_active OR can_manage_merchant(merchant_id)));
create policy "products manager write" on public."products" as PERMISSIVE for ALL to public using (can_manage_merchant(merchant_id)) with check (can_manage_merchant(merchant_id));
create policy "drivers self read" on public."drivers" as PERMISSIVE for SELECT to public using (((user_id = auth.uid()) OR is_admin()));
create policy "drivers self update" on public."drivers" as PERMISSIVE for UPDATE to public using (((user_id = auth.uid()) OR is_admin())) with check (((user_id = auth.uid()) OR is_admin()));
create policy "driver location self write" on public."driver_locations" as PERMISSIVE for ALL to public using (((driver_id = auth.uid()) OR is_admin())) with check (((driver_id = auth.uid()) OR is_admin()));
create policy "orders authorised read" on public."orders" as PERMISSIVE for SELECT to public using (((customer_id = auth.uid()) OR (driver_id = auth.uid()) OR can_manage_merchant(merchant_id) OR is_admin()));
create policy "order items authorised read" on public."order_items" as PERMISSIVE for SELECT to public using ((EXISTS ( SELECT 1
   FROM orders o
  WHERE ((o.id = order_items.order_id) AND ((o.customer_id = auth.uid()) OR (o.driver_id = auth.uid()) OR can_manage_merchant(o.merchant_id) OR is_admin())))));
create policy "history authorised read" on public."order_status_history" as PERMISSIVE for SELECT to public using ((EXISTS ( SELECT 1
   FROM orders o
  WHERE ((o.id = order_status_history.order_id) AND ((o.customer_id = auth.uid()) OR (o.driver_id = auth.uid()) OR can_manage_merchant(o.merchant_id) OR is_admin())))));
create policy "payments customer merchant admin read" on public."payments" as PERMISSIVE for SELECT to public using ((EXISTS ( SELECT 1
   FROM orders o
  WHERE ((o.id = payments.order_id) AND ((o.customer_id = auth.uid()) OR can_manage_merchant(o.merchant_id) OR is_admin())))));
create policy "notifications owner" on public."notifications" as PERMISSIVE for SELECT to public using (((user_id = auth.uid()) OR is_admin()));
create policy "notifications owner update" on public."notifications" as PERMISSIVE for UPDATE to public using (((user_id = auth.uid()) OR is_admin()));
create policy "product options public read" on public."product_options" as PERMISSIVE for SELECT to public using ((is_active AND (EXISTS ( SELECT 1
   FROM (products p
     JOIN merchants m ON ((m.id = p.merchant_id)))
  WHERE ((p.id = product_options.product_id) AND p.is_active AND (m.status = 'approved'::merchant_status))))));
create policy "product options merchant manage" on public."product_options" as PERMISSIVE for ALL to public using ((EXISTS ( SELECT 1
   FROM products p
  WHERE ((p.id = product_options.product_id) AND can_manage_merchant(p.merchant_id))))) with check ((EXISTS ( SELECT 1
   FROM products p
  WHERE ((p.id = product_options.product_id) AND can_manage_merchant(p.merchant_id)))));
create policy "delivery zones public read" on public."delivery_zones" as PERMISSIVE for SELECT to public using (is_active);
create policy "delivery zones admin manage" on public."delivery_zones" as PERMISSIVE for ALL to public using (is_admin()) with check (is_admin());
create policy "refunds authorised read" on public."refunds" as PERMISSIVE for SELECT to public using ((EXISTS ( SELECT 1
   FROM (payments p
     JOIN orders o ON ((o.id = p.order_id)))
  WHERE ((p.id = refunds.payment_id) AND ((o.customer_id = auth.uid()) OR can_manage_merchant(o.merchant_id) OR is_admin())))));
create policy "dispatch driver read" on public."dispatch_offers" as PERMISSIVE for SELECT to public using (((driver_id = auth.uid()) OR is_admin()));
create policy "dispatch driver response" on public."dispatch_offers" as PERMISSIVE for UPDATE to public using (((driver_id = auth.uid()) OR is_admin())) with check (((driver_id = auth.uid()) OR is_admin()));
create policy "deliveries authorised read" on public."deliveries" as PERMISSIVE for SELECT to public using (((driver_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM orders o
  WHERE ((o.id = deliveries.order_id) AND ((o.customer_id = auth.uid()) OR can_manage_merchant(o.merchant_id) OR is_admin()))))));
create policy "deliveries driver update" on public."deliveries" as PERMISSIVE for UPDATE to public using (((driver_id = auth.uid()) OR is_admin())) with check (((driver_id = auth.uid()) OR is_admin()));
create policy "platform settings public read" on public."platform_settings" as PERMISSIVE for SELECT to public using ((key = ANY (ARRAY['support'::text, 'service_area'::text, 'minimum_app_version'::text])));
create policy "platform settings admin manage" on public."platform_settings" as PERMISSIVE for ALL to public using (is_admin()) with check (is_admin());
create policy "audit admin read" on public."audit_logs" as PERMISSIVE for SELECT to public using (is_admin());
create policy "merchant staff member read" on public."merchant_staff" as PERMISSIVE for SELECT to public using (((user_id = auth.uid()) OR can_manage_merchant(merchant_id) OR is_admin()));
create policy "cart owner" on public."carts" as PERMISSIVE for ALL to "authenticated" using ((customer_id = ( SELECT auth.uid() AS uid))) with check ((customer_id = ( SELECT auth.uid() AS uid)));
create policy "cart item owner" on public."cart_items" as PERMISSIVE for ALL to "authenticated" using ((EXISTS ( SELECT 1
   FROM carts c
  WHERE ((c.id = cart_items.cart_id) AND (c.customer_id = ( SELECT auth.uid() AS uid)))))) with check ((EXISTS ( SELECT 1
   FROM carts c
  WHERE ((c.id = cart_items.cart_id) AND (c.customer_id = ( SELECT auth.uid() AS uid))))));
create policy "merchant hours public read" on public."merchant_hours" as PERMISSIVE for SELECT to public using (true);
create policy "promotions public active read" on public."promotions" as PERMISSIVE for SELECT to public using ((is_active AND ((starts_at IS NULL) OR (starts_at <= now())) AND ((ends_at IS NULL) OR (ends_at >= now()))));
create policy "redemptions customer read" on public."promotion_redemptions" as PERMISSIVE for SELECT to "authenticated" using ((customer_id = ( SELECT auth.uid() AS uid)));
create policy "delivery events authorised read" on public."delivery_events" as PERMISSIVE for SELECT to "authenticated" using ((EXISTS ( SELECT 1
   FROM (deliveries d
     JOIN orders o ON ((o.id = d.order_id)))
  WHERE ((d.id = delivery_events.delivery_id) AND ((o.customer_id = ( SELECT auth.uid() AS uid)) OR (o.driver_id = ( SELECT auth.uid() AS uid)))))));
create policy "payment events admin read" on public."payment_events" as PERMISSIVE for SELECT to public using (is_admin());
create policy "driver locations active customer read" on public."driver_locations" as PERMISSIVE for SELECT to public using (((driver_id = auth.uid()) OR is_admin() OR (EXISTS ( SELECT 1
   FROM orders o
  WHERE ((o.driver_id = driver_locations.driver_id) AND (o.customer_id = auth.uid()) AND (o.status = ANY (ARRAY['driver_assigned'::order_status, 'picked_up'::order_status, 'out_for_delivery'::order_status])))))));
grant INSERT on public."product_options" to "anon";
grant SELECT on public."product_options" to "anon";
grant UPDATE on public."product_options" to "anon";
grant DELETE on public."product_options" to "anon";
grant TRUNCATE on public."product_options" to "anon";
grant REFERENCES on public."product_options" to "anon";
grant TRIGGER on public."product_options" to "anon";
grant INSERT on public."product_options" to "authenticated";
grant SELECT on public."product_options" to "authenticated";
grant UPDATE on public."product_options" to "authenticated";
grant DELETE on public."product_options" to "authenticated";
grant TRUNCATE on public."product_options" to "authenticated";
grant REFERENCES on public."product_options" to "authenticated";
grant TRIGGER on public."product_options" to "authenticated";
grant INSERT on public."product_options" to "service_role";
grant SELECT on public."product_options" to "service_role";
grant UPDATE on public."product_options" to "service_role";
grant DELETE on public."product_options" to "service_role";
grant TRUNCATE on public."product_options" to "service_role";
grant REFERENCES on public."product_options" to "service_role";
grant TRIGGER on public."product_options" to "service_role";
grant INSERT on public."delivery_zones" to "anon";
grant SELECT on public."delivery_zones" to "anon";
grant UPDATE on public."delivery_zones" to "anon";
grant DELETE on public."delivery_zones" to "anon";
grant TRUNCATE on public."delivery_zones" to "anon";
grant REFERENCES on public."delivery_zones" to "anon";
grant TRIGGER on public."delivery_zones" to "anon";
grant INSERT on public."delivery_zones" to "authenticated";
grant SELECT on public."delivery_zones" to "authenticated";
grant UPDATE on public."delivery_zones" to "authenticated";
grant DELETE on public."delivery_zones" to "authenticated";
grant TRUNCATE on public."delivery_zones" to "authenticated";
grant REFERENCES on public."delivery_zones" to "authenticated";
grant TRIGGER on public."delivery_zones" to "authenticated";
grant INSERT on public."delivery_zones" to "service_role";
grant SELECT on public."delivery_zones" to "service_role";
grant UPDATE on public."delivery_zones" to "service_role";
grant DELETE on public."delivery_zones" to "service_role";
grant TRUNCATE on public."delivery_zones" to "service_role";
grant REFERENCES on public."delivery_zones" to "service_role";
grant TRIGGER on public."delivery_zones" to "service_role";
grant INSERT on public."refunds" to "anon";
grant SELECT on public."refunds" to "anon";
grant UPDATE on public."refunds" to "anon";
grant DELETE on public."refunds" to "anon";
grant TRUNCATE on public."refunds" to "anon";
grant REFERENCES on public."refunds" to "anon";
grant TRIGGER on public."refunds" to "anon";
grant INSERT on public."refunds" to "authenticated";
grant SELECT on public."refunds" to "authenticated";
grant UPDATE on public."refunds" to "authenticated";
grant DELETE on public."refunds" to "authenticated";
grant TRUNCATE on public."refunds" to "authenticated";
grant REFERENCES on public."refunds" to "authenticated";
grant TRIGGER on public."refunds" to "authenticated";
grant INSERT on public."refunds" to "service_role";
grant SELECT on public."refunds" to "service_role";
grant UPDATE on public."refunds" to "service_role";
grant DELETE on public."refunds" to "service_role";
grant TRUNCATE on public."refunds" to "service_role";
grant REFERENCES on public."refunds" to "service_role";
grant TRIGGER on public."refunds" to "service_role";
grant INSERT on public."dispatch_offers" to "anon";
grant SELECT on public."dispatch_offers" to "anon";
grant UPDATE on public."dispatch_offers" to "anon";
grant DELETE on public."dispatch_offers" to "anon";
grant TRUNCATE on public."dispatch_offers" to "anon";
grant REFERENCES on public."dispatch_offers" to "anon";
grant TRIGGER on public."dispatch_offers" to "anon";
grant INSERT on public."dispatch_offers" to "authenticated";
grant SELECT on public."dispatch_offers" to "authenticated";
grant UPDATE on public."dispatch_offers" to "authenticated";
grant DELETE on public."dispatch_offers" to "authenticated";
grant TRUNCATE on public."dispatch_offers" to "authenticated";
grant REFERENCES on public."dispatch_offers" to "authenticated";
grant TRIGGER on public."dispatch_offers" to "authenticated";
grant INSERT on public."dispatch_offers" to "service_role";
grant SELECT on public."dispatch_offers" to "service_role";
grant UPDATE on public."dispatch_offers" to "service_role";
grant DELETE on public."dispatch_offers" to "service_role";
grant TRUNCATE on public."dispatch_offers" to "service_role";
grant REFERENCES on public."dispatch_offers" to "service_role";
grant TRIGGER on public."dispatch_offers" to "service_role";
grant INSERT on public."deliveries" to "anon";
grant SELECT on public."deliveries" to "anon";
grant UPDATE on public."deliveries" to "anon";
grant DELETE on public."deliveries" to "anon";
grant TRUNCATE on public."deliveries" to "anon";
grant REFERENCES on public."deliveries" to "anon";
grant TRIGGER on public."deliveries" to "anon";
grant INSERT on public."deliveries" to "authenticated";
grant SELECT on public."deliveries" to "authenticated";
grant UPDATE on public."deliveries" to "authenticated";
grant DELETE on public."deliveries" to "authenticated";
grant TRUNCATE on public."deliveries" to "authenticated";
grant REFERENCES on public."deliveries" to "authenticated";
grant TRIGGER on public."deliveries" to "authenticated";
grant INSERT on public."deliveries" to "service_role";
grant SELECT on public."deliveries" to "service_role";
grant UPDATE on public."deliveries" to "service_role";
grant DELETE on public."deliveries" to "service_role";
grant TRUNCATE on public."deliveries" to "service_role";
grant REFERENCES on public."deliveries" to "service_role";
grant TRIGGER on public."deliveries" to "service_role";
grant INSERT on public."platform_settings" to "anon";
grant SELECT on public."platform_settings" to "anon";
grant UPDATE on public."platform_settings" to "anon";
grant DELETE on public."platform_settings" to "anon";
grant TRUNCATE on public."platform_settings" to "anon";
grant REFERENCES on public."platform_settings" to "anon";
grant TRIGGER on public."platform_settings" to "anon";
grant INSERT on public."platform_settings" to "authenticated";
grant SELECT on public."platform_settings" to "authenticated";
grant UPDATE on public."platform_settings" to "authenticated";
grant DELETE on public."platform_settings" to "authenticated";
grant TRUNCATE on public."platform_settings" to "authenticated";
grant REFERENCES on public."platform_settings" to "authenticated";
grant TRIGGER on public."platform_settings" to "authenticated";
grant INSERT on public."platform_settings" to "service_role";
grant SELECT on public."platform_settings" to "service_role";
grant UPDATE on public."platform_settings" to "service_role";
grant DELETE on public."platform_settings" to "service_role";
grant TRUNCATE on public."platform_settings" to "service_role";
grant REFERENCES on public."platform_settings" to "service_role";
grant TRIGGER on public."platform_settings" to "service_role";
grant INSERT on public."profiles" to "anon";
grant SELECT on public."profiles" to "anon";
grant UPDATE on public."profiles" to "anon";
grant DELETE on public."profiles" to "anon";
grant TRUNCATE on public."profiles" to "anon";
grant REFERENCES on public."profiles" to "anon";
grant TRIGGER on public."profiles" to "anon";
grant INSERT on public."profiles" to "authenticated";
grant SELECT on public."profiles" to "authenticated";
grant UPDATE on public."profiles" to "authenticated";
grant DELETE on public."profiles" to "authenticated";
grant TRUNCATE on public."profiles" to "authenticated";
grant REFERENCES on public."profiles" to "authenticated";
grant TRIGGER on public."profiles" to "authenticated";
grant INSERT on public."profiles" to "service_role";
grant SELECT on public."profiles" to "service_role";
grant UPDATE on public."profiles" to "service_role";
grant DELETE on public."profiles" to "service_role";
grant TRUNCATE on public."profiles" to "service_role";
grant REFERENCES on public."profiles" to "service_role";
grant TRIGGER on public."profiles" to "service_role";
grant INSERT on public."user_roles" to "anon";
grant SELECT on public."user_roles" to "anon";
grant UPDATE on public."user_roles" to "anon";
grant DELETE on public."user_roles" to "anon";
grant TRUNCATE on public."user_roles" to "anon";
grant REFERENCES on public."user_roles" to "anon";
grant TRIGGER on public."user_roles" to "anon";
grant INSERT on public."user_roles" to "authenticated";
grant SELECT on public."user_roles" to "authenticated";
grant UPDATE on public."user_roles" to "authenticated";
grant DELETE on public."user_roles" to "authenticated";
grant TRUNCATE on public."user_roles" to "authenticated";
grant REFERENCES on public."user_roles" to "authenticated";
grant TRIGGER on public."user_roles" to "authenticated";
grant INSERT on public."user_roles" to "service_role";
grant SELECT on public."user_roles" to "service_role";
grant UPDATE on public."user_roles" to "service_role";
grant DELETE on public."user_roles" to "service_role";
grant TRUNCATE on public."user_roles" to "service_role";
grant REFERENCES on public."user_roles" to "service_role";
grant TRIGGER on public."user_roles" to "service_role";
grant INSERT on public."addresses" to "anon";
grant SELECT on public."addresses" to "anon";
grant UPDATE on public."addresses" to "anon";
grant DELETE on public."addresses" to "anon";
grant TRUNCATE on public."addresses" to "anon";
grant REFERENCES on public."addresses" to "anon";
grant TRIGGER on public."addresses" to "anon";
grant INSERT on public."addresses" to "authenticated";
grant SELECT on public."addresses" to "authenticated";
grant UPDATE on public."addresses" to "authenticated";
grant DELETE on public."addresses" to "authenticated";
grant TRUNCATE on public."addresses" to "authenticated";
grant REFERENCES on public."addresses" to "authenticated";
grant TRIGGER on public."addresses" to "authenticated";
grant INSERT on public."addresses" to "service_role";
grant SELECT on public."addresses" to "service_role";
grant UPDATE on public."addresses" to "service_role";
grant DELETE on public."addresses" to "service_role";
grant TRUNCATE on public."addresses" to "service_role";
grant REFERENCES on public."addresses" to "service_role";
grant TRIGGER on public."addresses" to "service_role";
grant INSERT on public."orders" to "anon";
grant SELECT on public."orders" to "anon";
grant UPDATE on public."orders" to "anon";
grant DELETE on public."orders" to "anon";
grant TRUNCATE on public."orders" to "anon";
grant REFERENCES on public."orders" to "anon";
grant TRIGGER on public."orders" to "anon";
grant INSERT on public."orders" to "authenticated";
grant SELECT on public."orders" to "authenticated";
grant UPDATE on public."orders" to "authenticated";
grant DELETE on public."orders" to "authenticated";
grant TRUNCATE on public."orders" to "authenticated";
grant REFERENCES on public."orders" to "authenticated";
grant TRIGGER on public."orders" to "authenticated";
grant INSERT on public."orders" to "service_role";
grant SELECT on public."orders" to "service_role";
grant UPDATE on public."orders" to "service_role";
grant DELETE on public."orders" to "service_role";
grant TRUNCATE on public."orders" to "service_role";
grant REFERENCES on public."orders" to "service_role";
grant TRIGGER on public."orders" to "service_role";
grant INSERT on public."merchant_staff" to "anon";
grant SELECT on public."merchant_staff" to "anon";
grant UPDATE on public."merchant_staff" to "anon";
grant DELETE on public."merchant_staff" to "anon";
grant TRUNCATE on public."merchant_staff" to "anon";
grant REFERENCES on public."merchant_staff" to "anon";
grant TRIGGER on public."merchant_staff" to "anon";
grant INSERT on public."merchant_staff" to "authenticated";
grant SELECT on public."merchant_staff" to "authenticated";
grant UPDATE on public."merchant_staff" to "authenticated";
grant DELETE on public."merchant_staff" to "authenticated";
grant TRUNCATE on public."merchant_staff" to "authenticated";
grant REFERENCES on public."merchant_staff" to "authenticated";
grant TRIGGER on public."merchant_staff" to "authenticated";
grant INSERT on public."merchant_staff" to "service_role";
grant SELECT on public."merchant_staff" to "service_role";
grant UPDATE on public."merchant_staff" to "service_role";
grant DELETE on public."merchant_staff" to "service_role";
grant TRUNCATE on public."merchant_staff" to "service_role";
grant REFERENCES on public."merchant_staff" to "service_role";
grant TRIGGER on public."merchant_staff" to "service_role";
grant INSERT on public."merchant_branches" to "anon";
grant SELECT on public."merchant_branches" to "anon";
grant UPDATE on public."merchant_branches" to "anon";
grant DELETE on public."merchant_branches" to "anon";
grant TRUNCATE on public."merchant_branches" to "anon";
grant REFERENCES on public."merchant_branches" to "anon";
grant TRIGGER on public."merchant_branches" to "anon";
grant INSERT on public."merchant_branches" to "authenticated";
grant SELECT on public."merchant_branches" to "authenticated";
grant UPDATE on public."merchant_branches" to "authenticated";
grant DELETE on public."merchant_branches" to "authenticated";
grant TRUNCATE on public."merchant_branches" to "authenticated";
grant REFERENCES on public."merchant_branches" to "authenticated";
grant TRIGGER on public."merchant_branches" to "authenticated";
grant INSERT on public."merchant_branches" to "service_role";
grant SELECT on public."merchant_branches" to "service_role";
grant UPDATE on public."merchant_branches" to "service_role";
grant DELETE on public."merchant_branches" to "service_role";
grant TRUNCATE on public."merchant_branches" to "service_role";
grant REFERENCES on public."merchant_branches" to "service_role";
grant TRIGGER on public."merchant_branches" to "service_role";
grant INSERT on public."product_categories" to "anon";
grant SELECT on public."product_categories" to "anon";
grant UPDATE on public."product_categories" to "anon";
grant DELETE on public."product_categories" to "anon";
grant TRUNCATE on public."product_categories" to "anon";
grant REFERENCES on public."product_categories" to "anon";
grant TRIGGER on public."product_categories" to "anon";
grant INSERT on public."product_categories" to "authenticated";
grant SELECT on public."product_categories" to "authenticated";
grant UPDATE on public."product_categories" to "authenticated";
grant DELETE on public."product_categories" to "authenticated";
grant TRUNCATE on public."product_categories" to "authenticated";
grant REFERENCES on public."product_categories" to "authenticated";
grant TRIGGER on public."product_categories" to "authenticated";
grant INSERT on public."product_categories" to "service_role";
grant SELECT on public."product_categories" to "service_role";
grant UPDATE on public."product_categories" to "service_role";
grant DELETE on public."product_categories" to "service_role";
grant TRUNCATE on public."product_categories" to "service_role";
grant REFERENCES on public."product_categories" to "service_role";
grant TRIGGER on public."product_categories" to "service_role";
grant INSERT on public."drivers" to "anon";
grant SELECT on public."drivers" to "anon";
grant UPDATE on public."drivers" to "anon";
grant DELETE on public."drivers" to "anon";
grant TRUNCATE on public."drivers" to "anon";
grant REFERENCES on public."drivers" to "anon";
grant TRIGGER on public."drivers" to "anon";
grant INSERT on public."drivers" to "authenticated";
grant SELECT on public."drivers" to "authenticated";
grant UPDATE on public."drivers" to "authenticated";
grant DELETE on public."drivers" to "authenticated";
grant TRUNCATE on public."drivers" to "authenticated";
grant REFERENCES on public."drivers" to "authenticated";
grant TRIGGER on public."drivers" to "authenticated";
grant INSERT on public."drivers" to "service_role";
grant SELECT on public."drivers" to "service_role";
grant UPDATE on public."drivers" to "service_role";
grant DELETE on public."drivers" to "service_role";
grant TRUNCATE on public."drivers" to "service_role";
grant REFERENCES on public."drivers" to "service_role";
grant TRIGGER on public."drivers" to "service_role";
grant INSERT on public."driver_locations" to "anon";
grant SELECT on public."driver_locations" to "anon";
grant UPDATE on public."driver_locations" to "anon";
grant DELETE on public."driver_locations" to "anon";
grant TRUNCATE on public."driver_locations" to "anon";
grant REFERENCES on public."driver_locations" to "anon";
grant TRIGGER on public."driver_locations" to "anon";
grant INSERT on public."driver_locations" to "authenticated";
grant SELECT on public."driver_locations" to "authenticated";
grant UPDATE on public."driver_locations" to "authenticated";
grant DELETE on public."driver_locations" to "authenticated";
grant TRUNCATE on public."driver_locations" to "authenticated";
grant REFERENCES on public."driver_locations" to "authenticated";
grant TRIGGER on public."driver_locations" to "authenticated";
grant INSERT on public."driver_locations" to "service_role";
grant SELECT on public."driver_locations" to "service_role";
grant UPDATE on public."driver_locations" to "service_role";
grant DELETE on public."driver_locations" to "service_role";
grant TRUNCATE on public."driver_locations" to "service_role";
grant REFERENCES on public."driver_locations" to "service_role";
grant TRIGGER on public."driver_locations" to "service_role";
grant INSERT on public."order_items" to "anon";
grant SELECT on public."order_items" to "anon";
grant UPDATE on public."order_items" to "anon";
grant DELETE on public."order_items" to "anon";
grant TRUNCATE on public."order_items" to "anon";
grant REFERENCES on public."order_items" to "anon";
grant TRIGGER on public."order_items" to "anon";
grant INSERT on public."order_items" to "authenticated";
grant SELECT on public."order_items" to "authenticated";
grant UPDATE on public."order_items" to "authenticated";
grant DELETE on public."order_items" to "authenticated";
grant TRUNCATE on public."order_items" to "authenticated";
grant REFERENCES on public."order_items" to "authenticated";
grant TRIGGER on public."order_items" to "authenticated";
grant INSERT on public."order_items" to "service_role";
grant SELECT on public."order_items" to "service_role";
grant UPDATE on public."order_items" to "service_role";
grant DELETE on public."order_items" to "service_role";
grant TRUNCATE on public."order_items" to "service_role";
grant REFERENCES on public."order_items" to "service_role";
grant TRIGGER on public."order_items" to "service_role";
grant INSERT on public."order_status_history" to "anon";
grant SELECT on public."order_status_history" to "anon";
grant UPDATE on public."order_status_history" to "anon";
grant DELETE on public."order_status_history" to "anon";
grant TRUNCATE on public."order_status_history" to "anon";
grant REFERENCES on public."order_status_history" to "anon";
grant TRIGGER on public."order_status_history" to "anon";
grant INSERT on public."order_status_history" to "authenticated";
grant SELECT on public."order_status_history" to "authenticated";
grant UPDATE on public."order_status_history" to "authenticated";
grant DELETE on public."order_status_history" to "authenticated";
grant TRUNCATE on public."order_status_history" to "authenticated";
grant REFERENCES on public."order_status_history" to "authenticated";
grant TRIGGER on public."order_status_history" to "authenticated";
grant INSERT on public."order_status_history" to "service_role";
grant SELECT on public."order_status_history" to "service_role";
grant UPDATE on public."order_status_history" to "service_role";
grant DELETE on public."order_status_history" to "service_role";
grant TRUNCATE on public."order_status_history" to "service_role";
grant REFERENCES on public."order_status_history" to "service_role";
grant TRIGGER on public."order_status_history" to "service_role";
grant INSERT on public."payments" to "anon";
grant SELECT on public."payments" to "anon";
grant UPDATE on public."payments" to "anon";
grant DELETE on public."payments" to "anon";
grant TRUNCATE on public."payments" to "anon";
grant REFERENCES on public."payments" to "anon";
grant TRIGGER on public."payments" to "anon";
grant INSERT on public."payments" to "authenticated";
grant SELECT on public."payments" to "authenticated";
grant UPDATE on public."payments" to "authenticated";
grant DELETE on public."payments" to "authenticated";
grant TRUNCATE on public."payments" to "authenticated";
grant REFERENCES on public."payments" to "authenticated";
grant TRIGGER on public."payments" to "authenticated";
grant INSERT on public."payments" to "service_role";
grant SELECT on public."payments" to "service_role";
grant UPDATE on public."payments" to "service_role";
grant DELETE on public."payments" to "service_role";
grant TRUNCATE on public."payments" to "service_role";
grant REFERENCES on public."payments" to "service_role";
grant TRIGGER on public."payments" to "service_role";
grant INSERT on public."notifications" to "anon";
grant SELECT on public."notifications" to "anon";
grant UPDATE on public."notifications" to "anon";
grant DELETE on public."notifications" to "anon";
grant TRUNCATE on public."notifications" to "anon";
grant REFERENCES on public."notifications" to "anon";
grant TRIGGER on public."notifications" to "anon";
grant INSERT on public."notifications" to "authenticated";
grant SELECT on public."notifications" to "authenticated";
grant UPDATE on public."notifications" to "authenticated";
grant DELETE on public."notifications" to "authenticated";
grant TRUNCATE on public."notifications" to "authenticated";
grant REFERENCES on public."notifications" to "authenticated";
grant TRIGGER on public."notifications" to "authenticated";
grant INSERT on public."notifications" to "service_role";
grant SELECT on public."notifications" to "service_role";
grant UPDATE on public."notifications" to "service_role";
grant DELETE on public."notifications" to "service_role";
grant TRUNCATE on public."notifications" to "service_role";
grant REFERENCES on public."notifications" to "service_role";
grant TRIGGER on public."notifications" to "service_role";
grant INSERT on public."audit_logs" to "anon";
grant SELECT on public."audit_logs" to "anon";
grant UPDATE on public."audit_logs" to "anon";
grant DELETE on public."audit_logs" to "anon";
grant TRUNCATE on public."audit_logs" to "anon";
grant REFERENCES on public."audit_logs" to "anon";
grant TRIGGER on public."audit_logs" to "anon";
grant INSERT on public."audit_logs" to "authenticated";
grant SELECT on public."audit_logs" to "authenticated";
grant UPDATE on public."audit_logs" to "authenticated";
grant DELETE on public."audit_logs" to "authenticated";
grant TRUNCATE on public."audit_logs" to "authenticated";
grant REFERENCES on public."audit_logs" to "authenticated";
grant TRIGGER on public."audit_logs" to "authenticated";
grant INSERT on public."audit_logs" to "service_role";
grant SELECT on public."audit_logs" to "service_role";
grant UPDATE on public."audit_logs" to "service_role";
grant DELETE on public."audit_logs" to "service_role";
grant TRUNCATE on public."audit_logs" to "service_role";
grant REFERENCES on public."audit_logs" to "service_role";
grant TRIGGER on public."audit_logs" to "service_role";
grant INSERT on public."payment_events" to "anon";
grant SELECT on public."payment_events" to "anon";
grant UPDATE on public."payment_events" to "anon";
grant DELETE on public."payment_events" to "anon";
grant TRUNCATE on public."payment_events" to "anon";
grant REFERENCES on public."payment_events" to "anon";
grant TRIGGER on public."payment_events" to "anon";
grant INSERT on public."payment_events" to "authenticated";
grant SELECT on public."payment_events" to "authenticated";
grant UPDATE on public."payment_events" to "authenticated";
grant DELETE on public."payment_events" to "authenticated";
grant TRUNCATE on public."payment_events" to "authenticated";
grant REFERENCES on public."payment_events" to "authenticated";
grant TRIGGER on public."payment_events" to "authenticated";
grant INSERT on public."payment_events" to "service_role";
grant SELECT on public."payment_events" to "service_role";
grant UPDATE on public."payment_events" to "service_role";
grant DELETE on public."payment_events" to "service_role";
grant TRUNCATE on public."payment_events" to "service_role";
grant REFERENCES on public."payment_events" to "service_role";
grant TRIGGER on public."payment_events" to "service_role";
grant INSERT on public."delivery_events" to "anon";
grant SELECT on public."delivery_events" to "anon";
grant UPDATE on public."delivery_events" to "anon";
grant DELETE on public."delivery_events" to "anon";
grant TRUNCATE on public."delivery_events" to "anon";
grant REFERENCES on public."delivery_events" to "anon";
grant TRIGGER on public."delivery_events" to "anon";
grant INSERT on public."delivery_events" to "authenticated";
grant SELECT on public."delivery_events" to "authenticated";
grant UPDATE on public."delivery_events" to "authenticated";
grant DELETE on public."delivery_events" to "authenticated";
grant TRUNCATE on public."delivery_events" to "authenticated";
grant REFERENCES on public."delivery_events" to "authenticated";
grant TRIGGER on public."delivery_events" to "authenticated";
grant INSERT on public."delivery_events" to "service_role";
grant SELECT on public."delivery_events" to "service_role";
grant UPDATE on public."delivery_events" to "service_role";
grant DELETE on public."delivery_events" to "service_role";
grant TRUNCATE on public."delivery_events" to "service_role";
grant REFERENCES on public."delivery_events" to "service_role";
grant TRIGGER on public."delivery_events" to "service_role";
grant INSERT on public."products" to "anon";
grant SELECT on public."products" to "anon";
grant UPDATE on public."products" to "anon";
grant DELETE on public."products" to "anon";
grant TRUNCATE on public."products" to "anon";
grant REFERENCES on public."products" to "anon";
grant TRIGGER on public."products" to "anon";
grant INSERT on public."products" to "authenticated";
grant SELECT on public."products" to "authenticated";
grant UPDATE on public."products" to "authenticated";
grant DELETE on public."products" to "authenticated";
grant TRUNCATE on public."products" to "authenticated";
grant REFERENCES on public."products" to "authenticated";
grant TRIGGER on public."products" to "authenticated";
grant INSERT on public."products" to "service_role";
grant SELECT on public."products" to "service_role";
grant UPDATE on public."products" to "service_role";
grant DELETE on public."products" to "service_role";
grant TRUNCATE on public."products" to "service_role";
grant REFERENCES on public."products" to "service_role";
grant TRIGGER on public."products" to "service_role";
grant INSERT on public."carts" to "anon";
grant SELECT on public."carts" to "anon";
grant UPDATE on public."carts" to "anon";
grant DELETE on public."carts" to "anon";
grant TRUNCATE on public."carts" to "anon";
grant REFERENCES on public."carts" to "anon";
grant TRIGGER on public."carts" to "anon";
grant INSERT on public."carts" to "authenticated";
grant SELECT on public."carts" to "authenticated";
grant UPDATE on public."carts" to "authenticated";
grant DELETE on public."carts" to "authenticated";
grant TRUNCATE on public."carts" to "authenticated";
grant REFERENCES on public."carts" to "authenticated";
grant TRIGGER on public."carts" to "authenticated";
grant INSERT on public."carts" to "service_role";
grant SELECT on public."carts" to "service_role";
grant UPDATE on public."carts" to "service_role";
grant DELETE on public."carts" to "service_role";
grant TRUNCATE on public."carts" to "service_role";
grant REFERENCES on public."carts" to "service_role";
grant TRIGGER on public."carts" to "service_role";
grant INSERT on public."merchant_hours" to "anon";
grant SELECT on public."merchant_hours" to "anon";
grant UPDATE on public."merchant_hours" to "anon";
grant DELETE on public."merchant_hours" to "anon";
grant TRUNCATE on public."merchant_hours" to "anon";
grant REFERENCES on public."merchant_hours" to "anon";
grant TRIGGER on public."merchant_hours" to "anon";
grant INSERT on public."merchant_hours" to "authenticated";
grant SELECT on public."merchant_hours" to "authenticated";
grant UPDATE on public."merchant_hours" to "authenticated";
grant DELETE on public."merchant_hours" to "authenticated";
grant TRUNCATE on public."merchant_hours" to "authenticated";
grant REFERENCES on public."merchant_hours" to "authenticated";
grant TRIGGER on public."merchant_hours" to "authenticated";
grant INSERT on public."merchant_hours" to "service_role";
grant SELECT on public."merchant_hours" to "service_role";
grant UPDATE on public."merchant_hours" to "service_role";
grant DELETE on public."merchant_hours" to "service_role";
grant TRUNCATE on public."merchant_hours" to "service_role";
grant REFERENCES on public."merchant_hours" to "service_role";
grant TRIGGER on public."merchant_hours" to "service_role";
grant INSERT on public."promotions" to "anon";
grant SELECT on public."promotions" to "anon";
grant UPDATE on public."promotions" to "anon";
grant DELETE on public."promotions" to "anon";
grant TRUNCATE on public."promotions" to "anon";
grant REFERENCES on public."promotions" to "anon";
grant TRIGGER on public."promotions" to "anon";
grant INSERT on public."promotions" to "authenticated";
grant SELECT on public."promotions" to "authenticated";
grant UPDATE on public."promotions" to "authenticated";
grant DELETE on public."promotions" to "authenticated";
grant TRUNCATE on public."promotions" to "authenticated";
grant REFERENCES on public."promotions" to "authenticated";
grant TRIGGER on public."promotions" to "authenticated";
grant INSERT on public."promotions" to "service_role";
grant SELECT on public."promotions" to "service_role";
grant UPDATE on public."promotions" to "service_role";
grant DELETE on public."promotions" to "service_role";
grant TRUNCATE on public."promotions" to "service_role";
grant REFERENCES on public."promotions" to "service_role";
grant TRIGGER on public."promotions" to "service_role";
grant INSERT on public."promotion_redemptions" to "anon";
grant SELECT on public."promotion_redemptions" to "anon";
grant UPDATE on public."promotion_redemptions" to "anon";
grant DELETE on public."promotion_redemptions" to "anon";
grant TRUNCATE on public."promotion_redemptions" to "anon";
grant REFERENCES on public."promotion_redemptions" to "anon";
grant TRIGGER on public."promotion_redemptions" to "anon";
grant INSERT on public."promotion_redemptions" to "authenticated";
grant SELECT on public."promotion_redemptions" to "authenticated";
grant UPDATE on public."promotion_redemptions" to "authenticated";
grant DELETE on public."promotion_redemptions" to "authenticated";
grant TRUNCATE on public."promotion_redemptions" to "authenticated";
grant REFERENCES on public."promotion_redemptions" to "authenticated";
grant TRIGGER on public."promotion_redemptions" to "authenticated";
grant INSERT on public."promotion_redemptions" to "service_role";
grant SELECT on public."promotion_redemptions" to "service_role";
grant UPDATE on public."promotion_redemptions" to "service_role";
grant DELETE on public."promotion_redemptions" to "service_role";
grant TRUNCATE on public."promotion_redemptions" to "service_role";
grant REFERENCES on public."promotion_redemptions" to "service_role";
grant TRIGGER on public."promotion_redemptions" to "service_role";
grant INSERT on public."merchants" to "anon";
grant SELECT on public."merchants" to "anon";
grant UPDATE on public."merchants" to "anon";
grant DELETE on public."merchants" to "anon";
grant TRUNCATE on public."merchants" to "anon";
grant REFERENCES on public."merchants" to "anon";
grant TRIGGER on public."merchants" to "anon";
grant INSERT on public."merchants" to "authenticated";
grant SELECT on public."merchants" to "authenticated";
grant UPDATE on public."merchants" to "authenticated";
grant DELETE on public."merchants" to "authenticated";
grant TRUNCATE on public."merchants" to "authenticated";
grant REFERENCES on public."merchants" to "authenticated";
grant TRIGGER on public."merchants" to "authenticated";
grant INSERT on public."merchants" to "service_role";
grant SELECT on public."merchants" to "service_role";
grant UPDATE on public."merchants" to "service_role";
grant DELETE on public."merchants" to "service_role";
grant TRUNCATE on public."merchants" to "service_role";
grant REFERENCES on public."merchants" to "service_role";
grant TRIGGER on public."merchants" to "service_role";
grant INSERT on public."cart_items" to "anon";
grant SELECT on public."cart_items" to "anon";
grant UPDATE on public."cart_items" to "anon";
grant DELETE on public."cart_items" to "anon";
grant TRUNCATE on public."cart_items" to "anon";
grant REFERENCES on public."cart_items" to "anon";
grant TRIGGER on public."cart_items" to "anon";
grant INSERT on public."cart_items" to "authenticated";
grant SELECT on public."cart_items" to "authenticated";
grant UPDATE on public."cart_items" to "authenticated";
grant DELETE on public."cart_items" to "authenticated";
grant TRUNCATE on public."cart_items" to "authenticated";
grant REFERENCES on public."cart_items" to "authenticated";
grant TRIGGER on public."cart_items" to "authenticated";
grant INSERT on public."cart_items" to "service_role";
grant SELECT on public."cart_items" to "service_role";
grant UPDATE on public."cart_items" to "service_role";
grant DELETE on public."cart_items" to "service_role";
grant TRUNCATE on public."cart_items" to "service_role";
grant REFERENCES on public."cart_items" to "service_role";
grant TRIGGER on public."cart_items" to "service_role";
revoke all on function public.admin_set_driver_approval(uuid,boolean) from public, anon, authenticated;
grant execute on function public.admin_set_driver_approval(uuid,boolean) to "authenticated";
grant execute on function public.admin_set_driver_approval(uuid,boolean) to "service_role";
revoke all on function public.admin_set_merchant_status(uuid,merchant_status) from public, anon, authenticated;
grant execute on function public.admin_set_merchant_status(uuid,merchant_status) to "authenticated";
grant execute on function public.admin_set_merchant_status(uuid,merchant_status) to "service_role";
revoke all on function public.advance_delivery(uuid,order_status) from public, anon, authenticated;
grant execute on function public.advance_delivery(uuid,order_status) to "authenticated";
grant execute on function public.advance_delivery(uuid,order_status) to "service_role";
revoke all on function public.apply_payment_event(uuid,text,payment_status,text,text,jsonb) from public, anon, authenticated;
grant execute on function public.apply_payment_event(uuid,text,payment_status,text,text,jsonb) to "service_role";
revoke all on function public.can_manage_merchant(uuid) from public, anon, authenticated;
grant execute on function public.can_manage_merchant(uuid) to "service_role";
revoke all on function public.checkout_cart(uuid,uuid,text) from public, anon, authenticated;
grant execute on function public.checkout_cart(uuid,uuid,text) to "authenticated";
grant execute on function public.checkout_cart(uuid,uuid,text) to "service_role";
revoke all on function public.checkout_cart_v2(uuid,text,uuid,text) from public, anon, authenticated;
grant execute on function public.checkout_cart_v2(uuid,text,uuid,text) to "authenticated";
grant execute on function public.checkout_cart_v2(uuid,text,uuid,text) to "service_role";
revoke all on function public.handle_new_user() from public, anon, authenticated;
grant execute on function public.handle_new_user() to "service_role";
revoke all on function public.has_role(app_role) from public, anon, authenticated;
grant execute on function public.has_role(app_role) to "service_role";
revoke all on function public.is_admin() from public, anon, authenticated;
grant execute on function public.is_admin() to "service_role";
revoke all on function public.mark_all_notifications_read() from public, anon, authenticated;
grant execute on function public.mark_all_notifications_read() to "authenticated";
grant execute on function public.mark_all_notifications_read() to "service_role";
revoke all on function public.merchant_advance_order(uuid,order_status) from public, anon, authenticated;
grant execute on function public.merchant_advance_order(uuid,order_status) to "authenticated";
grant execute on function public.merchant_advance_order(uuid,order_status) to "service_role";
revoke all on function public.merchant_complete_pickup(uuid) from public, anon, authenticated;
grant execute on function public.merchant_complete_pickup(uuid) to "authenticated";
grant execute on function public.merchant_complete_pickup(uuid) to "service_role";
revoke all on function public.notify_order_change() from public, anon, authenticated;
grant execute on function public.notify_order_change() to "service_role";
revoke all on function public.prepare_payment_session(uuid,text) from public, anon, authenticated;
grant execute on function public.prepare_payment_session(uuid,text) to "authenticated";
grant execute on function public.prepare_payment_session(uuid,text) to "service_role";
revoke all on function public.prepare_yoco_payment(uuid) from public, anon, authenticated;
grant execute on function public.prepare_yoco_payment(uuid) to "authenticated";
grant execute on function public.prepare_yoco_payment(uuid) to "service_role";
revoke all on function public.quote_delivery_fee(uuid,uuid) from public, anon, authenticated;
grant execute on function public.quote_delivery_fee(uuid,uuid) to "authenticated";
grant execute on function public.quote_delivery_fee(uuid,uuid) to "service_role";
revoke all on function public.respond_dispatch_offer(uuid,boolean) from public, anon, authenticated;
grant execute on function public.respond_dispatch_offer(uuid,boolean) to "authenticated";
grant execute on function public.respond_dispatch_offer(uuid,boolean) to "service_role";
revoke all on function public.set_driver_availability(boolean) from public, anon, authenticated;
grant execute on function public.set_driver_availability(boolean) to "authenticated";
grant execute on function public.set_driver_availability(boolean) to "service_role";
revoke all on function public.validate_cart_item_price() from public, anon, authenticated;
grant execute on function public.validate_cart_item_price() to public;
grant execute on function public.validate_cart_item_price() to "anon";
grant execute on function public.validate_cart_item_price() to "authenticated";
grant execute on function public.validate_cart_item_price() to "service_role";
revoke all on function public.validated_option_delta(jsonb,jsonb,jsonb,jsonb) from public, anon, authenticated;
grant execute on function public.validated_option_delta(jsonb,jsonb,jsonb,jsonb) to public;
grant execute on function public.validated_option_delta(jsonb,jsonb,jsonb,jsonb) to "anon";
grant execute on function public.validated_option_delta(jsonb,jsonb,jsonb,jsonb) to "authenticated";
grant execute on function public.validated_option_delta(jsonb,jsonb,jsonb,jsonb) to "service_role";
CREATE TRIGGER trg_notify_order_change AFTER UPDATE OF status, driver_id ON public.orders FOR EACH ROW EXECUTE FUNCTION notify_order_change();
CREATE TRIGGER validate_cart_item_price BEFORE INSERT OR UPDATE ON public.cart_items FOR EACH ROW EXECUTE FUNCTION validate_cart_item_price();
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();


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

drop policy "orders authorised read" on public.orders;
create policy "orders authorised read" on public.orders for select using (
 customer_id=auth.uid() or driver_id=auth.uid() or public.can_manage_merchant(merchant_id) or public.is_admin()
 or exists(select 1 from public.dispatch_offers offer where offer.order_id=orders.id and offer.driver_id=auth.uid() and offer.status='offered' and (offer.expires_at is null or offer.expires_at>now()))
);
CREATE OR REPLACE FUNCTION public.respond_dispatch_offer(p_offer_id uuid, p_accept boolean)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_uid uuid:=auth.uid(); v_offer public.dispatch_offers; v_delivery uuid;
begin
 if v_uid is null then raise exception 'authentication required'; end if;
 select * into v_offer from public.dispatch_offers
 where id=p_offer_id and driver_id=v_uid and status='offered'
 and (expires_at is null or expires_at>now());
 if v_offer.id is null then raise exception 'offer unavailable'; end if;
 if not p_accept then
   update public.dispatch_offers set status='rejected',responded_at=now() where id=p_offer_id and status='offered';
   if not found then raise exception 'offer unavailable'; end if;
   return null;
 end if;
 perform 1 from public.orders where id=v_offer.order_id and driver_id is null and status='ready_for_pickup' and fulfillment_type='delivery' for update;
 if not found then raise exception 'order already assigned or unavailable'; end if;
 perform 1 from public.drivers where user_id=v_uid and approved and state='available' for update;
 if not found then raise exception 'An approved available driver is required'; end if;
 update public.dispatch_offers set status='accepted',responded_at=now() where id=p_offer_id and status='offered' and (expires_at is null or expires_at>now());
 if not found then raise exception 'offer unavailable'; end if;
 update public.orders set driver_id=v_uid,status='driver_assigned',updated_at=now()
 where id=v_offer.order_id and driver_id is null and status='ready_for_pickup' and fulfillment_type='delivery';
 if not found then raise exception 'order already assigned or unavailable'; end if;
 update public.dispatch_offers set status='accepted',responded_at=now() where id=p_offer_id;
 update public.dispatch_offers set status='expired',responded_at=now()
 where order_id=v_offer.order_id and id<>p_offer_id and status='offered';
 insert into public.deliveries(order_id,driver_id) values(v_offer.order_id,v_uid)
 on conflict(order_id) do update set driver_id=excluded.driver_id returning id into v_delivery;
 update public.drivers set state='assigned' where user_id=v_uid;
 insert into public.order_status_history(order_id,previous_status,new_status,actor_id,note)
 values(v_offer.order_id,'ready_for_pickup','driver_assigned',v_uid,'Driver accepted dispatch');
 return v_delivery;
end $function$
;
CREATE OR REPLACE FUNCTION public.set_driver_availability(p_available boolean)
 RETURNS driver_state
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_uid uuid:=auth.uid(); v_state public.driver_state;
begin
 if v_uid is null then raise exception 'authentication required'; end if;
 if not exists(select 1 from public.drivers where user_id=v_uid and approved) then raise exception 'approved driver required'; end if;
 if p_available and exists(select 1 from public.orders where driver_id=v_uid and status in ('driver_assigned','picked_up','out_for_delivery')) then raise exception 'Complete your active delivery before becoming available'; end if;
 v_state:=case when p_available then 'available'::public.driver_state else 'offline'::public.driver_state end;
 update public.drivers set state=v_state where user_id=v_uid;
 return v_state;
end $function$
;
do $$
declare relation text;
begin
 if exists(select 1 from pg_publication where pubname='supabase_realtime') then
  foreach relation in array array['dispatch_offers','products'] loop
   if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename=relation) then
    execute format('alter publication supabase_realtime add table public.%I',relation);
   end if;
  end loop;
 end if;
end $$;

create or replace function public.refresh_cart_prices()
returns void language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); cart uuid;
begin
 if uid is null then raise exception 'Authentication required'; end if;
 select id into cart from public.carts where customer_id=uid for update;
 if cart is not null then update public.cart_items set selected_options=selected_options where cart_id=cart; end if;
end $$;
create or replace function public.checkout_cart_confirmed(p_branch_id uuid,p_fulfillment text,p_expected_total numeric,p_address_id uuid default null,p_notes text default null)
returns uuid language plpgsql security invoker set search_path='' as $$
declare order_id uuid; actual numeric;
begin
 if p_expected_total is null or p_expected_total<0 then raise exception 'Confirm the checkout total'; end if;
 order_id:=public.checkout_cart_v2(p_branch_id,p_fulfillment,p_address_id,p_notes);
 select total into actual from public.orders where id=order_id;
 if actual is distinct from round(p_expected_total,2) then
  raise exception 'Prices changed. Review your cart before paying.';
 end if;
 return order_id;
end $$;
revoke execute on function public.refresh_cart_prices(),public.checkout_cart_confirmed(uuid,text,numeric,uuid,text) from public,anon;
grant execute on function public.refresh_cart_prices(),public.checkout_cart_confirmed(uuid,text,numeric,uuid,text) to authenticated,service_role;

commit;

