create or replace function public.apply_payment_event(
  p_payment_id uuid,
  p_provider_reference text,
  p_status public.payment_status,
  p_event_id text,
  p_event_type text,
  p_payload jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $function$
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
$function$;

revoke all on function public.apply_payment_event(uuid,text,public.payment_status,text,text,jsonb) from public, anon, authenticated;
grant execute on function public.apply_payment_event(uuid,text,public.payment_status,text,text,jsonb) to service_role;
