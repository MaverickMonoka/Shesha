create or replace function public.prepare_yoco_payment(p_order_id uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=auth.uid(); v_order public.orders; v_payment uuid;
begin
 if v_uid is null then raise exception 'authentication required'; end if;
 select * into v_order from public.orders where id=p_order_id and customer_id=v_uid and status='pending_payment' for update;
 if v_order.id is null then raise exception 'payable order not found'; end if;
 select id into v_payment from public.payments where order_id=p_order_id and status in ('pending','processing') order by created_at desc limit 1;
 if v_payment is null then insert into public.payments(order_id,provider,amount,currency,status) values(p_order_id,'yoco',v_order.total,v_order.currency,'pending') returning id into v_payment; end if;
 return jsonb_build_object('payment_id',v_payment,'order_id',v_order.id,'order_number',v_order.order_number,'amount',v_order.total,'currency',v_order.currency);
end $$;
revoke all on function public.prepare_yoco_payment(uuid) from public,anon;
grant execute on function public.prepare_yoco_payment(uuid) to authenticated;