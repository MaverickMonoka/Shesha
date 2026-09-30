-- Calculate option prices from merchant configuration, never browser-supplied prices.
create or replace function public.validated_option_delta(p_options jsonb, p_preparation jsonb, p_extras jsonb, p_packs jsonb)
returns numeric language plpgsql immutable set search_path = '' as $$
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
end $$;

create or replace function public.validate_cart_item_price()
returns trigger language plpgsql set search_path = '' as $$
declare product public.products;
begin
  select * into product from public.products where id = new.product_id;
  if product.id is null or not product.is_active then raise exception 'Product is unavailable'; end if;
  if new.quantity is null or new.quantity <= 0 then raise exception 'Invalid quantity'; end if;
  new.option_price_delta := public.validated_option_delta(coalesce(new.selected_options,'[]'),product.preparation_options,product.extras,product.pack_sizes);
  if product.price + new.option_price_delta < 0 then raise exception 'Invalid product price'; end if;
  return new;
end $$;
drop trigger if exists validate_cart_item_price on public.cart_items;
create trigger validate_cart_item_price before insert or update on public.cart_items
for each row execute function public.validate_cart_item_price();

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

