-- Tunbridge Wells Kebab: initial database schema.
-- Apply to a NEW, isolated Supabase project before any public pilot.
-- Money is always stored as integer pence. Do not change this to decimal/float.

create extension if not exists pgcrypto;

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated, service_role;

create type public.app_role as enum ('owner', 'kitchen', 'driver', 'customer');
create type public.runtime_mode as enum ('demo', 'live');
create type public.order_type as enum ('collection', 'delivery');
create type public.order_status as enum (
  'pending_payment',
  'paid',
  'confirmed',
  'preparing',
  'ready_for_pickup',
  'driver_assigned',
  'driver_en_route_to_pickup',
  'collected',
  'driver_en_route',
  'nearby',
  'delivered',
  'cancelled'
);
create type public.payment_status as enum ('unpaid', 'pending', 'paid', 'failed', 'refunded', 'partially_refunded');
create type public.driver_status as enum ('offline', 'available', 'busy', 'suspended');
create type public.assignment_status as enum ('offered', 'accepted', 'declined', 'reassigned', 'completed', 'cancelled');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 100),
  mobile_e164 text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_roles (
  user_id uuid not null references public.profiles(id) on delete cascade,
  role public.app_role not null,
  granted_by uuid references public.profiles(id) on delete set null,
  granted_at timestamptz not null default now(),
  primary key (user_id, role)
);

-- A signed-up user always receives a profile and the least-privileged role.
-- Owners and staff are promoted only through a protected operations path.
create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.profiles (id, display_name, mobile_e164)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'display_name', ''), nullif(split_part(new.email, '@', 1), ''), 'Customer'),
    nullif(new.raw_user_meta_data ->> 'mobile_e164', '')
  )
  on conflict (id) do nothing;
  insert into public.user_roles (user_id, role)
  values (new.id, 'customer')
  on conflict do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure private.handle_new_user();

create table public.restaurants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique check (slug ~ '^[a-z0-9-]+$'),
  support_phone text,
  support_email text,
  pickup_address text not null,
  latitude numeric(9,6),
  longitude numeric(9,6),
  is_open boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (latitude is null or latitude between -90 and 90),
  check (longitude is null or longitude between -180 and 180)
);

create table public.restaurant_hours (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  weekday smallint not null check (weekday between 0 and 6),
  opens_at time,
  closes_at time,
  is_closed boolean not null default false,
  unique (restaurant_id, weekday),
  check ((is_closed and opens_at is null and closes_at is null) or (not is_closed and opens_at is not null and closes_at is not null))
);

create table public.menu_categories (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  name text not null,
  display_order integer not null default 0,
  is_available boolean not null default true,
  unique (restaurant_id, name)
);

create table public.menu_items (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  category_id uuid not null references public.menu_categories(id) on delete restrict,
  name text not null,
  description text,
  base_price_pence integer not null check (base_price_pence >= 0),
  display_order integer not null default 0,
  is_available boolean not null default true,
  is_featured boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (restaurant_id, name)
);

create table public.menu_item_variants (
  id uuid primary key default gen_random_uuid(),
  menu_item_id uuid not null references public.menu_items(id) on delete cascade,
  name text not null,
  price_pence integer not null check (price_pence >= 0),
  display_order integer not null default 0,
  is_available boolean not null default true,
  unique (menu_item_id, name)
);

create table public.modifier_groups (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  name text not null,
  min_selections integer not null default 0 check (min_selections >= 0),
  max_selections integer not null default 1 check (max_selections >= min_selections),
  is_available boolean not null default true,
  unique (restaurant_id, name)
);

create table public.modifier_options (
  id uuid primary key default gen_random_uuid(),
  modifier_group_id uuid not null references public.modifier_groups(id) on delete cascade,
  name text not null,
  price_delta_pence integer not null default 0,
  display_order integer not null default 0,
  is_available boolean not null default true,
  unique (modifier_group_id, name)
);

create table public.menu_item_modifier_groups (
  menu_item_id uuid not null references public.menu_items(id) on delete cascade,
  modifier_group_id uuid not null references public.modifier_groups(id) on delete cascade,
  display_order integer not null default 0,
  primary key (menu_item_id, modifier_group_id)
);

create table public.fee_policies (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  platform_fee_pence integer not null default 100 check (platform_fee_pence >= 0),
  transaction_fee_pence integer not null default 29 check (transaction_fee_pence >= 0),
  effective_from timestamptz not null default now(),
  published_at timestamptz,
  retired_at timestamptz,
  change_reason text not null check (char_length(change_reason) between 3 and 500),
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  check (retired_at is null or retired_at >= effective_from)
);

create unique index one_published_fee_policy_per_restaurant
  on public.fee_policies (restaurant_id)
  where published_at is not null and retired_at is null;

create table public.delivery_zones (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  name text not null,
  centre_latitude numeric(9,6) not null check (centre_latitude between -90 and 90),
  centre_longitude numeric(9,6) not null check (centre_longitude between -180 and 180),
  radius_metres integer not null check (radius_metres between 250 and 50000),
  delivery_fee_pence integer not null check (delivery_fee_pence >= 0),
  minimum_order_pence integer not null default 0 check (minimum_order_pence >= 0),
  is_available boolean not null default true,
  unique (restaurant_id, name)
);

create table public.runtime_configuration (
  singleton boolean primary key default true check (singleton),
  mode public.runtime_mode not null default 'demo',
  live_readiness_confirmed_at timestamptz,
  live_readiness_confirmed_by uuid references public.profiles(id) on delete set null,
  legal_privacy_url text,
  legal_terms_url text,
  updated_at timestamptz not null default now()
);

insert into public.runtime_configuration (singleton, mode) values (true, 'demo') on conflict do nothing;

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  public_reference text not null unique,
  idempotency_key text not null check (char_length(idempotency_key) between 16 and 200),
  restaurant_id uuid not null references public.restaurants(id) on delete restrict,
  customer_id uuid not null references public.profiles(id) on delete restrict,
  order_type public.order_type not null,
  status public.order_status not null default 'pending_payment',
  payment_status public.payment_status not null default 'unpaid',
  fee_policy_id uuid references public.fee_policies(id) on delete set null,
  delivery_zone_id uuid references public.delivery_zones(id) on delete set null,
  customer_name_snapshot text not null,
  customer_phone_snapshot text not null,
  delivery_address_snapshot jsonb,
  delivery_note text,
  food_subtotal_pence integer not null check (food_subtotal_pence >= 0),
  delivery_fee_pence integer not null default 0 check (delivery_fee_pence >= 0),
  platform_fee_pence integer not null check (platform_fee_pence >= 0),
  transaction_fee_pence integer not null check (transaction_fee_pence >= 0),
  total_pence integer not null check (total_pence >= 0),
  currency char(3) not null default 'GBP' check (currency = 'GBP'),
  estimated_ready_at timestamptz,
  stripe_payment_intent_id text unique,
  is_demo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  delivered_at timestamptz,
  cancelled_at timestamptz,
  cancellation_reason text,
  check ((order_type = 'delivery' and delivery_address_snapshot is not null) or (order_type = 'collection' and delivery_address_snapshot is null)),
  check (total_pence = food_subtotal_pence + delivery_fee_pence + platform_fee_pence + transaction_fee_pence)
);

create unique index orders_customer_idempotency_key_idx on public.orders (customer_id, idempotency_key);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  menu_item_id uuid references public.menu_items(id) on delete set null,
  menu_item_name_snapshot text not null,
  variant_name_snapshot text,
  unit_price_pence integer not null check (unit_price_pence >= 0),
  quantity integer not null check (quantity between 1 and 99),
  customer_note text,
  line_total_pence integer not null check (line_total_pence >= 0),
  check (line_total_pence = unit_price_pence * quantity)
);

create table public.order_item_modifiers (
  id uuid primary key default gen_random_uuid(),
  order_item_id uuid not null references public.order_items(id) on delete cascade,
  modifier_name_snapshot text not null,
  option_name_snapshot text not null,
  price_delta_pence integer not null default 0,
  quantity integer not null default 1 check (quantity between 1 and 99)
);

create table public.order_status_events (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  actor_role public.app_role,
  from_status public.order_status,
  to_status public.order_status,
  event_type text not null,
  customer_message text,
  private_note text,
  created_at timestamptz not null default now()
);

create table public.driver_availability (
  driver_id uuid primary key references public.profiles(id) on delete cascade,
  status public.driver_status not null default 'offline',
  updated_at timestamptz not null default now()
);

create table public.driver_assignments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  driver_id uuid not null references public.profiles(id) on delete restrict,
  assigned_by uuid references public.profiles(id) on delete set null,
  status public.assignment_status not null default 'offered',
  assigned_at timestamptz not null default now(),
  accepted_at timestamptz,
  released_at timestamptz,
  release_reason text
);

create unique index one_active_driver_assignment_per_order
  on public.driver_assignments (order_id)
  where released_at is null and status in ('offered', 'accepted');

create index driver_assignments_driver_active_idx
  on public.driver_assignments (driver_id, assigned_at desc)
  where released_at is null;

create table public.driver_live_locations (
  order_id uuid primary key references public.orders(id) on delete cascade,
  driver_id uuid not null references public.profiles(id) on delete cascade,
  latitude numeric(9,6) not null check (latitude between -90 and 90),
  longitude numeric(9,6) not null check (longitude between -180 and 180),
  accuracy_metres integer check (accuracy_metres between 0 and 10000),
  heading_degrees numeric(5,2) check (heading_degrees is null or heading_degrees between 0 and 360),
  captured_at timestamptz not null,
  received_at timestamptz not null default now(),
  tracking_active boolean not null default true
);

create index driver_live_locations_recent_idx on public.driver_live_locations (received_at desc);

create table public.proof_of_delivery (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete cascade,
  recorded_by uuid references public.profiles(id) on delete set null,
  proof_kind text not null check (proof_kind in ('photo', 'otp', 'handed_to_customer', 'safe_place')),
  storage_path text,
  customer_otp_hash text,
  note text,
  recorded_at timestamptz not null default now()
);

create table public.refunds (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete restrict,
  amount_pence integer not null check (amount_pence > 0),
  reason text not null check (char_length(reason) between 3 and 500),
  stripe_refund_id text unique,
  initiated_by uuid references public.profiles(id) on delete set null,
  status text not null check (status in ('requested', 'succeeded', 'failed')),
  created_at timestamptz not null default now()
);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,
  target_table text,
  target_id uuid,
  reason text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index orders_customer_created_idx on public.orders (customer_id, created_at desc);
create index orders_status_created_idx on public.orders (status, created_at desc);
create index order_events_order_created_idx on public.order_status_events (order_id, created_at asc);

create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at before update on public.profiles
for each row execute procedure private.set_updated_at();
create trigger restaurants_set_updated_at before update on public.restaurants
for each row execute procedure private.set_updated_at();
create trigger menu_items_set_updated_at before update on public.menu_items
for each row execute procedure private.set_updated_at();
create trigger orders_set_updated_at before update on public.orders
for each row execute procedure private.set_updated_at();
create trigger runtime_configuration_set_updated_at before update on public.runtime_configuration
for each row execute procedure private.set_updated_at();

-- This database-level guard remains active even if a future client has a UI bug.
create or replace function private.enforce_order_transition()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if old.status = new.status then
    return new;
  end if;

  if (old.status = 'pending_payment' and new.status in ('paid', 'cancelled'))
     or (old.status = 'paid' and new.status in ('confirmed', 'cancelled'))
     or (old.status = 'confirmed' and new.status in ('preparing', 'cancelled'))
     or (old.status = 'preparing' and new.status in ('ready_for_pickup', 'cancelled'))
     or (old.status = 'ready_for_pickup' and new.status in ('driver_assigned', 'cancelled'))
     or (old.status = 'driver_assigned' and new.status in ('driver_en_route_to_pickup', 'cancelled'))
     or (old.status = 'driver_en_route_to_pickup' and new.status in ('collected', 'cancelled'))
     or (old.status = 'collected' and new.status in ('driver_en_route', 'cancelled'))
     or (old.status = 'driver_en_route' and new.status in ('nearby', 'delivered', 'cancelled'))
     or (old.status = 'nearby' and new.status in ('delivered', 'cancelled')) then
    return new;
  end if;

  raise exception 'Illegal order status transition from % to %', old.status, new.status
    using errcode = '22023';
end;
$$;

create trigger orders_enforce_transition
before update of status on public.orders
for each row execute procedure private.enforce_order_transition();
