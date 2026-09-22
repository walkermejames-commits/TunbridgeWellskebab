-- Run once, manually, after creating the first authenticated account.
-- Replace the UUID only in your private SQL editor; never commit a real user ID.

begin;

insert into public.user_roles (user_id, role)
values ('REPLACE-WITH-AUTH-USERS-ID', 'owner')
on conflict do nothing;

insert into public.audit_logs (actor_id, action, target_table, target_id, reason, metadata)
values (
  'REPLACE-WITH-AUTH-USERS-ID',
  'bootstrap_first_owner',
  'user_roles',
  'REPLACE-WITH-AUTH-USERS-ID',
  'Initial owner bootstrap in controlled setup',
  jsonb_build_object('role', 'owner')
);

commit;

