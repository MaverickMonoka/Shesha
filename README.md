# SHESHA

**Your town. Delivered.**

SHESHA is a Mobicom X hyperlocal multi-vendor delivery platform for South African towns and communities.

## Architecture
- Supabase PostgreSQL + Auth + RLS + Realtime
- Customer, merchant, driver and admin roles
- Multi-branch merchants and catalogues
- Server-authoritative orders and pricing
- Dispatch, delivery tracking, payments, refunds and settlements
- Netlify-ready web/PWA frontend (next build phase)

## Database
The first production migration is in `supabase/migrations/001_shesha_core.sql`.

It establishes the core data model, immutable order pricing snapshots, audit/status history, RLS helper functions and access policies. Never expose a Supabase service-role key in the browser.

## Product ownership
SHESHA is a Mobicom Business Solutions (Pty) Ltd / Mobicom X product.
