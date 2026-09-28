revoke execute on function public.checkout_cart_v2(uuid,text,uuid,text) from anon;
revoke execute on function public.mark_all_notifications_read() from anon;
revoke execute on function public.merchant_advance_order(uuid,public.order_status) from anon;
revoke execute on function public.merchant_complete_pickup(uuid) from anon;
revoke execute on function public.prepare_payment_session(uuid,text) from anon;
revoke execute on function public.quote_delivery_fee(uuid,uuid) from anon;
revoke execute on function public.notify_order_change() from anon, authenticated;

create index if not exists idx_cart_items_product on public.cart_items(product_id);
create index if not exists idx_carts_merchant on public.carts(merchant_id);
create index if not exists idx_promotion_redemptions_customer on public.promotion_redemptions(customer_id);
create index if not exists idx_promotion_redemptions_order on public.promotion_redemptions(order_id);
create index if not exists idx_promotions_merchant on public.promotions(merchant_id);
