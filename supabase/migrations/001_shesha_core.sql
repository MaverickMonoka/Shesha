-- SHESHA production core schema
-- Supabase/PostgreSQL. Run through Supabase migrations, not from the browser.
create extension if not exists pgcrypto;

do $$ begin create type public.app_role as enum ('customer','merchant_owner','merchant_staff','driver','admin','super_admin'); exception when duplicate_object then null; end $$;
do $$ begin create type public.merchant_status as enum ('draft','submitted','under_review','approved','rejected','suspended'); exception when duplicate_object then null; end $$;
do $$ begin create type public.order_status as enum ('pending_payment','paid','merchant_confirmed','preparing','ready_for_pickup','driver_assigned','picked_up','out_for_delivery','delivered','cancelled','refunded'); exception when duplicate_object then null; end $$;
do $$ begin create type public.payment_status as enum ('pending','processing','paid','failed','cancelled','refunded','partially_refunded'); exception when duplicate_object then null; end $$;
do $$ begin create type public.driver_state as enum ('offline','available','offered_job','assigned','at_pickup','delivering'); exception when duplicate_object then null; end $$;

create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 first_name text, last_name text, phone text, avatar_url text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.user_roles (
 user_id uuid not null references public.profiles(id) on delete cascade,
 role public.app_role not null default 'customer',
 created_at timestamptz not null default now(),
 primary key(user_id,role)
);
create table if not exists public.addresses (
 id uuid primary key default gen_random_uuid(), customer_id uuid not null references public.profiles(id) on delete cascade,
 label text not null default 'Home', address_line text not null, suburb_village text, town text, province text, postal_code text,
 landmark text, instructions text, latitude numeric(9,6), longitude numeric(9,6), is_default boolean not null default false,
 created_at timestamptz not null default now()
);
create table if not exists public.merchants (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null references public.profiles(id),
 name text not null, slug text not null unique, description text, category text, status public.merchant_status not null default 'draft',
 logo_url text, banner_url text, phone text, email text, commission_rate numeric(5,2) not null default 0 check(commission_rate between 0 and 100),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.merchant_staff (
 merchant_id uuid not null references public.merchants(id) on delete cascade, user_id uuid not null references public.profiles(id) on delete cascade,
 is_active boolean not null default true, created_at timestamptz not null default now(), primary key(merchant_id,user_id)
);
create table if not exists public.merchant_branches (
 id uuid primary key default gen_random_uuid(), merchant_id uuid not null references public.merchants(id) on delete cascade,
 name text not null, address_line text not null, suburb_village text, town text, province text, landmark text,
 latitude numeric(9,6), longitude numeric(9,6), phone text, is_open boolean not null default true, is_active boolean not null default true,
 min_order numeric(12,2) not null default 0 check(min_order>=0), created_at timestamptz not null default now()
);
create table if not exists public.product_categories (
 id uuid primary key default gen_random_uuid(), merchant_id uuid not null references public.merchants(id) on delete cascade,
 name text not null, sort_order int not null default 0, is_active boolean not null default true
);
create table if not exists public.products (
 id uuid primary key default gen_random_uuid(), merchant_id uuid not null references public.merchants(id) on delete cascade,
 category_id uuid references public.product_categories(id) on delete set null, name text not null, description text, image_url text,
 price numeric(12,2) not null check(price>=0), sku text, stock_quantity int, track_stock boolean not null default false,
 is_active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.product_options (
 id uuid primary key default gen_random_uuid(), product_id uuid not null references public.products(id) on delete cascade,
 name text not null, price_delta numeric(12,2) not null default 0, is_active boolean not null default true
);
create table if not exists public.delivery_zones (
 id uuid primary key default gen_random_uuid(), name text not null, town text, province text,
 base_fee numeric(12,2) not null default 0 check(base_fee>=0), per_km_fee numeric(12,2) not null default 0 check(per_km_fee>=0),
 max_distance_km numeric(8,2), is_active boolean not null default true
);
create table if not exists public.drivers (
 user_id uuid primary key references public.profiles(id) on delete cascade, state public.driver_state not null default 'offline',
 vehicle_type text, vehicle_registration text, approved boolean not null default false, current_zone_id uuid references public.delivery_zones(id),
 created_at timestamptz not null default now()
);
create table if not exists public.driver_locations (
 driver_id uuid primary key references public.drivers(user_id) on delete cascade,
 latitude numeric(9,6) not null, longitude numeric(9,6) not null, accuracy_m numeric(8,2), heading numeric(6,2),
 updated_at timestamptz not null default now()
);
create table if not exists public.orders (
 id uuid primary key default gen_random_uuid(), order_number bigint generated always as identity unique,
 customer_id uuid not null references public.profiles(id), merchant_id uuid not null references public.merchants(id),
 branch_id uuid not null references public.merchant_branches(id), driver_id uuid references public.drivers(user_id),
 delivery_address_id uuid references public.addresses(id), status public.order_status not null default 'pending_payment',
 currency char(3) not null default 'ZAR', subtotal numeric(12,2) not null check(subtotal>=0), delivery_fee numeric(12,2) not null default 0 check(delivery_fee>=0),
 service_fee numeric(12,2) not null default 0 check(service_fee>=0), discount numeric(12,2) not null default 0 check(discount>=0),
 total numeric(12,2) not null check(total>=0), notes text,
 delivery_address_snapshot jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.order_items (
 id uuid primary key default gen_random_uuid(), order_id uuid not null references public.orders(id) on delete cascade,
 product_id uuid references public.products(id) on delete set null, product_name text not null, sku text,
 quantity int not null check(quantity>0), unit_price numeric(12,2) not null check(unit_price>=0),
 options_snapshot jsonb not null default '[]'::jsonb, line_total numeric(12,2) not null check(line_total>=0)
);
create table if not exists public.order_status_history (
 id bigint generated always as identity primary key, order_id uuid not null references public.orders(id) on delete cascade,
 previous_status public.order_status, new_status public.order_status not null, actor_id uuid references public.profiles(id),
 note text, created_at timestamptz not null default now()
);
create table if not exists public.payments (
 id uuid primary key default gen_random_uuid(), order_id uuid not null references public.orders(id),
 provider text not null, provider_reference text, status public.payment_status not null default 'pending',
 amount numeric(12,2) not null check(amount>=0), currency char(3) not null default 'ZAR', idempotency_key text unique,
 metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.refunds (
 id uuid primary key default gen_random_uuid(), payment_id uuid not null references public.payments(id), amount numeric(12,2) not null check(amount>0),
 provider_reference text, reason text, created_at timestamptz not null default now()
);
create table if not exists public.dispatch_offers (
 id uuid primary key default gen_random_uuid(), order_id uuid not null references public.orders(id) on delete cascade,
 driver_id uuid not null references public.drivers(user_id), status text not null default 'offered' check(status in ('offered','accepted','rejected','expired')),
 offered_at timestamptz not null default now(), expires_at timestamptz, responded_at timestamptz, unique(order_id,driver_id)
);
create table if not exists public.deliveries (
 id uuid primary key default gen_random_uuid(), order_id uuid not null unique references public.orders(id) on delete cascade,
 driver_id uuid references public.drivers(user_id), pickup_at timestamptz, delivered_at timestamptz, proof_url text,
 created_at timestamptz not null default now()
);
create table if not exists public.notifications (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 channel text not null default 'in_app', title text not null, body text not null, read_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists public.platform_settings (
 key text primary key, value jsonb not null, updated_at timestamptz not null default now()
);
create table if not exists public.audit_logs (
 id bigint generated always as identity primary key, actor_id uuid references public.profiles(id), action text not null,
 entity_type text not null, entity_id text, metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now()
);

create index if not exists idx_products_merchant_active on public.products(merchant_id,is_active);
create index if not exists idx_orders_customer_created on public.orders(customer_id,created_at desc);
create index if not exists idx_orders_merchant_status on public.orders(merchant_id,status);
create index if not exists idx_orders_driver_status on public.orders(driver_id,status);
create index if not exists idx_payments_order on public.payments(order_id);
create index if not exists idx_dispatch_driver_status on public.dispatch_offers(driver_id,status);

create or replace function public.has_role(r public.app_role) returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.user_roles where user_id=auth.uid() and role=r)
$$;
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$
 select public.has_role('admin') or public.has_role('super_admin')
$$;
create or replace function public.can_manage_merchant(mid uuid) returns boolean language sql stable security definer set search_path=public as $$
 select public.is_admin() or exists(select 1 from public.merchants m where m.id=mid and m.owner_id=auth.uid())
 or exists(select 1 from public.merchant_staff s where s.merchant_id=mid and s.user_id=auth.uid() and s.is_active)
$$;

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into public.profiles(id,first_name,last_name,phone) values(new.id,new.raw_user_meta_data->>'first_name',new.raw_user_meta_data->>'last_name',new.phone)
 on conflict(id) do nothing;
 insert into public.user_roles(user_id,role) values(new.id,'customer') on conflict do nothing;
 return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.addresses enable row level security;
alter table public.merchants enable row level security;
alter table public.merchant_staff enable row level security;
alter table public.merchant_branches enable row level security;
alter table public.product_categories enable row level security;
alter table public.products enable row level security;
alter table public.drivers enable row level security;
alter table public.driver_locations enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_status_history enable row level security;
alter table public.payments enable row level security;
alter table public.notifications enable row level security;

create policy "profile self read" on public.profiles for select using(id=auth.uid() or public.is_admin());
create policy "profile self update" on public.profiles for update using(id=auth.uid() or public.is_admin()) with check(id=auth.uid() or public.is_admin());
create policy "roles self read" on public.user_roles for select using(user_id=auth.uid() or public.is_admin());
create policy "addresses owner" on public.addresses for all using(customer_id=auth.uid() or public.is_admin()) with check(customer_id=auth.uid() or public.is_admin());
create policy "approved merchants public read" on public.merchants for select using(status='approved' or public.can_manage_merchant(id));
create policy "merchant managers update" on public.merchants for update using(public.can_manage_merchant(id)) with check(public.can_manage_merchant(id));
create policy "branches public read" on public.merchant_branches for select using(is_active or public.can_manage_merchant(merchant_id));
create policy "branches manager write" on public.merchant_branches for all using(public.can_manage_merchant(merchant_id)) with check(public.can_manage_merchant(merchant_id));
create policy "categories public read" on public.product_categories for select using(is_active or public.can_manage_merchant(merchant_id));
create policy "categories manager write" on public.product_categories for all using(public.can_manage_merchant(merchant_id)) with check(public.can_manage_merchant(merchant_id));
create policy "products public read" on public.products for select using(is_active or public.can_manage_merchant(merchant_id));
create policy "products manager write" on public.products for all using(public.can_manage_merchant(merchant_id)) with check(public.can_manage_merchant(merchant_id));
create policy "drivers self read" on public.drivers for select using(user_id=auth.uid() or public.is_admin());
create policy "drivers self update" on public.drivers for update using(user_id=auth.uid() or public.is_admin()) with check(user_id=auth.uid() or public.is_admin());
create policy "driver location self write" on public.driver_locations for all using(driver_id=auth.uid() or public.is_admin()) with check(driver_id=auth.uid() or public.is_admin());
create policy "orders authorised read" on public.orders for select using(customer_id=auth.uid() or driver_id=auth.uid() or public.can_manage_merchant(merchant_id) or public.is_admin());
create policy "orders customer create" on public.orders for insert with check(customer_id=auth.uid());
create policy "orders operator update" on public.orders for update using(driver_id=auth.uid() or public.can_manage_merchant(merchant_id) or public.is_admin());
create policy "order items authorised read" on public.order_items for select using(exists(select 1 from public.orders o where o.id=order_id and (o.customer_id=auth.uid() or o.driver_id=auth.uid() or public.can_manage_merchant(o.merchant_id) or public.is_admin())));
create policy "history authorised read" on public.order_status_history for select using(exists(select 1 from public.orders o where o.id=order_id and (o.customer_id=auth.uid() or o.driver_id=auth.uid() or public.can_manage_merchant(o.merchant_id) or public.is_admin())));
create policy "payments customer merchant admin read" on public.payments for select using(exists(select 1 from public.orders o where o.id=order_id and (o.customer_id=auth.uid() or public.can_manage_merchant(o.merchant_id) or public.is_admin())));
create policy "notifications owner" on public.notifications for select using(user_id=auth.uid() or public.is_admin());
create policy "notifications owner update" on public.notifications for update using(user_id=auth.uid() or public.is_admin());

-- Intentionally no browser INSERT policy for payments/order_items or role elevation.
-- Those writes belong in trusted server/RPC code so totals, permissions and provider state cannot be forged.
