-- Harden operational tables and RPC permissions.
alter table public.payment_events enable row level security;
alter table public.delivery_events enable row level security;
alter table public.merchant_hours enable row level security;
alter table public.promotions enable row level security;
alter table public.promotion_redemptions enable row level security;

create policy "merchant hours public read" on public.merchant_hours for select using(true);
create policy "promotions public active read" on public.promotions for select using(
 is_active and (starts_at is null or starts_at<=now()) and (ends_at is null or ends_at>=now())
);
create policy "redemptions customer read" on public.promotion_redemptions for select to authenticated
 using(customer_id=(select auth.uid()));
create policy "delivery events authorised read" on public.delivery_events for select to authenticated
 using(exists(select 1 from public.deliveries d join public.orders o on o.id=d.order_id
 where d.id=delivery_id and (o.customer_id=(select auth.uid()) or o.driver_id=(select auth.uid()))));

revoke execute on function public.checkout_cart(uuid,uuid,text) from anon;
revoke execute on function public.handle_new_user() from anon,authenticated;
revoke execute on function public.has_role(public.app_role) from anon;
revoke execute on function public.is_admin() from anon;
revoke execute on function public.can_manage_merchant(uuid) from anon;
