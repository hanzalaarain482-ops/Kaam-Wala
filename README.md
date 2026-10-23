# BulaoJi — Apni Price Lagao, Ustaad Bulao!

This branch contains a newly designed public marketing site matching the reference's royal-blue / indigo theme, plus About, Contact, Sign Up, and Sign In pages.

## Run

```bash
npm install
cp .env.example .env
npm run dev
```

Set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` in `.env` to enable real Supabase email/password sign-in and sign-up. The sign-up sends the chosen role in user metadata and redirects verified users based on their database profile. **You must deploy a trusted database trigger that creates `profiles` from sign-up metadata while restricting admin-role registration.** Technician approval is a separate admin step. Never use user-editable metadata as authorization.

Routes: `/` (Home), `/about`, `/contact`, `/login`, `/signup`. The older `/app`, `/tech`, and `/admin` demo pages remain and are **not production-secure**. Do not launch publicly until protected routes, RLS, database functions, and verification tests have been completed.

Contact sends through the visitor's email client using `mailto:`, not a backend. Full marketplace workflows are still in development.
