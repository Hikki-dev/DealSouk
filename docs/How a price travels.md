# How a price travels

This page follows one price, from a shelf in a Dubai supermarket to everyone's phone.

<p align="center"><img src="images/price-journey.svg" alt="Diagram of the five steps below" width="100%"></p>

## 1. A shopper shares it

Sara is in a supermarket. The milk costs AED 9.50. She opens DealSouk, taps **Share a price**, picks the store and the product, types 9.50 and takes a photo of the shelf.

If her phone has no signal, the price waits in a queue on the phone. It is sent when the signal comes back.

## 2. The photo is cleaned

The app does not send the photo to the API. It asks the API for a signed link that works once, for this user, for one file of the right type and size. Then it uploads the photo to Firebase Storage.

A Cloud Function then removes the location and camera details hidden inside the photo. A scanner checks the photo for viruses. Only after that can anyone see it.

## 3. A moderator checks it

The price appears in the moderator console as **Pending**. The moderator sees the photos next to a short checklist: does the receipt match the store, does the price match the pack size, is there a promotion tag, is the date recent. They also see how reliable Sara has been in the past.

They approve it, change it or reject it. Every choice is written to the audit log.

## 4. It goes live

Once approved, the price shows up for every shopper who searches for milk. It is called **fresh** for 72 hours. After that it is marked as old, so nobody trusts a price that may have changed.

If three different people flag a price as wrong, it hides itself until a moderator looks at it.

## 5. Sara is rewarded

The API adds tokens to Sara's balance. The new balance is written as a transaction that includes the hash of the one before it, so the history can be checked later. A progress bar shows how close she is to the next voucher. Daily challenges, streaks and badges add more.

When she has enough tokens she asks for a voucher. A moderator approves it and the code is sent from the voucher stock.

## Where this is in the code

| Step | Code |
|---|---|
| Share a price | `lib/features/submissions/` |
| Upload | `backend/src/routes` (uploads), `firebase/`, `services/malware-scanner/` |
| Moderate | `lib/features/admin/`, `backend/src/routes` (admin) |
| Fresh prices | `backend/src/routes` (products, stores) |
| Tokens | `backend/src/services` (token engine), `lib/features/tokens/` |
