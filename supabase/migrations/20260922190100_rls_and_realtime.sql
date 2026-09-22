-- RLS and Data API grants. Every public table is protected.
-- All writes that affect money, status, dispatch or location occur through Edge Functions.

create or replace function private.has_role(required_role public.app_role)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.user_roles
    where user_id = (select auth.uid()) and role = required_role
  );
$$;

revoke all on function private.has_role(public.app_role) from public;
grant execute on function private.has_role(public.app_role) to authenticated, service_role;

-- Data API needs explicit table grants as well as RLS policies.
grant select on public.restaurants, public.restaurant_hours, public.menu_categories, public.menu_items,
  public.menu_item_variants, public.modifier_groups, public.modifier_options,
  public.menu_item_modifier_groups, public.delivery_zones, public.fee_policies
  to anon, authenticated;
grant select on public.profiles, public.user_roles, public.orders, public.order_items,
  public.order_item_modifiers, public.order_status_events, public.driver_availability,
  public.driver_assignments, public.driver_live_locations, public.proof_of_delivery,
  public.runtime_configuration, public.audit_logs, public.refunds
  to authenticated;

alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.restaurants enable row level security;
alter table public.restaurant_hours enable row level security;
alter table public.menu_categories enable row level security;
alter table public.menu_items enable row level security;
alter table public.menu_item_variants enable row level security;
alter table public.modifier_groups enable row level security;
alter table public.modifier_options enable row level security;
alter table public.menu_item_modifier_groups enable row level security;
alter table public.fee_policies enable row level security;
alter table public.delivery_zones enable row level security;
alter table public.runtime_configuration enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_item_modifiers enable row level security;
alter table public.order_status_events enable row level security;
alter table public.driver_availability enable row level security;
alter table public.driver_assignments enable row level security;
alter table public.driver_live_locations enable row level security;
alter table public.proof_of_delivery enable row level security;
alter table public.refunds enable row level security;
alter table public.audit_logs enable row level security;

create policy "profiles: users read self" on public.profiles
for select to authenticated using (id = (select auth.uid()));
create policy "profiles: owners read all" on public.profiles
for select to authenticated using ((select private.has_role('owner')));

create policy "roles: users read own" on public.user_roles
for select to authenticated using (user_id = (select auth.uid()));
create policy "roles: owners read all" on public.user_roles
for select to authenticated using ((select private.has_role('owner')));

create policy "restaurant: public read" on public.restaurants for select using (true);
create policy "restaurant hours: public read" on public.restaurant_hours for select using (true);
create policy "menu categories: public read" on public.menu_categories for select using (is_available or (select private.has_role('owner')) or (select private.has_role('kitchen')));
create policy "menu items: public read available" on public.menu_items for select using (is_available or (select private.has_role('owner')) or (select private.has_role('kitchen')));
create policy "menu variants: public read available" on public.menu_item_variants for select using (is_available or (select private.has_role('owner')) or (select private.has_role('kitchen')));
create policy "modifier groups: public read" on public.modifier_groups for select using (is_available or (select private.has_role('owner')) or (select private.has_role('kitchen')));
create policy "modifier options: public read" on public.modifier_options for select using (is_available or (select private.has_role('owner')) or (select private.has_role('kitchen')));
create policy "menu modifier mapping: public read" on public.menu_item_modifier_groups for select using (true);
create policy "zones: public read available" on public.delivery_zones for select using (is_available or (select private.has_role('owner')));
create policy "fees: public read published" on public.fee_policies for select using (published_at is not null or (select private.has_role('owner')));

create policy "runtime config: owner read" on public.runtime_configuration
for select to authenticated using ((select private.has_role('owner')));

create policy "orders: customer reads own" on public.orders
for select to authenticated using (customer_id = (select auth.uid()));
create policy "orders: kitchen reads all" on public.orders
for select to authenticated using ((select private.has_role('kitchen')));
create policy "orders: owner reads all" on public.orders
for select to authenticated using ((select private.has_role('owner')));
create policy "orders: assigned driver reads job" on public.orders
for select to authenticated using (
  exists (select 1 from public.driver_assignments da where da.order_id = id and da.driver_id = (select auth.uid()))
);

create policy "order items: order viewers read" on public.order_items
for select to authenticated using (
  exists (select 1 from public.orders o where o.id = order_id)
);
create policy "order modifiers: order viewers read" on public.order_item_modifiers
for select to authenticated using (
  exists (select 1 from public.order_items oi join public.orders o on o.id = oi.order_id where oi.id = order_item_id)
);
create policy "order events: order viewers read" on public.order_status_events
for select to authenticated using (
  exists (select 1 from public.orders o where o.id = order_id)
);

create policy "driver availability: driver reads self" on public.driver_availability
for select to authenticated using (driver_id = (select auth.uid()));
create policy "driver availability: operations read" on public.driver_availability
for select to authenticated using ((select private.has_role('owner')) or (select private.has_role('kitchen')));

create policy "assignments: assigned driver reads self" on public.driver_assignments
for select to authenticated using (driver_id = (select auth.uid()));
create policy "assignments: operations read" on public.driver_assignments
for select to authenticated using ((select private.has_role('owner')) or (select private.has_role('kitchen')));

create policy "live location: active customer reads own delivery" on public.driver_live_locations
for select to authenticated using (
  exists (
    select 1 from public.orders o
    where o.id = order_id
      and o.customer_id = (select auth.uid())
      and o.status in ('driver_en_route', 'nearby')
  )
);
create policy "live location: assigned driver reads own delivery" on public.driver_live_locations
for select to authenticated using (driver_id = (select auth.uid()));
create policy "live location: owners read active operations" on public.driver_live_locations
for select to authenticated using ((select private.has_role('owner')));

create policy "proof: customer reads own" on public.proof_of_delivery
for select to authenticated using (exists (select 1 from public.orders o where o.id = order_id and o.customer_id = (select auth.uid())));
create policy "proof: assigned driver reads own" on public.proof_of_delivery
for select to authenticated using (recorded_by = (select auth.uid()));
create policy "proof: operations read" on public.proof_of_delivery
for select to authenticated using ((select private.has_role('owner')) or (select private.has_role('kitchen')));

create policy "refunds: customer reads own" on public.refunds
for select to authenticated using (exists (select 1 from public.orders o where o.id = order_id and o.customer_id = (select auth.uid())));
create policy "refunds: owners read" on public.refunds
for select to authenticated using ((select private.has_role('owner')));
create policy "audit: owners read" on public.audit_logs
for select to authenticated using ((select private.has_role('owner')));

-- The Realtime publication powers order status and approved live tracking.
alter publication supabase_realtime add table public.orders;
alter publication supabase_realtime add table public.order_status_events;
alter publication supabase_realtime add table public.driver_live_locations;

