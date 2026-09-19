-- Production RPC execution hardening.
revoke execute on function public.admin_set_driver_approval(uuid,boolean) from public,anon;
revoke execute on function public.admin_set_merchant_status(uuid,public.merchant_status) from public,anon;
revoke execute on function public.advance_delivery(uuid,public.order_status) from public,anon;
revoke execute on function public.respond_dispatch_offer(uuid,boolean) from public,anon;
revoke execute on function public.set_driver_availability(boolean) from public,anon;
revoke execute on function public.checkout_cart(uuid,uuid,text) from public,anon;
revoke execute on function public.handle_new_user() from public,anon,authenticated;
revoke execute on function public.has_role(public.app_role) from public,anon;
revoke execute on function public.is_admin() from public,anon;
revoke execute on function public.can_manage_merchant(uuid) from public,anon;
grant execute on function public.checkout_cart(uuid,uuid,text) to authenticated;
grant execute on function public.set_driver_availability(boolean) to authenticated;
grant execute on function public.respond_dispatch_offer(uuid,boolean) to authenticated;
grant execute on function public.advance_delivery(uuid,public.order_status) to authenticated;
grant execute on function public.admin_set_merchant_status(uuid,public.merchant_status) to authenticated;
grant execute on function public.admin_set_driver_approval(uuid,boolean) to authenticated;
