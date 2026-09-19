-- Production-equivalent transactional checkout schema.
create table if not exists public.carts (
 id uuid primary key default gen_random_uuid(),
 customer_id uuid not null references public.profiles(id) on delete cascade,
 merchant_id uuid references public.merchants(id) on delete cascade,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(customer_id)
);
create table if not exists public.cart_items (
 id uuid primary key default gen_random_uuid(),
 cart_id uuid not null references public.carts(id) on delete cascade,
 product_id uuid not null references public.products(id) on delete cascade,
 quantity int not null check(quantity>0),
 created_at timestamptz not null default now(),
 unique(cart_id,product_id)
);
create table if not exists public.payment_events (
 id bigint generated always as identity primary key,
 payment_id uuid references public.payments(id) on delete cascade,
 provider_event_id text unique,
 event_type text not null,
 payload jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create table if not exists public.delivery_events (
 id bigint generated always as identity primary key,
 delivery_id uuid not null references public.deliveries(id) on delete cascade,
 event_type text not null,
 latitude numeric(9,6), longitude numeric(9,6),
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create table if not exists public.merchant_hours (
 id uuid primary key default gen_random_uuid(),
 branch_id uuid not null references public.merchant_branches(id) on delete cascade,
 day_of_week smallint not null check(day_of_week between 0 and 6),
 opens_at time, closes_at time, is_closed boolean not null default false,
 unique(branch_id,day_of_week)
);
create table if not exists public.promotions (
 id uuid primary key default gen_random_uuid(), code text not null unique,
 merchant_id uuid references public.merchants(id) on delete cascade,
 discount_type text not null check(discount_type in ('fixed','percent','free_delivery')),
 value numeric(12,2) not null default 0, starts_at timestamptz, ends_at timestamptz,
 usage_limit int, is_active boolean not null default true
);
create table if not exists public.promotion_redemptions (
 id uuid primary key default gen_random_uuid(),
 promotion_id uuid not null references public.promotions(id),
 customer_id uuid not null references public.profiles(id),
 order_id uuid not null references public.orders(id),
 created_at timestamptz not null default now(), unique(promotion_id,order_id)
);
alter table public.carts enable row level security;
alter table public.cart_items enable row level security;
create policy "cart owner" on public.carts for all to authenticated
 using(customer_id=(select auth.uid())) with check(customer_id=(select auth.uid()));
create policy "cart item owner" on public.cart_items for all to authenticated
 using(exists(select 1 from public.carts c where c.id=cart_id and c.customer_id=(select auth.uid())))
 with check(exists(select 1 from public.carts c where c.id=cart_id and c.customer_id=(select auth.uid())));
drop policy if exists "orders customer create" on public.orders;
drop policy if exists "orders operator update" on public.orders;
create or replace function public.checkout_cart(p_address_id uuid,p_branch_id uuid,p_notes text default null)
returns uuid language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=auth.uid(); v_cart public.carts; v_address public.addresses;
v_sub numeric(12,2); v_order uuid; v_min numeric(12,2);
begin
 if v_uid is null then raise exception 'authentication required'; end if;
 select * into v_cart from public.carts where customer_id=v_uid for update;
 if v_cart.id is null or v_cart.merchant_id is null then raise exception 'cart is empty'; end if;
 select * into v_address from public.addresses where id=p_address_id and customer_id=v_uid;
 if v_address.id is null then raise exception 'invalid address'; end if;
 select min_order into v_min from public.merchant_branches where id=p_branch_id and merchant_id=v_cart.merchant_id and is_active;
 if not found then raise exception 'invalid branch'; end if;
 select coalesce(sum(p.price*ci.quantity),0) into v_sub from public.cart_items ci
 join public.products p on p.id=ci.product_id
 where ci.cart_id=v_cart.id and p.merchant_id=v_cart.merchant_id and p.is_active
 and (not p.track_stock or coalesce(p.stock_quantity,0)>=ci.quantity);
 if v_sub<=0 then raise exception 'no valid cart items'; end if;
 if v_sub<v_min then raise exception 'minimum order not met'; end if;
 insert into public.orders(customer_id,merchant_id,branch_id,delivery_address_id,subtotal,delivery_fee,service_fee,discount,total,notes,delivery_address_snapshot)
 values(v_uid,v_cart.merchant_id,p_branch_id,p_address_id,v_sub,0,0,0,v_sub,p_notes,to_jsonb(v_address))
 returning id into v_order;
 insert into public.order_items(order_id,product_id,product_name,sku,quantity,unit_price,line_total)
 select v_order,p.id,p.name,p.sku,ci.quantity,p.price,p.price*ci.quantity
 from public.cart_items ci join public.products p on p.id=ci.product_id
 where ci.cart_id=v_cart.id and p.merchant_id=v_cart.merchant_id and p.is_active
 and (not p.track_stock or coalesce(p.stock_quantity,0)>=ci.quantity);
 insert into public.order_status_history(order_id,new_status,actor_id,note)
 values(v_order,'pending_payment',v_uid,'Checkout created');
 delete from public.cart_items where cart_id=v_cart.id;
 update public.carts set merchant_id=null,updated_at=now() where id=v_cart.id;
 return v_order;
end $$;
revoke all on function public.checkout_cart(uuid,uuid,text) from public;
grant execute on function public.checkout_cart(uuid,uuid,text) to authenticated;
create index if not exists idx_cart_items_cart on public.cart_items(cart_id);
create index if not exists idx_payment_events_payment on public.payment_events(payment_id);
create index if not exists idx_delivery_events_delivery on public.delivery_events(delivery_id);
