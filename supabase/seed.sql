-- Demo data transcribed from the supplied Tunbridge Wells kebab menu photograph.
-- It is editable by an owner. Confirm allergens, ingredients, stock and the real
-- takeaway address with the merchant before Live mode.

insert into public.restaurants (id, name, slug, pickup_address, latitude, longitude, is_open)
values (
  '11111111-1111-1111-1111-111111111111',
  'Tunbridge Wells Kebab',
  'tunbridge-wells-kebab',
  'Demo pickup address — owner must replace before Live mode',
  51.132400,
  0.263000,
  true
)
on conflict (slug) do update set name = excluded.name;

insert into public.restaurant_hours (restaurant_id, weekday, opens_at, closes_at, is_closed)
select '11111111-1111-1111-1111-111111111111', day, '16:00', '23:00', false
from generate_series(0, 6) as day
on conflict (restaurant_id, weekday) do nothing;

insert into public.menu_categories (restaurant_id, name, display_order)
values
  ('11111111-1111-1111-1111-111111111111', 'Starters', 10),
  ('11111111-1111-1111-1111-111111111111', 'Kebabs', 20),
  ('11111111-1111-1111-1111-111111111111', 'Combination Kebabs', 30),
  ('11111111-1111-1111-1111-111111111111', 'Burgers', 40),
  ('11111111-1111-1111-1111-111111111111', 'Chicken', 50),
  ('11111111-1111-1111-1111-111111111111', 'Fish', 60),
  ('11111111-1111-1111-1111-111111111111', 'Meals', 70)
on conflict (restaurant_id, name) do nothing;

insert into public.menu_items (restaurant_id, category_id, name, description, base_price_pence, display_order)
select '11111111-1111-1111-1111-111111111111', c.id, v.name, v.description, v.price_pence, v.display_order
from public.menu_categories c
join (values
  ('Starters', 'Humus', null::text, 500, 10),
  ('Starters', 'Stuffed Vine Leaves', null::text, 500, 20),
  ('Starters', 'Garlic Mushroom', null::text, 500, 30),
  ('Starters', 'Onion Rings (10 pcs)', null::text, 500, 40),
  ('Starters', 'Mozzarella Stick', null::text, 500, 50),
  ('Starters', 'Halloumi Cheese', null::text, 500, 60),

  ('Kebabs', 'Doner Kebab', 'Served in pitta & salad. Minced lamb roasted on an upright spit.', 800, 10),
  ('Kebabs', 'Chicken Doner', 'Served in pitta & salad. Marinated chicken pieces roasted on an upright spit.', 800, 20),
  ('Kebabs', 'Chicken Shish Kebab', 'Served in pitta & salad. Marinated cubes of chicken grilled on skewers.', 900, 30),
  ('Kebabs', 'Lamb Shish', 'Served in pitta & salad. Marinated cubes of lamb grilled on skewers.', 900, 40),
  ('Kebabs', 'Kofte Kebab', 'Served in pitta & salad. Seasoned minced lamb grilled on skewers.', 900, 50),
  ('Kebabs', 'Doner Meat, Chips', null::text, 800, 60),
  ('Kebabs', 'Doner Meal & Chips in Pitta', null::text, 1000, 70),
  ('Kebabs', 'Chicken Meat & Chips', null::text, 800, 80),
  ('Kebabs', 'Mixed Doner Meat & Chips', null::text, 1100, 90),
  ('Kebabs', 'Lamb Doner Wrap', null::text, 800, 100),
  ('Kebabs', 'Chicken Doner Wrap', null::text, 800, 110),
  ('Kebabs', 'Portion Of Doner Meat', null::text, 800, 120),
  ('Kebabs', 'Mixed Kebab Shish, Kofte & Mixture Of Doner', null::text, 1700, 130),
  ('Kebabs', 'Super Best Shish, Chicken, Kofte & Mixture Of Doner & Chips', null::text, 2500, 140),

  ('Combination Kebabs', 'Lamb Shish & Doner', 'Served with pitta bread & salad.', 1250, 10),
  ('Combination Kebabs', 'Lamb Shish & Chicken Shish', 'Served with pitta bread & salad.', 1250, 20),
  ('Combination Kebabs', 'Chicken Shish & Doner', 'Served with pitta bread & salad.', 1250, 30),
  ('Combination Kebabs', 'Chicken Doner & Lamb Doner', 'Served with pitta bread & salad.', 1250, 40),
  ('Combination Kebabs', 'Lamb Shish & Kofte', 'Served with pitta bread & salad.', 1250, 50),
  ('Combination Kebabs', 'Chicken Shish & Kofte', 'Served with pitta bread & salad.', 1250, 60),
  ('Combination Kebabs', 'Lamb Kofte & Doner', 'Served with pitta bread & salad.', 1250, 70),

  ('Burgers', '1/4 Pounder', 'Served with salad garnish.', 500, 10),
  ('Burgers', '1/4 Pounder With Cheese', 'Served with salad garnish.', 550, 20),
  ('Burgers', '1/4 Pounder With Meat Doner', 'Served with salad garnish.', 800, 30),
  ('Burgers', '1/2 Pounder With Cheese', 'Served with salad garnish.', 700, 40),
  ('Burgers', '1/2 Pounder With Meat Doner', 'Served with salad garnish.', 1000, 50),
  ('Burgers', 'Vege Burger', 'Served with salad garnish.', 500, 60),
  ('Burgers', 'Chicken Burger', 'Served with salad garnish.', 550, 70),
  ('Burgers', 'Chicken Sandwich (Supreme)', 'Served with salad garnish.', 700, 80),
  ('Burgers', 'Giant Burger With Cheese', 'Served with salad garnish.', 1000, 90),
  ('Burgers', 'Doner In Roll', 'Served with salad garnish.', 800, 100),

  ('Chicken', '8 Chicken Wings With Chips - Grilled', null::text, 900, 10),
  ('Chicken', '12 Chicken Nuggets & Chips', null::text, 850, 20),
  ('Chicken', '8 Chicken Nuggets & Chips', null::text, 750, 30),
  ('Chicken', '20 Pcs Popcorn Chicken', null::text, 750, 40),
  ('Chicken', 'Roast Chicken With Chips', null::text, 850, 50),

  ('Fish', 'Cod & Chips', null::text, 850, 10),
  ('Fish', 'Scampi & Chips (10 Pcs)', null::text, 850, 20),

  ('Meals', 'Meal 1 - 1/4 Pounder, Chips & Drink', null::text, 900, 10),
  ('Meals', 'Meal 2 - 1/2 Pounder, Chips & Drink', null::text, 1100, 20),
  ('Meals', 'Meal 3 - Chicken Sandwich, Chips & Drink', null::text, 1100, 30),
  ('Meals', 'Meal 4 - Chicken Twister, Chips & Drink', null::text, 1100, 40),
  ('Meals', 'Meal 5 - Lamb Doner Wrap, Chips & Drink', null::text, 1100, 50),
  ('Meals', 'Meal 6 - Chicken Doner Wrap, Chips & Drink', null::text, 1100, 60)
) as v(category_name, name, description, price_pence, display_order)
  on c.restaurant_id = '11111111-1111-1111-1111-111111111111' and c.name = v.category_name
on conflict (restaurant_id, name) do nothing;

insert into public.menu_item_variants (menu_item_id, name, price_pence, display_order)
select mi.id, v.variant_name, v.price_pence, v.display_order
from public.menu_items mi
join (values
  ('Doner Kebab', 'Medium', 800, 10), ('Doner Kebab', 'Large', 1000, 20),
  ('Chicken Doner', 'Medium', 800, 10), ('Chicken Doner', 'Large', 1000, 20),
  ('Chicken Shish Kebab', 'Medium', 900, 10), ('Chicken Shish Kebab', 'Large', 1250, 20),
  ('Lamb Shish', 'Medium', 900, 10), ('Lamb Shish', 'Large', 1250, 20),
  ('Kofte Kebab', 'Medium', 900, 10), ('Kofte Kebab', 'Large', 1250, 20),
  ('Doner Meat, Chips', 'Medium', 800, 10), ('Doner Meat, Chips', 'Large', 1000, 20),
  ('Chicken Meat & Chips', 'Medium', 800, 10), ('Chicken Meat & Chips', 'Large', 1000, 20),
  ('Lamb Doner Wrap', 'Medium', 800, 10), ('Lamb Doner Wrap', 'Large', 1000, 20),
  ('Chicken Doner Wrap', 'Medium', 800, 10), ('Chicken Doner Wrap', 'Large', 1000, 20),
  ('Portion Of Doner Meat', 'Medium', 800, 10), ('Portion Of Doner Meat', 'Large', 1000, 20),
  ('Meal 5 - Lamb Doner Wrap, Chips & Drink', 'Medium', 1100, 10), ('Meal 5 - Lamb Doner Wrap, Chips & Drink', 'Large', 1350, 20),
  ('Meal 6 - Chicken Doner Wrap, Chips & Drink', 'Medium', 1100, 10), ('Meal 6 - Chicken Doner Wrap, Chips & Drink', 'Large', 1350, 20)
) as v(item_name, variant_name, price_pence, display_order)
  on mi.name = v.item_name
on conflict (menu_item_id, name) do nothing;

insert into public.modifier_groups (id, restaurant_id, name, min_selections, max_selections)
values ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'Sauce and salad preference', 0, 4)
on conflict (restaurant_id, name) do nothing;

insert into public.modifier_options (modifier_group_id, name, price_delta_pence, display_order)
values
  ('22222222-2222-2222-2222-222222222222', 'No salad', 0, 10),
  ('22222222-2222-2222-2222-222222222222', 'Extra salad', 0, 20),
  ('22222222-2222-2222-2222-222222222222', 'Chilli sauce', 0, 30),
  ('22222222-2222-2222-2222-222222222222', 'Garlic sauce', 0, 40),
  ('22222222-2222-2222-2222-222222222222', 'No sauce', 0, 50)
on conflict (modifier_group_id, name) do nothing;

insert into public.menu_item_modifier_groups (menu_item_id, modifier_group_id)
select mi.id, '22222222-2222-2222-2222-222222222222'
from public.menu_items mi
join public.menu_categories c on c.id = mi.category_id
where c.name in ('Kebabs', 'Combination Kebabs')
on conflict do nothing;

insert into public.fee_policies (restaurant_id, platform_fee_pence, transaction_fee_pence, effective_from, published_at, change_reason)
values ('11111111-1111-1111-1111-111111111111', 100, 29, now(), now(), 'Initial transparent customer-fee policy')
on conflict do nothing;

insert into public.delivery_zones (restaurant_id, name, centre_latitude, centre_longitude, radius_metres, delivery_fee_pence, minimum_order_pence)
values ('11111111-1111-1111-1111-111111111111', 'Demo Tunbridge Wells local zone', 51.132400, 0.263000, 4000, 250, 0)
on conflict (restaurant_id, name) do nothing;

