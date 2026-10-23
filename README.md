# BulaoJi screenshot-inspired interface

**Main page:** `index.html` uses `saas.css` and `saas.js`, offering Customer, Technician and Super Admin responsive prototype panels based on the user-supplied reference design. Includes UI pages for booking, service choice, offers, map preview, tracking preview, chats, technician job requests, earnings preview, admin approvals, services, pricing, reports, roles, coupons and support.

**IMPORTANT:** This is a visual and interactive **prototype**, not an exact pixel-for-pixel recreation and not a functional multi-tenant production SaaS. It uses browser localStorage, sample technicians and sample numbers. No real live location tracking, map routing, calling, payments, or secure customer/technician identity verification is provided here.

**Previous experiment:** `legacy.html` retains the earlier map-first frontend and optional Supabase integration via `app.js`, `style.css`, `live.js`, `database.sql`, and `privacy_patch.sql`; it is NOT production-ready and must not be used with real customer addresses until a secured dispatch feed replaces the currently exposed location fields.

Launch the screenshot-inspired UI by opening `index.html` with VS Code Live Server. No package installation is required. Internet is needed for the embedded map shown in the prototype.
