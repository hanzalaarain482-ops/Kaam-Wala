# BulaoJi

**Apni Price Lagao, Ustaad Bulao!**

React + Vite + TypeScript marketplace starter. This repository is **under active development**. Its customer, technician, and admin screens use demonstration data; they are not a verified production marketplace.

## Run

```bash
npm install
npm run dev
```

## Routes

- /app — customer demo
- /tech — technician demo
- /admin — admin demo

## PWA

The repository contains a web manifest, an SVG app icon and an offline service worker. Production builds should register the service worker and validate installability in a browser; web push requires a configured push backend and user permission.

## Security

Do not deploy the demo to real users without server-enforced authentication, Postgres RLS, verified technician identity, transactional booking and wallet functions, location-sharing consent and automated security testing. The business-rule tests in `tests/` are illustrative and do not replace database race-condition tests.

## Status

Multi-job UI and production Supabase integration are **not yet complete in this GitHub version**.
