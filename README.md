# Skillence Review — Private Admin Dashboard

This repository contains the admin dashboard only. Supabase is the backend database and authentication provider; GitHub is not a data store.

## Secure setup

1. Create a separate Supabase project in the desired organization (do not mix with SkillType or Ballot Paper).
2. Apply the SQL schema/migration in `schema.sql`.
3. Create an admin in Supabase Auth with an email you control. Set the chosen password **inside Supabase Auth**, not in code. Use a stronger password than one pasted into a chat, and enable MFA if available.
4. Insert the auth user UUID into `public.admin_users` using the Supabase SQL editor. No admin registration endpoint is exposed.
5. Configure `config.js` with project URL, public publishable/anon key and auth email (not a secret). Username display is `Skillenceadmin`. Never put a service-role or secret key in browser code.
6. Deploy admin repository to Vercel. The data table is protected by RLS; only the whitelisted authenticated admin can view private reviews. Use a private Supabase Storage bucket for uploaded files.
7. Connect the student frontend's `config.js` with the project URL and public key; then implement server-side validation/rate-limiting before public rollout.

**Important:** The frontend's existing default count 16 is a display placeholder, not stored records. Accurate average ratings must come from actual submissions. The admin dashboard initially loads up to 500 reviews; paginate for larger datasets. Location map uses submitted coordinates and third-party OpenStreetMap tiles; coordinates may be sent to that map provider when an admin opens the dashboard. Use a self-hosted map provider for stricter privacy.
