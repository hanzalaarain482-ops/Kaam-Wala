# BulaoJi / Kaam-Wala

Responsive service-booking **website** with customer, technician and admin dashboards. Source code is in the repository root. The website connects to your own Supabase database (no seeded demo accounts or fake job records).

## Setup

1. Create a **new Supabase project**.
2. Run `supabase/schema.sql` in the Supabase SQL Editor, then `supabase/security_patch.sql`, then `supabase/extra_features.sql` in that order.
3. Update `config.js` with your Supabase project URL and **publishable/anon key only**. Do NOT use your service-role secret.
4. Serve this repository with VS Code Live Server or `python -m http.server 8080`. Open http://localhost:8080 in your browser.
5. Register a customer. For your first admin, register another normal user, then use **Supabase SQL Editor** (never browser UI) to promote that user: `update public.profiles set role='admin' where email='YOUR_EMAIL';`
6. Register technician > update skills and city in profile > admin approves > technician goes Online > customer creates a booking > technician submits a bid > customer accepts > chat > start/finish booking.

## Included

- Customer email/password account, service request with address and offer price, initial GPS coordinates, offer acceptance, booking history and chat.
- Technician accounts, manual approval, city/skill-based job listing, job bids, online/offline toggle and job lifecycle controls.
- Admin management screens for technician approvals, users, service categories, booking list and reviews.
- Supabase SQL schema, Row Level Security, controlled booking status and bid-acceptance functions.
- Responsive dashboard layout.

## Current limits — not production ready

- Web app only; no store-ready Android/iPhone builds.
- **No live moving-map location tracking**, no in-app audio/video calling, no true distance/radius matching. Current interface only captures initial GPS coordinates and can open external Google Maps navigation for an accepted job.
- Chat refreshes periodically, rather than websocket realtime.
- No actual payment processing, commission ledger, wallet, push notifications, CNIC verification/document upload, image uploads, moderation or dispute handling.
- Saved addresses, favorites, in-app notification center, support tickets and admin platform-settings screens are included after running extra_features.sql. Settings do not process payments.
- More testing, audit logging, real-user verification, abuse protection and launch readiness work are essential.
- **Privacy warning:** service request rows currently contain exact addresses and GPS coordinates, which approved technicians can fetch before selection; limit real-user use until address redaction is implemented server-side.

Do not publish real secret keys. Obtain all required consent for live location and protect customers' exact addresses and identity information. This repository is a usable **development starter** and must not be advertised as a complete commercially tested platform.
