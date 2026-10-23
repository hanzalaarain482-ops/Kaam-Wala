# BulaoJi — Apni Price Lagao, Ustaad Bulao!

React 18 + TypeScript + Vite starter for a Pakistan home and vehicle services marketplace. Customer, technician and admin interfaces are included as **demo screens**; the transactional backend, complete security policies, live tracking and tests are **not yet production-ready**.

## Run

```bash
npm install
npm run dev
```

Copy `.env.example` to `.env` and fill in the Supabase project URL and public anon key if connecting to Supabase.

- Customer: `/app`
- Technician: `/tech`
- Admin: `/admin`
- Auth demo: `/login`

**Do not treat demo screens as protected routes.** Implement verified role guards, complete Postgres RLS, atomic booking status transitions and authorization before deploying or accepting real customers.
