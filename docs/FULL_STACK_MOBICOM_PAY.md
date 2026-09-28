# SHESHA full-stack + Mobicom Pay

## Stack
- React 19 + Vite customer/merchant/driver/admin PWA
- Supabase Auth, Postgres, RLS, RPCs, Realtime and Edge Functions
- Mobicom Pay as the primary payment gateway interface
- Optional Yoco fallback remains available until Mobicom Pay is fully commissioned

## Payment path
SHESHA checkout -> Supabase create-payment-session -> Mobicom Pay /v1/checkout/sessions -> settlement processor -> Mobicom Pay signed webhook -> Supabase payment-webhook -> apply_payment_event -> order becomes paid.

## Required Supabase Edge Function secrets
- PAYMENT_GATEWAY_BASE_URL
- PAYMENT_GATEWAY_API_KEY
- PAYMENT_GATEWAY_WEBHOOK_SECRET
- SUPABASE_SERVICE_ROLE_KEY (Supabase managed/runtime secret)

## Deploy
Deploy frontend to Netlify or Cloudflare.
Deploy both Edge Functions:
- create-payment-session (JWT required)
- payment-webhook (JWT disabled; HMAC verified in code)

Do not put gateway API keys, webhook secrets, service-role keys or processor credentials in VITE_ variables.
