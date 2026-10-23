# Voucher Operations

Date: 2026-06-12

## Current Flow

1. User earns tokens through approved submissions and rewards.
2. When the user balance crosses the configured voucher threshold, the backend creates a `VoucherRequest`.
3. The voucher request enters the admin queue with `pending` status.
4. Admin reviews the user and enters a real voucher code from approved inventory.
5. On approval, the backend deducts the configured token cost and marks the voucher as delivered.
6. If rejected, no tokens are deducted and the admin note records why.

## API Endpoints

Admin:

- `GET /admin/vouchers?status=pending`
- `GET /admin/vouchers?status=all`
- `POST /admin/vouchers/:id/approve`
- `POST /admin/vouchers/:id/reject`

User:

- `GET /profile/me/vouchers`

## Rules

- Do not auto-generate fake voucher codes.
- Do not show tokens as cash.
- Do not approve vouchers without confirmed supermarket voucher inventory.
- Do not expose voucher codes in admin list responses unless the voucher is already approved.
- Do not send voucher codes in push notification payloads.

## Remaining Work Before Public Launch

- Add admin UI controls for the voucher approval queue.
- Add user UI for approved voucher codes.
- Add voucher inventory import or manual inventory management.
- Add audit export for issued/rejected vouchers.
- Add fraud review checks before high-volume voucher issuance.
