# Kaam-Wala — HTML, CSS, JavaScript

Kaam-Wala is a map-first service-booking web project. It includes an offline interactive **demo** and a separate optional **database-connected development mode**. No React, Next.js, Node backend or build tool is required.

## Files
- `index.html` — single-page customer/technician/admin web UI
- `style.css` — responsive design
- `app.js` — standalone simulation, browser GPS, map, minimum-price example, simulated moving technician
- `live.js` — optional real Supabase Auth/REST connection and three connected panel interfaces
- `database.sql` — new Supabase database schema with role policies and server-validated offer floors
- `privacy_patch.sql` — restrict worker GPS viewing and document further privacy work

## Start demo
Open `index.html` via VS Code Live Server or another static server. Leaflet/OpenStreetMap map tiles load over the internet. Use the Customer/Partner/Admin tabs to explore the **simulation**.

## Start database-connected mode
1. Create a **fresh** Supabase project. Run `database.sql` then `privacy_patch.sql` in the SQL Editor (check SQL output for errors). **Do not run this on an existing database without reviewing schema conflicts**.
2. Open `index.html` on HTTPS or localhost. Click the top **LIVE MODE** button.
3. Enter your Supabase project URL and **publishable/anon key only**. Never enter a Supabase service-role or secret key in the browser.
4. Register as a customer or technician, confirm your email if required, then sign in.
5. To set first admin, sign up normally and, **only in Supabase SQL Editor**, execute:
   `update public.kw_profiles set role='admin' where id=(select id from auth.users where email='YOUR_ADMIN_EMAIL');`
6. The admin can review technicians and configure city/area service minimums. Technicians can opt into sharing GPS. Customers can create bookings at or above the server-enforced minimum, raise offers, select an accepting technician, and exchange basic messages.

## What works in connected *development* mode
Email/password accounts, profiles, technician approvals, skills and availability, area-price configuration, offer floor validation, nearby-area job feed, bid acceptance, booking state transitions, messages, support tickets, bookings and a basic dashboard. Data is stored in your Supabase project.

## Critical limitations before production use
- **NOT A FULL PRODUCTION SERVICE.** No app-store binaries, real background continuous GPS, secure proximity dispatch, dynamic routing/ETA, push notifications, in-app calling, technician identity-document verification, wallets, commissions, payment gateway, automated refunds or robust moderation.
- Exact customer addresses and coordinates in the searching-job REST feed are currently readable by approved matching technicians. **Do not collect real user location or run live public bookings until a server-side redacted dispatch feed replaces this**.
- Database connected mode is not yet end-to-end tested against a live Supabase deployment, and RLS/storage/access and sign-in flows require further auditing.
- The moving technician route in demo mode is fictional and explicitly simulated.
- Static HTML/CSS/JavaScript alone cannot securely implement a complete realtime ride-hailing-style platform; persistent data, location authorization, messaging, and matching require a backend such as Supabase and secure server-side functions.

This repository is a starting implementation and preview, not an operational marketplace.
