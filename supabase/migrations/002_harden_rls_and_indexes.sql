-- Security hardening after core schema
alter table public.product_options enable row level security;
alter table public.delivery_zones enable row level security;
alter table public.refunds enable row level security;
alter table public.dispatch_offers enable row level security;
alter table public.deliveries enable row level security;
alter table public.platform_settings enable row level security;
alter table public.audit_logs enable row level security;

create policy "product options public read" on public.product_options for select using (is_active and exists(select 1 from public.products p join public.merchants m on m.id=p.merchant_id where p.id=product_id and p.is_active and m.status='approved'));
create policy "product options merchant manage" on public.product_options for all using (exists(select 1 from public.products p where p.id=product_id and public.can_manage_merchant(p.merchant_id))) with check (exists(select 1 from public.products p where p.id=product_id and public.can_manage_merchant(p.merchant_id)));
create policy "delivery zones public read" on public.delivery_zones for select using(is_active);
create policy "delivery zones admin manage" on public.delivery_zones for all using(public.is_admin()) with check(public.is_admin());
create policy "refunds authorised read" on public.refunds for select using (exists(select 1 from public.payments p join public.orders o on o.id=p.order_id where p.id=payment_id and (o.customer_id=auth.uid() or public.can_manage_merchant(o.merchant_id) or public.is_admin())));
create policy "dispatch driver read" on public.dispatch_offers for select using(driver_id=auth.uid() or public.is_admin());
create policy "dispatch driver response" on public.dispatch_offers for update using(driver_id=auth.uid() or public.is_admin()) with check(driver_id=auth.uid() or public.is_admin());
create policy "deliveries authorised read" on public.deliveries for select using (driver_id=auth.uid() or exists(select 1 from public.orders o where o.id=order_id and (o.customer_id=auth.uid() or public.can_manage_merchant(o.merchant_id) or public.is_admin())));
create policy "deliveries driver update" on public.deliveries for update using(driver_id=auth.uid() or public.is_admin()) with check(driver_id=auth.uid() or public.is_admin());
create policy "platform settings public read" on public.platform_settings for select using(key in ('support','service_area','minimum_app_version'));
create policy "platform settings admin manage" on public.platform_settings for all using(public.is_admin()) with check(public.is_admin());
create policy "audit admin read" on public.audit_logs for select using(public.is_admin());
create policy "merchant staff member read" on public.merchant_staff for select using(user_id=auth.uid() or public.can_manage_merchant(merchant_id) or public.is_admin());

revoke execute on function public.handle_new_user() from anon, authenticated;
revoke execute on function public.has_role(public.app_role) from anon;
revoke execute on function public.is_admin() from anon;
revoke execute on function public.can_manage_merchant(uuid) from anon;

create index if not exists idx_addresses_customer on public.addresses(customer_id);
create index if not exists idx_merchants_owner on public.merchants(owner_id);
create index if not exists idx_merchant_staff_user on public.merchant_staff(user_id);
create index if not exists idx_branches_merchant on public.merchant_branches(merchant_id);
create index if not exists idx_categories_merchant on public.product_categories(merchant_id);
create index if not exists idx_products_category on public.products(category_id);
create index if not exists idx_product_options_product on public.product_options(product_id);
create index if not exists idx_order_items_order on public.order_items(order_id);
create index if not exists idx_order_items_product on public.order_items(product_id);
create index if not exists idx_order_history_order on public.order_status_history(order_id);
create index if not exists idx_notifications_user on public.notifications(user_id);
create index if not exists idx_refunds_payment on public.refunds(payment_id);
create index if not exists idx_deliveries_driver on public.deliveries(driver_id);
