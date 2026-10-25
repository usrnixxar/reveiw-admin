-- Run in a dedicated Supabase project SQL Editor.
create table if not exists public.skillence_reviews (
 id uuid primary key default gen_random_uuid(),
 created_at timestamptz not null default now(),
 student_name text not null check (char_length(trim(student_name)) between 2 and 100),
 email text null check (email is null or (char_length(email)<=254 and position('@' in email)>1)),
 rating int not null check (rating between 1 and 5),
 review text not null check (char_length(trim(review)) between 10 and 1500),
 comment text null check (comment is null or char_length(comment)<=1500),
 attachment_path text null,
 latitude double precision not null check (latitude between -90 and 90),
 longitude double precision not null check (longitude between -180 and 180),
 location_accuracy_meters double precision check (location_accuracy_meters is null or location_accuracy_meters>=0),
 consent_given boolean not null check (consent_given = true)
);
create table if not exists public.admin_users (
 user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.skillence_reviews enable row level security;
alter table public.admin_users enable row level security;
revoke all on public.skillence_reviews from anon, authenticated;
revoke all on public.admin_users from anon, authenticated;
grant usage on schema public to anon, authenticated;
grant insert on public.skillence_reviews to anon, authenticated;
grant select on public.skillence_reviews to authenticated;
grant select on public.admin_users to authenticated;
drop policy if exists "visitors can submit consented reviews" on public.skillence_reviews;
create policy "visitors can submit consented reviews" on public.skillence_reviews
for insert to anon, authenticated
with check (consent_given=true and (attachment_path is null or attachment_path ~ '^[a-f0-9-]{36}\\.(jpg|png|webp|pdf)$'));
drop policy if exists "admins can see reviews" on public.skillence_reviews;
create policy "admins can see reviews" on public.skillence_reviews for select to authenticated
using (exists (select 1 from public.admin_users a where a.user_id = (select auth.uid())));
drop policy if exists "admin can see own membership" on public.admin_users;
create policy "admin can see own membership" on public.admin_users
for select to authenticated using (user_id=(select auth.uid()));
-- Private bucket. Backend validates MIME and size again; browser-side validation is not security.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('review-attachments','review-attachments',false,5242880,array['image/jpeg','image/png','image/webp','application/pdf'])
on conflict(id) do update set public=false,file_size_limit=5242880,allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists "visitors upload new review files" on storage.objects;
create policy "visitors upload new review files" on storage.objects for insert to anon, authenticated
with check (bucket_id='review-attachments' and name ~ '^[a-f0-9-]{36}\\.(jpg|png|webp|pdf)$');
drop policy if exists "admin reads submitted files" on storage.objects;
create policy "admin reads submitted files" on storage.objects for select to authenticated
using (bucket_id='review-attachments' and exists(select 1 from public.admin_users a where a.user_id=(select auth.uid())));
-- After creating the Supabase Auth user, run separately:
-- insert into public.admin_users(user_id) values ('AUTH_USER_UUID_HERE');
-- No public read policy for private review rows, emails or coordinates.
