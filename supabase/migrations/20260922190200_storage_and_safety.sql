-- Private bucket. No browser/mobile client receives broad write access.
-- A validated Edge Function issues a narrowly scoped signed upload when proof is required.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('proof-of-delivery', 'proof-of-delivery', false, 5242880, array['image/jpeg', 'image/png', 'application/pdf'])
on conflict (id) do update set public = false;

-- A single protected job can later purge expired proof/GPS history; do not add
-- a cron schedule until a real retention period is agreed in the privacy notice.

