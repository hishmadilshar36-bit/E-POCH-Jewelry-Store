# Jewellery Store

Online jewellery shop with AI try-on. React (Vite) frontend, Node/Express + Prisma + PostgreSQL backend.

## Run it

Backend (terminal 1):

```
cd backend
npm install
npx prisma migrate dev --name full-site
npm run seed
npm run dev          # API on :4000
```

Frontend (terminal 2):

```
cd frontend
npm install
npm run dev          # http://localhost:5173
```

Admin: http://localhost:5173/admin/login — admin@shop.lk / admin123 (change this password).

## First steps in admin

1. Settings: shop name, phone, WhatsApp, address, bank details, delivery fee.
2. Categories: rename or add images if you like.
3. Products: add pieces with photos, price, stock and jewellery type.
4. AI models: upload a few front-facing model photos for try-on.
5. Offers: optional discounts on a product, a category or the whole shop.

## Switched off until connected

- AI try-on uses a stand-in that returns the input photo. Set AI_PROVIDER=http plus AI_ENDPOINT and AI_API_KEY in backend/.env, and adapt backend/src/services/ai/provider.ts to the image API you choose.
- SMS / WhatsApp messages are logged in the backend terminal. Plug a provider into send() in backend/src/services/notify.ts.
- Online card payment is off in Settings until a gateway (for example PayHere) is connected.

Text in [BRACKETS] on the About, Contact and Delivery pages is placeholder copy for the shop to replace.
