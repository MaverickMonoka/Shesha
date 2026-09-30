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
