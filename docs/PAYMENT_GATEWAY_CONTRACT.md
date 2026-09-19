# SHESHA custom payment gateway contract

SHESHA now uses a gateway-agnostic payment adapter. The app calls the Supabase Edge Function `create-payment-session`. That function prefers the custom gateway whenever the custom gateway environment variables are present.

## Required Supabase Edge Function secrets

Set these when the custom gateway is ready:

- `PAYMENT_GATEWAY_BASE_URL` — base URL of the gateway, for example `https://pay.example.com`
- `PAYMENT_GATEWAY_API_KEY` — server-to-server API key used only by the SHESHA Edge Function
- `PAYMENT_GATEWAY_WEBHOOK_SECRET` — shared HMAC secret for webhook verification

Do not expose these values through Vite variables or browser code.

While the custom gateway variables are absent, the adapter can continue using the existing Yoco server-side secret as a temporary fallback. Once the custom gateway variables exist, the custom gateway takes priority automatically.

## Create checkout session

SHESHA calls:

`POST /v1/checkout/sessions`

Headers:

- `Authorization: Bearer <PAYMENT_GATEWAY_API_KEY>`
- `Content-Type: application/json`
- `Idempotency-Key: <stable SHESHA payment attempt key>`

Example body:

```json
{
  "amount_minor": 12500,
  "currency": "ZAR",
  "merchant_reference": "payment-uuid",
  "order_reference": "10042",
  "success_url": "https://shesha.example/orders?payment=return&order=...",
  "cancel_url": "https://shesha.example/orders?payment=cancelled&order=...",
  "webhook_url": "https://<supabase-project>.supabase.co/functions/v1/payment-webhook",
  "metadata": {
    "order_id": "order-uuid",
    "payment_id": "payment-uuid",
    "order_number": "10042",
    "source": "SHESHA"
  }
}
```

Amounts are sent in minor units. For ZAR, `12500` means R125.00.

Expected success response:

```json
{
  "id": "gateway-session-id",
  "checkout_url": "https://pay.example.com/checkout/..."
}
```

The adapter also accepts `session_id` or `reference` for the session identifier, and `redirect_url` or `redirectUrl` for the checkout URL.

## Webhook

The gateway must send payment events to the supplied `webhook_url`.

Request:

`POST /functions/v1/payment-webhook`

Headers:

- `Content-Type: application/json`
- `X-Gateway-Signature: sha256=<hex HMAC SHA-256 of the exact raw request body>`
- optional `X-Gateway-Event-Id: <unique event id>`

The signature uses `PAYMENT_GATEWAY_WEBHOOK_SECRET`.

Example body:

```json
{
  "event_id": "evt_123",
  "event_type": "payment.succeeded",
  "data": {
    "id": "gateway-payment-id",
    "merchant_reference": "payment-uuid",
    "status": "paid",
    "amount_minor": 12500,
    "currency": "ZAR"
  }
}
```

Accepted successful status aliases include `paid`, `succeeded`, `successful`, `complete`, and `completed`.

Other mapped statuses:

- `failed`, `declined`, `error` -> failed
- `cancelled`, `canceled`, `voided` -> cancelled
- `refunded` -> refunded
- `partially_refunded`, `partial_refund` -> partially_refunded
- `processing`, `authorizing`, `authorised`, `authorized` -> processing

SHESHA verifies currency and, when supplied, `amount_minor` before accepting the event.

## Server-authoritative state

The browser never marks an order paid. A successful gateway webhook updates the payment record and moves the order from `pending_payment` to `paid`.

Webhook events are stored in `payment_events` with a unique `event_id`, making processing idempotent and auditable.

## SHESHA payment flow

1. Customer selects delivery or pickup.
2. SHESHA calculates the server-side order total and delivery fee.
3. SHESHA creates an order in `pending_payment`.
4. `create-payment-session` creates or reuses a payment attempt.
5. Customer is redirected to the gateway checkout.
6. Gateway sends a signed webhook.
7. SHESHA verifies the webhook, amount and currency.
8. Order becomes `paid`.
9. Merchant fulfilment starts.

A browser success redirect alone is not considered proof of payment.
