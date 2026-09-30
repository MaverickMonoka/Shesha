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
