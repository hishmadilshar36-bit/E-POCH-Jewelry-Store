# E-POCH Jewelry Store - full site setup.
# Writes every backend and frontend file into the right folder. Your .env and uploaded images are not touched.
# Save this file in C:\E-POCH-Jewelry-Store-main (the folder that holds backend and frontend), then run:
#   powershell -ExecutionPolicy Bypass -File .\setup-store.ps1

$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)
if (-not (Test-Path (Join-Path $here 'backend')) -and -not (Test-Path (Join-Path $here 'frontend'))) { Write-Host 'Put this script in the folder that contains backend and frontend, then run it again.'; exit 1 }

function Write-ProjectFile($rel, $content) {
  $path = Join-Path $here $rel
  $dir = Split-Path $path -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
  [System.IO.File]::WriteAllText($path, (($content -replace "`r`n", "`n") + "`n"), $utf8)
}

Write-ProjectFile 'README.md' @'
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
'@

Write-ProjectFile 'backend\.env.example' @'
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/jewellery"
JWT_SECRET="change-me"
PORT=4000
UPLOAD_DIR="uploads"
PUBLIC_URL="http://localhost:4000"
AI_PROVIDER="mock"        # mock | http
AI_API_KEY=""
AI_ENDPOINT=""
DELIVERY_FEE=450
'@

Write-ProjectFile 'backend\package.json' @'
{
  "name": "jewellery-backend",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "seed": "tsx prisma/seed.ts"
  },
  "dependencies": {
    "@prisma/client": "^5.20.0",
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.21.0",
    "jsonwebtoken": "^9.0.2",
    "multer": "^1.4.5-lts.1",
    "zod": "^3.23.8"
  },
  "devDependencies": {
    "@types/bcryptjs": "^2.4.6",
    "@types/cors": "^2.8.17",
    "@types/express": "^4.17.21",
    "@types/jsonwebtoken": "^9.0.7",
    "@types/multer": "^1.4.12",
    "@types/node": "^22.7.0",
    "prisma": "^5.20.0",
    "tsx": "^4.19.0",
    "typescript": "^5.6.0"
  }
}
'@

Write-ProjectFile 'backend\prisma\schema.prisma' @'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

enum Role {
  CUSTOMER
  ADMIN
}

enum JewelleryType {
  EARRINGS
  NECKLACE
  CHAIN
  LONG_CHAIN
  BANGLE
  BRACELET
  RING
  ANKLET
  HAIR
  OTHER
}

enum OrderStatus {
  PENDING
  CONFIRMED
  PROCESSING
  READY
  DISPATCHED
  DELIVERED
  CANCELLED
}

enum PaymentMethod {
  BANK_TRANSFER
  COD
  ONLINE
}

enum PaymentStatus {
  UNPAID
  PAID
  REFUNDED
}

enum DeliveryMethod {
  DELIVERY
  PICKUP
}

enum TryOnSource {
  AI_MODEL
  UPLOAD
}

enum TryOnStatus {
  PENDING
  PROCESSING
  DONE
  FAILED
}

model User {
  id        String         @id @default(cuid())
  name      String
  email     String         @unique
  phone     String?
  password  String
  role      Role           @default(CUSTOMER)
  createdAt DateTime       @default(now())
  cart      Cart?
  orders    Order[]
  wishlist  WishlistItem[]
  tryOns    TryOn[]
}

model Category {
  id       String    @id @default(cuid())
  name     String
  slug     String    @unique
  imageUrl String?
  sort     Int       @default(0)
  products Product[]
  offers   Offer[]
}

model Product {
  id            String         @id @default(cuid())
  code          String         @unique
  name          String
  slug          String         @unique
  description   String?
  price         Int
  stock         Int            @default(0)
  isActive      Boolean        @default(true)
  isNewArrival  Boolean        @default(false)
  style         String?
  colour        String?
  jewelleryType JewelleryType
  tryOnEnabled  Boolean        @default(true)
  tryOnAssetUrl String? // transparent PNG used by AI
  categoryId    String
  category      Category       @relation(fields: [categoryId], references: [id])
  images        ProductImage[]
  createdAt     DateTime       @default(now())
  orderItems    OrderItem[]
  cartItems     CartItem[]
  wishlist      WishlistItem[]
  tryOnItems    TryOnItem[]
  offers        Offer[]
}

model ProductImage {
  id        String  @id @default(cuid())
  url       String
  sort      Int     @default(0)
  productId String
  product   Product @relation(fields: [productId], references: [id], onDelete: Cascade)
}

model Cart {
  id        String     @id @default(cuid())
  userId    String?    @unique
  user      User?      @relation(fields: [userId], references: [id])
  guestKey  String?    @unique
  items     CartItem[]
  updatedAt DateTime   @updatedAt
}

model CartItem {
  id        String  @id @default(cuid())
  cartId    String
  cart      Cart    @relation(fields: [cartId], references: [id], onDelete: Cascade)
  productId String
  product   Product @relation(fields: [productId], references: [id])
  qty       Int     @default(1)

  @@unique([cartId, productId])
}

model WishlistItem {
  id        String  @id @default(cuid())
  userId    String
  user      User    @relation(fields: [userId], references: [id])
  productId String
  product   Product @relation(fields: [productId], references: [id])

  @@unique([userId, productId])
}

model Order {
  id             String           @id @default(cuid())
  orderNo        String           @unique
  userId         String?
  user           User?            @relation(fields: [userId], references: [id])
  fullName       String
  mobile         String
  whatsapp       String?
  email          String?
  address        String?
  city           String?
  postalCode     String?
  note           String?
  deliveryMethod DeliveryMethod
  paymentMethod  PaymentMethod
  paymentStatus  PaymentStatus    @default(UNPAID)
  subtotal       Int
  deliveryFee    Int
  total          Int
  status         OrderStatus      @default(PENDING)
  items          OrderItem[]
  history        OrderStatusLog[]
  createdAt      DateTime         @default(now())
}

model OrderItem {
  id        String  @id @default(cuid())
  orderId   String
  order     Order   @relation(fields: [orderId], references: [id], onDelete: Cascade)
  productId String
  product   Product @relation(fields: [productId], references: [id])
  name      String
  price     Int
  qty       Int
}

model OrderStatusLog {
  id        String      @id @default(cuid())
  orderId   String
  order     Order       @relation(fields: [orderId], references: [id], onDelete: Cascade)
  status    OrderStatus
  createdAt DateTime    @default(now())
}

model AiModel {
  id        String   @id @default(cuid())
  name      String
  imageUrl  String
  isActive  Boolean  @default(true)
  createdAt DateTime @default(now())
  tryOns    TryOn[]
}

model TryOn {
  id        String      @id @default(cuid())
  userId    String?
  user      User?       @relation(fields: [userId], references: [id])
  source    TryOnSource
  aiModelId String?
  aiModel   AiModel?    @relation(fields: [aiModelId], references: [id])
  inputUrl  String
  resultUrl String?
  status    TryOnStatus @default(PENDING)
  error     String?
  items     TryOnItem[]
  createdAt DateTime    @default(now())
}

model TryOnItem {
  id        String  @id @default(cuid())
  tryOnId   String
  tryOn     TryOn   @relation(fields: [tryOnId], references: [id], onDelete: Cascade)
  productId String
  product   Product @relation(fields: [productId], references: [id])
}

// An offer applies to one product, one category, or (both empty) the whole shop.
model Offer {
  id         String    @id @default(cuid())
  title      String
  percentOff Int
  startsAt   DateTime
  endsAt     DateTime
  isActive   Boolean   @default(true)
  productId  String?
  product    Product?  @relation(fields: [productId], references: [id], onDelete: Cascade)
  categoryId String?
  category   Category? @relation(fields: [categoryId], references: [id], onDelete: Cascade)
  createdAt  DateTime  @default(now())
}

// Single row (id = 1) holding the shop's editable details.
model ShopSettings {
  id               Int     @id @default(1)
  shopName         String  @default("[Shop name]")
  tagline          String  @default("Jewellery for every day and every occasion.")
  phone            String  @default("")
  whatsapp         String  @default("")
  email            String  @default("")
  address          String  @default("")
  deliveryFee      Int     @default(450)
  freeDeliveryOver Int?
  bankDetails      String  @default("")
  codEnabled       Boolean @default(true)
  bankEnabled      Boolean @default(true)
  onlineEnabled    Boolean @default(false)
  pickupEnabled    Boolean @default(true)
}
'@

Write-ProjectFile 'backend\prisma\seed.ts' @'
import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";
const db = new PrismaClient();

async function main() {
  await db.user.upsert({
    where: { email: "admin@shop.lk" },
    update: {},
    create: { name: "Admin", email: "admin@shop.lk", password: await bcrypt.hash("admin123", 10), role: "ADMIN" },
  });

  const cats = ["Earrings", "Bangles", "Chains", "Long Chains", "Necklaces", "Rings", "Bracelets", "Anklets", "Bridal Jewellery", "Hair Accessories", "Fancy Jewellery"];
  for (const [i, name] of cats.entries()) {
    const slug = name.toLowerCase().replace(/\s+/g, "-");
    await db.category.upsert({ where: { slug }, update: {}, create: { name, slug, sort: i } });
  }

  await db.shopSettings.upsert({ where: { id: 1 }, update: {}, create: { id: 1 } });

  console.log(`Seeded: admin@shop.lk / admin123, ${cats.length} categories, shop settings`);
}

main()
  .catch((e) => { console.error("Seed failed:", e); process.exit(1); })
  .finally(() => db.$disconnect());
'@

Write-ProjectFile 'backend\src\app.ts' @'
import express from "express";
import cors from "cors";
import { env } from "./config/env";
import { errorHandler } from "./middleware/error";
import auth from "./modules/auth/auth.routes";
import categories from "./modules/categories/categories.routes";
import products from "./modules/products/products.routes";
import cart from "./modules/cart/cart.routes";
import orders from "./modules/orders/orders.routes";
import tryon from "./modules/tryon/tryon.routes";
import wishlist from "./modules/wishlist/wishlist.routes";
import settings from "./modules/settings/settings.routes";
import admin from "./modules/admin/admin.routes";

export const app = express();
app.use(cors());
app.use(express.json({ limit: "1mb" }));
app.use("/uploads", express.static(env.uploadDir, { maxAge: "7d" }));

app.use("/api/auth", auth);
app.use("/api/categories", categories);
app.use("/api/products", products);
app.use("/api/cart", cart);
app.use("/api/orders", orders);
app.use("/api/tryon", tryon);
app.use("/api/wishlist", wishlist);
app.use("/api/settings", settings);
app.use("/api/admin", admin);

app.get("/api/health", (_req, res) => res.json({ ok: true }));
app.use("/api", (_req, res) => res.status(404).json({ error: "Not found" }));
app.use(errorHandler);
'@

Write-ProjectFile 'backend\src\config\db.ts' @'
import { PrismaClient } from "@prisma/client";
export const db = new PrismaClient();
'@

Write-ProjectFile 'backend\src\config\env.ts' @'
import "dotenv/config";
export const env = {
  port: Number(process.env.PORT ?? 4000),
  jwtSecret: process.env.JWT_SECRET ?? "dev",
  uploadDir: process.env.UPLOAD_DIR ?? "uploads",
  publicUrl: process.env.PUBLIC_URL ?? "http://localhost:4000",
  aiProvider: process.env.AI_PROVIDER ?? "mock",
  aiApiKey: process.env.AI_API_KEY ?? "",
  aiEndpoint: process.env.AI_ENDPOINT ?? "",
  deliveryFee: Number(process.env.DELIVERY_FEE ?? 450),
};
'@

Write-ProjectFile 'backend\src\index.ts' @'
import { app } from "./app";
import { env } from "./config/env";
import { startTryOnWorker } from "./services/ai/tryon.worker";

app.listen(env.port, "0.0.0.0", () => console.log(`API on :${env.port}`));
startTryOnWorker();
'@

Write-ProjectFile 'backend\src\middleware\auth.ts' @'
import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { env } from "../config/env";

export type AuthUser = { id: string; role: "CUSTOMER" | "ADMIN" };
declare global { namespace Express { interface Request { user?: AuthUser } } }

export const signToken = (u: AuthUser) => jwt.sign(u, env.jwtSecret, { expiresIn: "7d" });

export function optionalAuth(req: Request, _res: Response, next: NextFunction) {
  const t = req.headers.authorization?.replace("Bearer ", "");
  if (t) try { req.user = jwt.verify(t, env.jwtSecret) as AuthUser; } catch {}
  next();
}
export function requireAuth(req: Request, res: Response, next: NextFunction) {
  optionalAuth(req, res, () => (req.user ? next() : res.status(401).json({ error: "Sign in required" })));
}
export function requireAdmin(req: Request, res: Response, next: NextFunction) {
  requireAuth(req, res, () => (req.user?.role === "ADMIN" ? next() : res.status(403).json({ error: "Admin only" })));
}
'@

Write-ProjectFile 'backend\src\middleware\error.ts' @'
import { Request, Response, NextFunction } from "express";
import { ZodError } from "zod";
import { MulterError } from "multer";
import { Prisma } from "@prisma/client";

export class HttpError extends Error { constructor(public status: number, msg: string) { super(msg); } }
export const ah = (fn: (req: Request, res: Response, next: NextFunction) => Promise<unknown>) =>
  (req: Request, res: Response, next: NextFunction) => fn(req, res, next).catch(next);

export function errorHandler(err: unknown, _req: Request, res: Response, _next: NextFunction) {
  if (err instanceof ZodError) {
    const first = err.issues[0];
    const field = first?.path.join(".");
    const message = first?.message && first.message !== "Required" ? first.message : `Check the ${field || "form"} field`;
    return res.status(400).json({ error: message, field, details: err.flatten() });
  }
  if (err instanceof HttpError) return res.status(err.status).json({ error: err.message });
  if (err instanceof MulterError) {
    return res.status(400).json({ error: err.code === "LIMIT_FILE_SIZE" ? "That image is over 8 MB. Choose a smaller one." : "That upload didn't work. Try another image." });
  }
  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    if (err.code === "P2025") return res.status(404).json({ error: "That item no longer exists." });
    if (err.code === "P2002") return res.status(409).json({ error: "That value is already in use." });
  }
  console.error(err);
  res.status(500).json({ error: "Something went wrong on our side. Try again." });
}
'@

Write-ProjectFile 'backend\src\middleware\upload.ts' @'
import multer from "multer";
import path from "path";
import fs from "fs";
import { env } from "../config/env";

fs.mkdirSync(env.uploadDir, { recursive: true });
export const upload = multer({
  storage: multer.diskStorage({
    destination: env.uploadDir,
    filename: (_r, f, cb) => cb(null, `${Date.now()}-${Math.round(Math.random() * 1e9)}${path.extname(f.originalname)}`),
  }),
  limits: { fileSize: 8 * 1024 * 1024 },
  fileFilter: (_r, f, cb) => cb(null, /image\/(jpeg|png|webp)/.test(f.mimetype)),
});
export const fileUrl = (filename: string) => `${env.publicUrl}/uploads/${filename}`;
'@

Write-ProjectFile 'backend\src\modules\admin\admin.routes.ts' @'
import { Router } from "express";
import { z } from "zod";
import { Prisma } from "@prisma/client";
import { db } from "../../config/db";
import { ah, HttpError } from "../../middleware/error";
import { requireAdmin } from "../../middleware/auth";
import { upload, fileUrl } from "../../middleware/upload";
import { changeStatus, nextStatuses } from "../orders/orders.service";

const r = Router();
r.use(requireAdmin);

const orderStatuses = ["PENDING", "CONFIRMED", "PROCESSING", "READY", "DISPATCHED", "DELIVERED", "CANCELLED"] as const;
const startOfDay = (d = new Date()) => new Date(d.getFullYear(), d.getMonth(), d.getDate());
const dayKey = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;

// ---------- Dashboard ----------
r.get("/dashboard", ah(async (_req, res) => {
  const today = startOfDay();
  const weekStart = new Date(today);
  weekStart.setDate(weekStart.getDate() - 6);

  const [todayOrders, pending, processing, completed, sales, weekOrders, recentOrders, lowStock] = await Promise.all([
    db.order.count({ where: { createdAt: { gte: today } } }),
    db.order.count({ where: { status: "PENDING" } }),
    db.order.count({ where: { status: { in: ["CONFIRMED", "PROCESSING", "READY", "DISPATCHED"] } } }),
    db.order.count({ where: { status: "DELIVERED", createdAt: { gte: today } } }),
    db.order.aggregate({ _sum: { total: true }, where: { createdAt: { gte: today }, status: { not: "CANCELLED" } } }),
    db.order.findMany({ where: { createdAt: { gte: weekStart }, status: { not: "CANCELLED" } }, select: { createdAt: true, total: true } }),
    db.order.findMany({ orderBy: { createdAt: "desc" }, take: 6, select: { id: true, orderNo: true, fullName: true, total: true, status: true, createdAt: true } }),
    db.product.findMany({ where: { isActive: true, stock: { lte: 3 } }, orderBy: { stock: "asc" }, take: 6, select: { id: true, name: true, code: true, stock: true } }),
  ]);

  const last7Days = Array.from({ length: 7 }, (_, i) => {
    const d = new Date(weekStart);
    d.setDate(d.getDate() + i);
    return { date: dayKey(d), sales: 0, orders: 0 };
  });
  for (const o of weekOrders) {
    const day = last7Days.find((x) => x.date === dayKey(o.createdAt));
    if (day) { day.sales += o.total; day.orders += 1; }
  }

  res.json({ todayOrders, pending, processing, completed, todaySales: sales._sum.total ?? 0, last7Days, recentOrders, lowStock });
}));

// ---------- Products ----------
r.get("/products", ah(async (req, res) => {
  const q = z.object({
    q: z.string().optional(), categoryId: z.string().optional(),
    show: z.enum(["all", "active", "hidden", "low"]).default("all"),
    page: z.coerce.number().int().min(1).default(1),
  }).parse(req.query);
  const where: Prisma.ProductWhereInput = {
    ...(q.q && { OR: [{ name: { contains: q.q, mode: "insensitive" } }, { code: { contains: q.q, mode: "insensitive" } }] }),
    ...(q.categoryId && { categoryId: q.categoryId }),
    ...(q.show === "active" && { isActive: true }),
    ...(q.show === "hidden" && { isActive: false }),
    ...(q.show === "low" && { isActive: true, stock: { lte: 3 } }),
  };
  const [items, total] = await Promise.all([
    db.product.findMany({
      where, orderBy: { createdAt: "desc" }, skip: (q.page - 1) * 20, take: 20,
      include: { images: { orderBy: { sort: "asc" }, take: 1 }, category: { select: { name: true } } },
    }),
    db.product.count({ where }),
  ]);
  res.json({ items, total, page: q.page, pages: Math.max(1, Math.ceil(total / 20)) });
}));

r.get("/products/:id", ah(async (req, res) => {
  const p = await db.product.findUnique({ where: { id: req.params.id }, include: { images: { orderBy: { sort: "asc" } }, category: true } });
  if (!p) throw new HttpError(404, "Product not found");
  res.json(p);
}));

// ---------- Orders ----------
r.get("/orders", ah(async (req, res) => {
  const q = z.object({
    status: z.enum(orderStatuses).optional(), q: z.string().optional(),
    page: z.coerce.number().int().min(1).default(1),
  }).parse(req.query);
  const where: Prisma.OrderWhereInput = {
    ...(q.status && { status: q.status }),
    ...(q.q && { OR: [{ orderNo: { contains: q.q, mode: "insensitive" } }, { fullName: { contains: q.q, mode: "insensitive" } }, { mobile: { contains: q.q } }] }),
  };
  const [items, total, counts] = await Promise.all([
    db.order.findMany({ where, orderBy: { createdAt: "desc" }, skip: (q.page - 1) * 20, take: 20, include: { _count: { select: { items: true } } } }),
    db.order.count({ where }),
    db.order.groupBy({ by: ["status"], _count: { _all: true } }),
  ]);
  const byStatus = Object.fromEntries(counts.map((c) => [c.status, c._count._all]));
  res.json({ items, total, page: q.page, pages: Math.max(1, Math.ceil(total / 20)), byStatus });
}));

r.get("/orders/:id", ah(async (req, res) => {
  const o = await db.order.findUnique({
    where: { id: req.params.id },
    include: {
      items: { include: { product: { select: { slug: true, code: true, images: { orderBy: { sort: "asc" }, take: 1 } } } } },
      history: { orderBy: { createdAt: "asc" } },
      user: { select: { id: true, email: true } },
    },
  });
  if (!o) throw new HttpError(404, "Order not found");
  res.json({ ...o, nextStatuses: nextStatuses[o.status] });
}));

r.patch("/orders/:id/status", ah(async (req, res) => {
  const { status } = z.object({ status: z.enum(orderStatuses) }).parse(req.body);
  res.json(await changeStatus(req.params.id, status));
}));

r.patch("/orders/:id/payment", ah(async (req, res) => {
  const { paymentStatus } = z.object({ paymentStatus: z.enum(["UNPAID", "PAID", "REFUNDED"]) }).parse(req.body);
  res.json(await db.order.update({ where: { id: req.params.id }, data: { paymentStatus } }));
}));

// ---------- Customers ----------
r.get("/customers", ah(async (req, res) => {
  const q = z.object({ q: z.string().optional(), page: z.coerce.number().int().min(1).default(1) }).parse(req.query);
  const where: Prisma.UserWhereInput = {
    role: "CUSTOMER",
    ...(q.q && { OR: [{ name: { contains: q.q, mode: "insensitive" } }, { email: { contains: q.q, mode: "insensitive" } }, { phone: { contains: q.q } }] }),
  };
  const [users, total] = await Promise.all([
    db.user.findMany({
      where, orderBy: { createdAt: "desc" }, skip: (q.page - 1) * 20, take: 20,
      select: { id: true, name: true, email: true, phone: true, createdAt: true, _count: { select: { orders: true } } },
    }),
    db.user.count({ where }),
  ]);
  const spend = await db.order.groupBy({ by: ["userId"], where: { userId: { in: users.map((u) => u.id) }, status: { not: "CANCELLED" } }, _sum: { total: true } });
  const spent = Object.fromEntries(spend.map((s) => [s.userId, s._sum.total ?? 0]));
  res.json({ items: users.map((u) => ({ ...u, totalSpent: spent[u.id] ?? 0 })), total, page: q.page, pages: Math.max(1, Math.ceil(total / 20)) });
}));

r.get("/customers/:id", ah(async (req, res) => {
  const u = await db.user.findFirst({
    where: { id: req.params.id, role: "CUSTOMER" },
    select: {
      id: true, name: true, email: true, phone: true, createdAt: true,
      orders: { orderBy: { createdAt: "desc" }, select: { id: true, orderNo: true, total: true, status: true, createdAt: true } },
    },
  });
  if (!u) throw new HttpError(404, "Customer not found");
  res.json(u);
}));

// ---------- AI models ----------
r.get("/ai-models", ah(async (_req, res) => {
  res.json(await db.aiModel.findMany({ orderBy: { createdAt: "asc" }, include: { _count: { select: { tryOns: true } } } }));
}));

r.post("/ai-models", upload.single("image"), ah(async (req, res) => {
  if (!req.file) throw new HttpError(400, "Choose a JPG, PNG or WebP photo.");
  const { name } = z.object({ name: z.string().trim().min(1).max(40) }).parse(req.body);
  res.status(201).json(await db.aiModel.create({ data: { name, imageUrl: fileUrl(req.file.filename) } }));
}));

r.patch("/ai-models/:id", ah(async (req, res) => {
  const b = z.object({ name: z.string().trim().min(1).max(40).optional(), isActive: z.boolean().optional() }).parse(req.body);
  res.json(await db.aiModel.update({ where: { id: req.params.id }, data: b }));
}));

r.delete("/ai-models/:id", ah(async (req, res) => {
  const used = await db.tryOn.count({ where: { aiModelId: req.params.id } });
  if (used) {
    await db.aiModel.update({ where: { id: req.params.id }, data: { isActive: false } });
    return res.json({ hidden: true });
  }
  await db.aiModel.delete({ where: { id: req.params.id } });
  res.status(204).end();
}));

// ---------- Offers ----------
const offerBody = z.object({
  title: z.string().trim().min(2).max(80),
  percentOff: z.coerce.number().int().min(1).max(90),
  startsAt: z.coerce.date(),
  endsAt: z.coerce.date(),
  isActive: z.boolean().default(true),
  productId: z.string().nullable().optional().transform((v) => v || null),
  categoryId: z.string().nullable().optional().transform((v) => v || null),
}).refine((o) => o.endsAt > o.startsAt, { message: "End date must be after the start date", path: ["endsAt"] })
  .refine((o) => !(o.productId && o.categoryId), { message: "Choose a product or a category, not both", path: ["productId"] });

r.get("/offers", ah(async (_req, res) => {
  res.json(await db.offer.findMany({
    orderBy: [{ isActive: "desc" }, { endsAt: "desc" }],
    include: { product: { select: { id: true, name: true, code: true } }, category: { select: { id: true, name: true } } },
  }));
}));

r.post("/offers", ah(async (req, res) => res.status(201).json(await db.offer.create({ data: offerBody.parse(req.body) }))));

r.put("/offers/:id", ah(async (req, res) => res.json(await db.offer.update({ where: { id: req.params.id }, data: offerBody.parse(req.body) }))));

r.delete("/offers/:id", ah(async (req, res) => {
  await db.offer.delete({ where: { id: req.params.id } });
  res.status(204).end();
}));

// ---------- Reports ----------
r.get("/reports/sales", ah(async (req, res) => {
  const { range } = z.object({ range: z.enum(["daily", "weekly", "monthly"]).default("daily") }).parse(req.query);
  const unit = range === "daily" ? "day" : range === "weekly" ? "week" : "month";
  const limit = range === "daily" ? 30 : 12;
  type SalesRow = { period: Date; orders: bigint; sales: bigint | null };
  const rows = (await db.$queryRawUnsafe(
    `SELECT date_trunc('${unit}', "createdAt") AS period, COUNT(*) AS orders, SUM(total) AS sales
     FROM "Order" WHERE status <> 'CANCELLED' GROUP BY 1 ORDER BY 1 DESC LIMIT ${limit}`
  )) as SalesRow[];
  res.json(rows.reverse().map((row) => ({ period: row.period, orders: Number(row.orders), sales: Number(row.sales ?? 0) })));
}));

r.get("/reports/orders", ah(async (_req, res) => {
  const counts = await db.order.groupBy({ by: ["status"], _count: { _all: true } });
  res.json(orderStatuses.map((status) => ({ status, count: counts.find((c) => c.status === status)?._count._all ?? 0 })));
}));

r.get("/reports/products", ah(async (_req, res) => {
  const [top, outOfStock, newest, tried] = await Promise.all([
    db.orderItem.groupBy({
      by: ["productId", "name"], where: { order: { status: { not: "CANCELLED" } } },
      _sum: { qty: true, price: true }, orderBy: { _sum: { qty: "desc" } }, take: 10,
    }),
    db.product.findMany({ where: { stock: 0, isActive: true }, select: { id: true, name: true, code: true } }),
    db.product.findMany({ orderBy: { createdAt: "desc" }, take: 10, select: { id: true, name: true, code: true, createdAt: true } }),
    db.tryOnItem.groupBy({ by: ["productId"], _count: { _all: true }, orderBy: { _count: { productId: "desc" } }, take: 10 }),
  ]);
  const names = await db.product.findMany({ where: { id: { in: tried.map((t) => t.productId) } }, select: { id: true, name: true, code: true } });
  const mostTried = tried.map((t) => ({ ...names.find((n) => n.id === t.productId), tries: t._count._all }));
  res.json({ top: top.map((t) => ({ productId: t.productId, name: t.name, qty: t._sum.qty ?? 0 })), outOfStock, newest, mostTried });
}));

export default r;
'@

Write-ProjectFile 'backend\src\modules\auth\auth.routes.ts' @'
import { Router } from "express";
import bcrypt from "bcryptjs";
import { z } from "zod";
import { db } from "../../config/db";
import { ah, HttpError } from "../../middleware/error";
import { requireAuth, signToken } from "../../middleware/auth";

const r = Router();
const publicUser = { id: true, name: true, email: true, phone: true, role: true } as const;
const phone = z.string().regex(/^0\d{9}$/, "Use a mobile number like 07XXXXXXXX").optional().or(z.literal("").transform(() => undefined));

r.post("/register", ah(async (req, res) => {
  const b = z.object({ name: z.string().trim().min(2), email: z.string().trim().toLowerCase().email(), phone, password: z.string().min(6) }).parse(req.body);
  if (await db.user.findUnique({ where: { email: b.email } })) throw new HttpError(409, "An account with this email already exists. Sign in instead.");
  const u = await db.user.create({ data: { ...b, password: await bcrypt.hash(b.password, 10) }, select: publicUser });
  res.status(201).json({ token: signToken({ id: u.id, role: u.role }), user: u });
}));

r.post("/login", ah(async (req, res) => {
  const b = z.object({ email: z.string().trim().toLowerCase().email(), password: z.string() }).parse(req.body);
  const u = await db.user.findUnique({ where: { email: b.email } });
  if (!u || !(await bcrypt.compare(b.password, u.password))) throw new HttpError(401, "Wrong email or password.");
  res.json({ token: signToken({ id: u.id, role: u.role }), user: { id: u.id, name: u.name, email: u.email, phone: u.phone, role: u.role } });
}));

r.get("/me", requireAuth, ah(async (req, res) => {
  const u = await db.user.findUnique({ where: { id: req.user!.id }, select: publicUser });
  if (!u) throw new HttpError(401, "Sign in required");
  res.json(u);
}));

r.patch("/me", requireAuth, ah(async (req, res) => {
  const b = z.object({ name: z.string().trim().min(2).optional(), phone }).parse(req.body);
  res.json(await db.user.update({ where: { id: req.user!.id }, data: { name: b.name, phone: b.phone ?? null }, select: publicUser }));
}));

r.post("/password", requireAuth, ah(async (req, res) => {
  const b = z.object({ current: z.string(), next: z.string().min(6, "New password needs at least 6 characters") }).parse(req.body);
  const u = await db.user.findUnique({ where: { id: req.user!.id } });
  if (!u || !(await bcrypt.compare(b.current, u.password))) throw new HttpError(400, "Current password is wrong.");
  await db.user.update({ where: { id: u.id }, data: { password: await bcrypt.hash(b.next, 10) } });
  res.status(204).end();
}));

export default r;
'@

Write-ProjectFile 'backend\src\modules\cart\cart.routes.ts' @'
import { Router } from "express";
import { z } from "zod";
import { db } from "../../config/db";
import { ah, HttpError } from "../../middleware/error";
import { optionalAuth, requireAuth } from "../../middleware/auth";
import { resolveCart, cartView, mergeGuestCart } from "./cart.service";

const r = Router();
r.use(optionalAuth);

r.get("/", ah(async (req, res) => res.json(await cartView((await resolveCart(req)).id))));

// Single item or a "Create your look" set: { items: [{ productId, qty }] }
r.post("/items", ah(async (req, res) => {
  const b = z.object({ items: z.array(z.object({ productId: z.string(), qty: z.number().int().min(1).max(20).default(1) })).min(1).max(10) }).parse(req.body);
  const cart = await resolveCart(req);
  for (const it of b.items) {
    const p = await db.product.findUnique({ where: { id: it.productId } });
    if (!p || !p.isActive) throw new HttpError(404, "This product isn't available.");
    const existing = await db.cartItem.findUnique({ where: { cartId_productId: { cartId: cart.id, productId: p.id } } });
    const want = (existing?.qty ?? 0) + it.qty;
    if (p.stock < want) throw new HttpError(409, p.stock ? `Only ${p.stock} of ${p.name} left.` : `${p.name} is sold out.`);
    await db.cartItem.upsert({
      where: { cartId_productId: { cartId: cart.id, productId: p.id } },
      update: { qty: want },
      create: { cartId: cart.id, productId: p.id, qty: it.qty },
    });
  }
  res.json(await cartView(cart.id));
}));

r.patch("/items/:productId", ah(async (req, res) => {
  const { qty } = z.object({ qty: z.number().int().min(1).max(20) }).parse(req.body);
  const cart = await resolveCart(req);
  const p = await db.product.findUnique({ where: { id: req.params.productId } });
  if (!p) throw new HttpError(404, "This product isn't available.");
  if (p.stock < qty) throw new HttpError(409, p.stock ? `Only ${p.stock} of ${p.name} left.` : `${p.name} is sold out.`);
  await db.cartItem.update({ where: { cartId_productId: { cartId: cart.id, productId: p.id } }, data: { qty } });
  res.json(await cartView(cart.id));
}));

r.delete("/items/:productId", ah(async (req, res) => {
  const cart = await resolveCart(req);
  await db.cartItem.deleteMany({ where: { cartId: cart.id, productId: req.params.productId } });
  res.json(await cartView(cart.id));
}));

r.post("/merge", requireAuth, ah(async (req, res) => {
  const { guestKey } = z.object({ guestKey: z.string() }).parse(req.body);
  await mergeGuestCart(req.user!.id, guestKey);
  res.json(await cartView((await resolveCart(req)).id));
}));

export default r;
'@

Write-ProjectFile 'backend\src\modules\cart\cart.service.ts' @'
import { Request } from "express";
import { db } from "../../config/db";
import { HttpError } from "../../middleware/error";
import { getActiveOffers, priceFor } from "../../services/pricing";
import { deliveryFeeFor, getSettings } from "../../services/settings";

// Logged-in → cart by userId. Guest → cart by X-Cart-Key header (uuid kept in localStorage).
export async function resolveCart(req: Request) {
  if (req.user) {
    return db.cart.upsert({ where: { userId: req.user.id }, update: {}, create: { userId: req.user.id } });
  }
  const guestKey = req.header("x-cart-key");
  if (!guestKey) throw new HttpError(400, "Missing cart key");
  return db.cart.upsert({ where: { guestKey }, update: {}, create: { guestKey } });
}

export async function cartView(cartId: string) {
  const [rows, offers, settings] = await Promise.all([
    db.cartItem.findMany({
      where: { cartId },
      orderBy: { id: "asc" },
      include: { product: { include: { images: { take: 1, orderBy: { sort: "asc" } } } } },
    }),
    getActiveOffers(),
    getSettings(),
  ]);
  const items = rows
    .filter((i) => i.product.isActive)
    .map((i) => {
      const pricing = priceFor(i.product, offers);
      const unitPrice = pricing.salePrice ?? i.product.price;
      return { ...i, product: { ...i.product, ...pricing }, unitPrice, lineTotal: unitPrice * i.qty, inStock: i.product.stock >= i.qty };
    });
  const subtotal = items.reduce((s, i) => s + i.lineTotal, 0);
  const deliveryFee = items.length ? deliveryFeeFor(settings, subtotal) : 0;
  return { id: cartId, items, subtotal, deliveryFee, total: subtotal + deliveryFee, freeDeliveryOver: settings.freeDeliveryOver };
}

// Call after login: move guest cart items into the user cart.
export async function mergeGuestCart(userId: string, guestKey: string) {
  const guest = await db.cart.findUnique({ where: { guestKey }, include: { items: true } });
  if (!guest) return;
  const user = await db.cart.upsert({ where: { userId }, update: {}, create: { userId } });
  for (const it of guest.items) {
    await db.cartItem.upsert({
      where: { cartId_productId: { cartId: user.id, productId: it.productId } },
      update: { qty: { increment: it.qty } },
      create: { cartId: user.id, productId: it.productId, qty: it.qty },
    });
  }
  await db.cart.delete({ where: { id: guest.id } });
}
'@

Write-ProjectFile 'backend\src\modules\categories\categories.routes.ts' @'
import { Router } from "express";
import { z } from "zod";
import { db } from "../../config/db";
import { ah, HttpError } from "../../middleware/error";
import { requireAdmin } from "../../middleware/auth";
import { upload, fileUrl } from "../../middleware/upload";

const r = Router();
const slugify = (s: string) => s.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");

r.get("/", ah(async (_req, res) => {
  res.json(await db.category.findMany({
    orderBy: [{ sort: "asc" }, { name: "asc" }],
    include: { _count: { select: { products: { where: { isActive: true } } } } },
  }));
}));

// multipart/form-data: name, sort, image?
const body = z.object({ name: z.string().trim().min(1).max(60), sort: z.coerce.number().int().optional() });

r.post("/", requireAdmin, upload.single("image"), ah(async (req, res) => {
  const b = body.parse(req.body);
  const slug = slugify(b.name);
  if (await db.category.findUnique({ where: { slug } })) throw new HttpError(409, "A category with this name already exists.");
  res.status(201).json(await db.category.create({ data: { ...b, slug, imageUrl: req.file ? fileUrl(req.file.filename) : undefined } }));
}));

r.put("/:id", requireAdmin, upload.single("image"), ah(async (req, res) => {
  const b = body.partial().parse(req.body);
  const data: { name?: string; slug?: string; sort?: number; imageUrl?: string } = { ...b };
  if (b.name) {
    data.slug = slugify(b.name);
    const clash = await db.category.findFirst({ where: { slug: data.slug, NOT: { id: req.params.id } } });
    if (clash) throw new HttpError(409, "A category with this name already exists.");
  }
  if (req.file) data.imageUrl = fileUrl(req.file.filename);
  res.json(await db.category.update({ where: { id: req.params.id }, data }));
}));

r.delete("/:id", requireAdmin, ah(async (req, res) => {
  const count = await db.product.count({ where: { categoryId: req.params.id } });
  if (count) throw new HttpError(409, `This category has ${count} product${count === 1 ? "" : "s"}. Move them to another category first.`);
  await db.category.delete({ where: { id: req.params.id } });
  res.status(204).end();
}));

export default r;
'@

Write-ProjectFile 'backend\src\modules\orders\orders.routes.ts' @'
import { Router } from "express";
import { z } from "zod";
import { db } from "../../config/db";
import { ah, HttpError } from "../../middleware/error";
import { optionalAuth, requireAuth } from "../../middleware/auth";
import { resolveCart } from "../cart/cart.service";
import { placeOrder } from "./orders.service";
import { notifyOrderPlaced } from "../../services/notify";

const r = Router();

const optionalText = z.string().trim().max(300).optional().transform((v) => v || undefined);
const checkout = z.object({
  fullName: z.string().trim().min(2, "Enter your full name"),
  mobile: z.string().trim().regex(/^0\d{9}$/, "Enter a mobile number like 07XXXXXXXX"),
  whatsapp: optionalText, email: z.string().trim().email("Enter a valid email").optional().or(z.literal("").transform(() => undefined)),
  address: optionalText, city: optionalText, postalCode: optionalText, note: optionalText,
  deliveryMethod: z.enum(["DELIVERY", "PICKUP"]), paymentMethod: z.enum(["BANK_TRANSFER", "COD", "ONLINE"]),
});

const orderDetail = {
  items: { include: { product: { select: { slug: true, images: { orderBy: { sort: "asc" as const }, take: 1 } } } } },
  history: { orderBy: { createdAt: "asc" as const } },
};

r.post("/", optionalAuth, ah(async (req, res) => {
  const input = checkout.parse(req.body);
  const cart = await resolveCart(req);
  const order = await placeOrder(cart.id, req.user?.id, input);
  notifyOrderPlaced(order).catch(console.error);
  res.status(201).json(await db.order.findUnique({ where: { id: order.id }, include: orderDetail }));
}));

r.get("/mine", requireAuth, ah(async (req, res) => {
  res.json(await db.order.findMany({ where: { userId: req.user!.id }, orderBy: { createdAt: "desc" }, include: orderDetail }));
}));

// Public tracking: order number + mobile number
r.get("/track", ah(async (req, res) => {
  const { orderNo, mobile } = z.object({ orderNo: z.string().trim(), mobile: z.string().trim() }).parse(req.query);
  const normalized = orderNo.toUpperCase().startsWith("ORD-") ? orderNo.toUpperCase() : `ORD-${orderNo.replace(/\D/g, "").padStart(6, "0")}`;
  const o = await db.order.findFirst({ where: { orderNo: normalized.replace(/^#/, ""), mobile }, include: orderDetail });
  if (!o) throw new HttpError(404, "No order matches that order number and mobile number.");
  res.json(o);
}));

export default r;
'@

Write-ProjectFile 'backend\src\modules\orders\orders.service.ts' @'
import { OrderStatus, Prisma } from "@prisma/client";
import { db } from "../../config/db";
import { HttpError } from "../../middleware/error";
import { getActiveOffers, unitPrice } from "../../services/pricing";
import { deliveryFeeFor, getSettings } from "../../services/settings";
import { notifyStatusChanged } from "../../services/notify";

export type CheckoutInput = {
  fullName: string; mobile: string; whatsapp?: string; email?: string;
  address?: string; city?: string; postalCode?: string; note?: string;
  deliveryMethod: "DELIVERY" | "PICKUP"; paymentMethod: "BANK_TRANSFER" | "COD" | "ONLINE";
};

// PENDING → CONFIRMED → PROCESSING → READY → DISPATCHED → DELIVERED; CANCELLED before dispatch.
export const nextStatuses: Record<OrderStatus, OrderStatus[]> = {
  PENDING: ["CONFIRMED", "CANCELLED"],
  CONFIRMED: ["PROCESSING", "CANCELLED"],
  PROCESSING: ["READY", "CANCELLED"],
  READY: ["DISPATCHED", "DELIVERED", "CANCELLED"], // DELIVERED straight from READY for store pickup
  DISPATCHED: ["DELIVERED"],
  DELIVERED: [],
  CANCELLED: [],
};

async function nextOrderNo(tx: Prisma.TransactionClient) {
  const last = await tx.order.findFirst({ orderBy: { createdAt: "desc" }, select: { orderNo: true } });
  const n = last ? Number(last.orderNo.replace(/\D/g, "")) + 1 : 1;
  return `ORD-${String(n).padStart(6, "0")}`;
}

export async function placeOrder(cartId: string, userId: string | undefined, input: CheckoutInput) {
  const settings = await getSettings();
  if (input.deliveryMethod === "DELIVERY" && (!input.address || !input.city)) throw new HttpError(400, "Enter your address and city for delivery.");
  if (input.deliveryMethod === "PICKUP" && !settings.pickupEnabled) throw new HttpError(400, "Store pickup isn't available right now.");
  const methodOn = { COD: settings.codEnabled, BANK_TRANSFER: settings.bankEnabled, ONLINE: settings.onlineEnabled }[input.paymentMethod];
  if (!methodOn) throw new HttpError(400, "That payment method isn't available. Choose another one.");
  const offers = await getActiveOffers();

  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      return await db.$transaction(async (tx) => {
        const items = await tx.cartItem.findMany({ where: { cartId }, include: { product: true } });
        const live = items.filter((i) => i.product.isActive);
        if (!live.length) throw new HttpError(400, "Your cart is empty.");

        for (const i of live) {
          const updated = await tx.product.updateMany({ where: { id: i.productId, stock: { gte: i.qty } }, data: { stock: { decrement: i.qty } } });
          if (!updated.count) throw new HttpError(409, `${i.product.name} doesn't have enough stock. Update your cart and try again.`);
        }

        const lines = live.map((i) => ({ productId: i.productId, name: i.product.name, price: unitPrice(i.product, offers), qty: i.qty }));
        const subtotal = lines.reduce((s, l) => s + l.price * l.qty, 0);
        const deliveryFee = input.deliveryMethod === "DELIVERY" ? deliveryFeeFor(settings, subtotal) : 0;

        const order = await tx.order.create({
          data: {
            ...input, userId, orderNo: await nextOrderNo(tx), subtotal, deliveryFee, total: subtotal + deliveryFee,
            items: { create: lines },
            history: { create: { status: "PENDING" } },
          },
          include: { items: true },
        });
        await tx.cartItem.deleteMany({ where: { cartId } });
        return order;
      });
    } catch (e) {
      // Two orders at the same moment can pick the same number; retry with the next one.
      if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === "P2002" && attempt < 2) continue;
      throw e;
    }
  }
  throw new HttpError(500, "Couldn't place the order. Try again.");
}

export async function changeStatus(orderId: string, to: OrderStatus) {
  const o = await db.order.findUnique({ where: { id: orderId }, include: { items: true } });
  if (!o) throw new HttpError(404, "Order not found");
  if (!nextStatuses[o.status].includes(to)) throw new HttpError(409, `An order that is ${o.status.toLowerCase()} can't be moved to ${to.toLowerCase()}.`);

  const updated = await db.$transaction(async (tx) => {
    if (to === "CANCELLED") {
      for (const i of o.items) await tx.product.update({ where: { id: i.productId }, data: { stock: { increment: i.qty } } });
    }
    await tx.orderStatusLog.create({ data: { orderId, status: to } });
    return tx.order.update({ where: { id: orderId }, data: { status: to } });
  });
  notifyStatusChanged(updated).catch(console.error);
  return updated;
}
'@

Write-ProjectFile 'backend\src\modules\products\products.routes.ts' @'
import { Router } from "express";
import { z } from "zod";
import { Prisma, JewelleryType } from "@prisma/client";
import { db } from "../../config/db";
import { ah, HttpError } from "../../middleware/error";
import { requireAdmin } from "../../middleware/auth";
import { upload, fileUrl } from "../../middleware/upload";
import { getActiveOffers, priceFor, withPricing } from "../../services/pricing";

const r = Router();
const slugify = (s: string) => s.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
const firstImage = { images: { orderBy: { sort: "asc" as const }, take: 1 } };

// GET /api/products?ids=a,b&category=earrings&q=&minPrice=&maxPrice=&style=&colour=&inStock=1&newArrivals=1&onSale=1&type=EARRINGS&sort=price_asc&page=1
r.get("/", ah(async (req, res) => {
  const q = z.object({
    category: z.string().optional(), q: z.string().optional(),
    minPrice: z.coerce.number().optional(), maxPrice: z.coerce.number().optional(),
    style: z.string().optional(), colour: z.string().optional(),
    inStock: z.string().optional(), newArrivals: z.string().optional(), onSale: z.string().optional(),
    type: z.nativeEnum(JewelleryType).optional(), tryOn: z.string().optional(),
    ids: z.string().optional().transform((v) => (v ? v.split(",").filter(Boolean).slice(0, 20) : undefined)),
    sort: z.enum(["new", "price_asc", "price_desc", "name"]).default("new"),
    page: z.coerce.number().int().min(1).default(1), limit: z.coerce.number().int().min(1).max(60).default(24),
  }).parse(req.query);

  const where: Prisma.ProductWhereInput = {
    isActive: true,
    ...(q.category && { category: { slug: q.category } }),
    ...(q.q && { OR: [{ name: { contains: q.q, mode: "insensitive" } }, { code: { contains: q.q, mode: "insensitive" } }, { description: { contains: q.q, mode: "insensitive" } }] }),
    ...((q.minPrice !== undefined || q.maxPrice !== undefined) && { price: { gte: q.minPrice, lte: q.maxPrice } }),
    ...(q.style && { style: q.style }),
    ...(q.colour && { colour: q.colour }),
    ...(q.inStock && { stock: { gt: 0 } }),
    ...(q.newArrivals && { isNewArrival: true }),
    ...(q.type && { jewelleryType: q.type }),
    ...(q.tryOn && { tryOnEnabled: true }),
    ...(q.ids && { id: { in: q.ids } }),
  };
  const orderBy: Prisma.ProductOrderByWithRelationInput =
    q.sort === "price_asc" ? { price: "asc" } : q.sort === "price_desc" ? { price: "desc" } : q.sort === "name" ? { name: "asc" } : { createdAt: "desc" };

  if (q.onSale) {
    // Offers can target products, categories or the whole shop, so filter after pricing.
    const offers = await getActiveOffers();
    const all = await db.product.findMany({ where, orderBy, include: firstImage });
    const onSale = all.map((p) => ({ ...p, ...priceFor(p, offers) })).filter((p) => p.salePrice !== null);
    const items = onSale.slice((q.page - 1) * q.limit, q.page * q.limit);
    return res.json({ items, total: onSale.length, page: q.page, pages: Math.max(1, Math.ceil(onSale.length / q.limit)) });
  }

  const [items, total] = await Promise.all([
    db.product.findMany({ where, orderBy, skip: (q.page - 1) * q.limit, take: q.limit, include: firstImage }),
    db.product.count({ where }),
  ]);
  res.json({ items: await withPricing(items), total, page: q.page, pages: Math.max(1, Math.ceil(total / q.limit)) });
}));

// Values for the filter panel
r.get("/filters", ah(async (_req, res) => {
  const [styles, colours, range] = await Promise.all([
    db.product.findMany({ where: { isActive: true, style: { not: null } }, distinct: ["style"], select: { style: true }, orderBy: { style: "asc" } }),
    db.product.findMany({ where: { isActive: true, colour: { not: null } }, distinct: ["colour"], select: { colour: true }, orderBy: { colour: "asc" } }),
    db.product.aggregate({ where: { isActive: true }, _min: { price: true }, _max: { price: true } }),
  ]);
  res.json({
    styles: styles.map((s) => s.style).filter(Boolean),
    colours: colours.map((c) => c.colour).filter(Boolean),
    minPrice: range._min.price ?? 0,
    maxPrice: range._max.price ?? 0,
  });
}));

r.get("/:slug", ah(async (req, res) => {
  const p = await db.product.findUnique({ where: { slug: req.params.slug }, include: { images: { orderBy: { sort: "asc" } }, category: true } });
  if (!p || !p.isActive) throw new HttpError(404, "This product isn't available.");
  const [priced] = await withPricing([p]);
  res.json(priced);
}));

r.get("/:slug/related", ah(async (req, res) => {
  const p = await db.product.findUnique({ where: { slug: req.params.slug }, select: { id: true, categoryId: true } });
  if (!p) return res.json([]);
  const items = await db.product.findMany({
    where: { isActive: true, categoryId: p.categoryId, NOT: { id: p.id } },
    orderBy: { createdAt: "desc" }, take: 4, include: firstImage,
  });
  res.json(await withPricing(items));
}));

// ---------- Admin ----------
const bool = z.preprocess((v) => v === true || v === "true" || v === "on" || v === "1", z.boolean());
const productBody = z.object({
  code: z.string().trim().min(1).max(30), name: z.string().trim().min(2).max(120), description: z.string().max(4000).optional(),
  price: z.coerce.number().int().positive(), stock: z.coerce.number().int().min(0).default(0),
  categoryId: z.string().min(1), jewelleryType: z.nativeEnum(JewelleryType),
  tryOnEnabled: bool.default(true), isNewArrival: bool.default(false), isActive: bool.default(true),
  style: z.string().trim().max(40).optional().transform((v) => v || null),
  colour: z.string().trim().max(40).optional().transform((v) => v || null),
});
const files = upload.fields([{ name: "images", maxCount: 10 }, { name: "tryOnAsset", maxCount: 1 }]);

async function assertCodeFree(code: string, exceptId?: string) {
  const clash = await db.product.findFirst({ where: { code, ...(exceptId && { NOT: { id: exceptId } }) } });
  if (clash) throw new HttpError(409, `Product code ${code} is already used by "${clash.name}".`);
}

r.post("/", requireAdmin, files, ah(async (req, res) => {
  const b = productBody.parse(req.body);
  await assertCodeFree(b.code);
  const f = req.files as Record<string, Express.Multer.File[]> | undefined;
  const p = await db.product.create({
    data: {
      ...b, slug: `${slugify(b.name)}-${slugify(b.code)}`,
      tryOnAssetUrl: f?.tryOnAsset?.[0] ? fileUrl(f.tryOnAsset[0].filename) : undefined,
      images: { create: (f?.images ?? []).map((file, i) => ({ url: fileUrl(file.filename), sort: i })) },
    },
    include: { images: true },
  });
  res.status(201).json(p);
}));

r.put("/:id", requireAdmin, files, ah(async (req, res) => {
  const b = productBody.partial().parse(req.body);
  if (b.code) await assertCodeFree(b.code, req.params.id);
  const f = req.files as Record<string, Express.Multer.File[]> | undefined;
  const current = await db.productImage.aggregate({ where: { productId: req.params.id }, _max: { sort: true } });
  const start = (current._max.sort ?? -1) + 1;
  const p = await db.product.update({
    where: { id: req.params.id },
    data: {
      ...b,
      ...(f?.tryOnAsset?.[0] && { tryOnAssetUrl: fileUrl(f.tryOnAsset[0].filename) }),
      ...(f?.images?.length && { images: { create: f.images.map((file, i) => ({ url: fileUrl(file.filename), sort: start + i })) } }),
    },
    include: { images: { orderBy: { sort: "asc" } } },
  });
  res.json(p);
}));

// Body: { order: [imageId, imageId, ...] } — first becomes the main image
r.put("/:id/images/order", requireAdmin, ah(async (req, res) => {
  const { order } = z.object({ order: z.array(z.string()) }).parse(req.body);
  await db.$transaction(order.map((id, i) => db.productImage.updateMany({ where: { id, productId: req.params.id }, data: { sort: i } })));
  res.status(204).end();
}));

r.delete("/:id/images/:imageId", requireAdmin, ah(async (req, res) => {
  await db.productImage.deleteMany({ where: { id: req.params.imageId, productId: req.params.id } });
  res.status(204).end();
}));

r.delete("/:id/try-on-asset", requireAdmin, ah(async (req, res) => {
  await db.product.update({ where: { id: req.params.id }, data: { tryOnAssetUrl: null } });
  res.status(204).end();
}));

// Hiding keeps order history intact; the product can be shown again from the edit form.
r.delete("/:id", requireAdmin, ah(async (req, res) => {
  await db.product.update({ where: { id: req.params.id }, data: { isActive: false } });
  res.status(204).end();
}));

export default r;
'@

Write-ProjectFile 'backend\src\modules\settings\settings.routes.ts' @'
import { Router } from "express";
import { z } from "zod";
import { db } from "../../config/db";
import { ah } from "../../middleware/error";
import { requireAdmin } from "../../middleware/auth";
import { getSettings } from "../../services/settings";

const r = Router();

r.get("/", ah(async (_req, res) => res.json(await getSettings())));

const body = z.object({
  shopName: z.string().min(1).max(80),
  tagline: z.string().max(200),
  phone: z.string().max(30),
  whatsapp: z.string().max(30),
  email: z.string().max(120),
  address: z.string().max(300),
  deliveryFee: z.coerce.number().int().min(0),
  freeDeliveryOver: z.coerce.number().int().min(0).nullable(),
  bankDetails: z.string().max(1000),
  codEnabled: z.boolean(),
  bankEnabled: z.boolean(),
  onlineEnabled: z.boolean(),
  pickupEnabled: z.boolean(),
}).partial();

r.put("/", requireAdmin, ah(async (req, res) => {
  const data = body.parse(req.body);
  await getSettings();
  res.json(await db.shopSettings.update({ where: { id: 1 }, data }));
}));

export default r;
'@

Write-ProjectFile 'backend\src\modules\tryon\tryon.routes.ts' @'
import { Router } from "express";
import { z } from "zod";
import { db } from "../../config/db";
import { ah, HttpError } from "../../middleware/error";
import { optionalAuth, requireAuth } from "../../middleware/auth";
import { upload, fileUrl } from "../../middleware/upload";

const r = Router();
r.use(optionalAuth);

r.get("/models", ah(async (_req, res) => res.json(await db.aiModel.findMany({ where: { isActive: true }, orderBy: { createdAt: "asc" } }))));

// multipart: productIds (JSON array string), source=AI_MODEL|UPLOAD, aiModelId?, photo?
r.post("/", upload.single("photo"), ah(async (req, res) => {
  const b = z.object({
    productIds: z.string().transform((s, ctx) => {
      try { return z.array(z.string()).min(1).max(5).parse(JSON.parse(s)); }
      catch { ctx.addIssue({ code: "custom", message: "Choose 1 to 5 items" }); return z.NEVER; }
    }),
    source: z.enum(["AI_MODEL", "UPLOAD"]),
    aiModelId: z.string().optional(),
  }).parse(req.body);

  const products = await db.product.findMany({ where: { id: { in: b.productIds }, tryOnEnabled: true, isActive: true } });
  if (products.length !== b.productIds.length) throw new HttpError(400, "One or more of these items can't be tried on.");
  if (new Set(products.map((p) => p.jewelleryType)).size !== products.length) throw new HttpError(400, "Choose one item of each type, for example one pair of earrings and one necklace.");

  let inputUrl: string;
  if (b.source === "UPLOAD") {
    if (!req.file) throw new HttpError(400, "Upload a JPG, PNG or WebP photo to continue.");
    inputUrl = fileUrl(req.file.filename);
  } else {
    const m = b.aiModelId ? await db.aiModel.findFirst({ where: { id: b.aiModelId, isActive: true } }) : null;
    if (!m) throw new HttpError(400, "Choose a model to continue.");
    inputUrl = m.imageUrl;
  }

  const job = await db.tryOn.create({
    data: { userId: req.user?.id, source: b.source, aiModelId: b.source === "AI_MODEL" ? b.aiModelId : undefined, inputUrl, items: { create: b.productIds.map((productId) => ({ productId })) } },
  });
  res.status(202).json({ id: job.id, status: job.status });
}));

r.get("/mine", requireAuth, ah(async (req, res) => {
  res.json(await db.tryOn.findMany({
    where: { userId: req.user!.id, status: "DONE" },
    orderBy: { createdAt: "desc" },
    take: 50,
    select: {
      id: true, resultUrl: true, createdAt: true,
      items: { select: { product: { select: { id: true, name: true, slug: true, price: true, isActive: true } } } },
    },
  }));
}));

// The page polls this every 2 seconds
r.get("/:id", ah(async (req, res) => {
  const j = await db.tryOn.findUnique({ where: { id: req.params.id }, select: { id: true, status: true, resultUrl: true, error: true, items: { select: { productId: true } } } });
  if (!j) throw new HttpError(404, "Try-on not found");
  res.json({ ...j, error: j.error ? "We couldn't create a preview from this photo. Try a clear, front-facing photo with good light." : null });
}));

export default r;
'@

Write-ProjectFile 'backend\src\modules\wishlist\wishlist.routes.ts' @'
import { Router } from "express";
import { db } from "../../config/db";
import { ah, HttpError } from "../../middleware/error";
import { requireAuth } from "../../middleware/auth";
import { withPricing } from "../../services/pricing";

const r = Router();
r.use(requireAuth);

r.get("/", ah(async (req, res) => {
  const rows = await db.wishlistItem.findMany({
    where: { userId: req.user!.id, product: { isActive: true } },
    orderBy: { id: "desc" },
    include: { product: { include: { images: { orderBy: { sort: "asc" }, take: 1 } } } },
  });
  res.json(await withPricing(rows.map((w) => w.product)));
}));

r.get("/ids", ah(async (req, res) => {
  const rows = await db.wishlistItem.findMany({ where: { userId: req.user!.id }, select: { productId: true } });
  res.json(rows.map((w) => w.productId));
}));

r.post("/:productId", ah(async (req, res) => {
  const p = await db.product.findUnique({ where: { id: req.params.productId } });
  if (!p || !p.isActive) throw new HttpError(404, "Product not found");
  await db.wishlistItem.upsert({
    where: { userId_productId: { userId: req.user!.id, productId: p.id } },
    update: {},
    create: { userId: req.user!.id, productId: p.id },
  });
  res.status(204).end();
}));

r.delete("/:productId", ah(async (req, res) => {
  await db.wishlistItem.deleteMany({ where: { userId: req.user!.id, productId: req.params.productId } });
  res.status(204).end();
}));

export default r;
'@

Write-ProjectFile 'backend\src\services\ai\provider.ts' @'
import { JewelleryType } from "@prisma/client";
import { env } from "../../config/env";

export type TryOnRequest = {
  personImageUrl: string;                       // AI model image or customer photo
  items: { imageUrl: string; type: JewelleryType }[];
};
export interface TryOnProvider { generate(req: TryOnRequest): Promise<string /* result image URL */> }

// Where each jewellery type is placed — sent to the AI as guidance.
export const placement: Record<JewelleryType, string> = {
  EARRINGS: "on both earlobes", NECKLACE: "around the neck, resting on the collarbone",
  CHAIN: "around the neck", LONG_CHAIN: "around the neck, hanging to mid-chest",
  BANGLE: "on the wrist", BRACELET: "on the wrist", RING: "on the ring finger",
  ANKLET: "on the ankle", HAIR: "in the hair", OTHER: "where it is naturally worn",
};

export const buildPrompt = (r: TryOnRequest) =>
  "Photorealistic virtual try-on. Keep the person's face, skin tone, pose and background unchanged. Add: " +
  r.items.map((i, n) => `item ${n + 1} ${placement[i.type]}`).join("; ") +
  ". Match lighting and scale; keep the jewellery design exactly as in the reference images.";

class MockProvider implements TryOnProvider {
  async generate(r: TryOnRequest) {
    await new Promise((ok) => setTimeout(ok, 2000));
    return r.personImageUrl; // returns input so the UI flow can be built before the real AI is wired
  }
}

// Generic HTTP provider — adapt body/response to the image-editing API you choose.
class HttpProvider implements TryOnProvider {
  async generate(r: TryOnRequest) {
    const res = await fetch(env.aiEndpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${env.aiApiKey}` },
      body: JSON.stringify({ person_image: r.personImageUrl, reference_images: r.items.map((i) => i.imageUrl), prompt: buildPrompt(r) }),
    });
    if (!res.ok) throw new Error(`AI provider ${res.status}: ${await res.text()}`);
    const data = (await res.json()) as { output_url: string };
    return data.output_url;
  }
}

export const aiProvider: TryOnProvider = env.aiProvider === "http" ? new HttpProvider() : new MockProvider();
'@

Write-ProjectFile 'backend\src\services\ai\tryon.worker.ts' @'
import { db } from "../../config/db";
import { aiProvider } from "./provider";

// Simple DB-polling queue. Swap for BullMQ + Redis when traffic grows.
let running = false;
let lastError = "";

async function processNext() {
  const job = await db.tryOn.findFirst({
    where: { status: "PENDING" }, orderBy: { createdAt: "asc" },
    include: { items: { include: { product: { include: { images: { take: 1, orderBy: { sort: "asc" } } } } } } },
  });
  if (!job) return false;

  const claimed = await db.tryOn.updateMany({ where: { id: job.id, status: "PENDING" }, data: { status: "PROCESSING" } });
  if (!claimed.count) return true;

  try {
    const resultUrl = await aiProvider.generate({
      personImageUrl: job.inputUrl,
      items: job.items.map((i) => ({ imageUrl: i.product.tryOnAssetUrl ?? i.product.images[0]?.url ?? "", type: i.product.jewelleryType })),
    });
    await db.tryOn.update({ where: { id: job.id }, data: { status: "DONE", resultUrl } });
  } catch (e) {
    await db.tryOn.update({ where: { id: job.id }, data: { status: "FAILED", error: String(e).slice(0, 500) } });
  }
  return true;
}

export function startTryOnWorker(intervalMs = 1500) {
  setInterval(async () => {
    if (running) return;
    running = true;
    try {
      while (await processNext());
      lastError = "";
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      if (msg !== lastError) console.error("[tryon worker]", msg);
      lastError = msg;
    } finally {
      running = false;
    }
  }, intervalMs);
}
'@

Write-ProjectFile 'backend\src\services\notify.ts' @'
import { Order, OrderItem, OrderStatus } from "@prisma/client";
import { getSettings } from "./settings";

// Messages are logged for now. To send real SMS or WhatsApp messages, call your provider
// (for example Notify.lk, Dialog eSMS or the WhatsApp Cloud API) inside send().
async function send(to: string, text: string) {
  if (!to) return;
  console.log(`[notify → ${to}]\n${text}\n`);
}

const lkr = (n: number) => `LKR ${n.toLocaleString("en-LK")}`;

export async function notifyOrderPlaced(order: Order & { items: OrderItem[] }) {
  const s = await getSettings();
  const lines = order.items.map((i) => `${i.name} × ${i.qty}`).join("\n");
  await send(order.mobile, `${s.shopName}: order ${order.orderNo} received.\n${lines}\nTotal ${lkr(order.total)}.\nTrack it with your order number and mobile number.`);
  await send(s.whatsapp || s.phone, `New order ${order.orderNo} from ${order.fullName} (${order.mobile}).\n${lines}\nTotal ${lkr(order.total)}`);
}

const statusText: Partial<Record<OrderStatus, string>> = {
  CONFIRMED: "has been confirmed",
  READY: "is ready",
  DISPATCHED: "is on its way",
  DELIVERED: "has been delivered",
  CANCELLED: "has been cancelled",
};

export async function notifyStatusChanged(order: Order) {
  const text = statusText[order.status];
  if (!text) return;
  const s = await getSettings();
  await send(order.mobile, `${s.shopName}: your order ${order.orderNo} ${text}.`);
}

export const whatsappLink = (phone: string, text: string) =>
  `https://wa.me/94${phone.replace(/\D/g, "").replace(/^(94|0)/, "")}?text=${encodeURIComponent(text)}`;
'@

Write-ProjectFile 'backend\src\services\pricing.ts' @'
import { db } from "../config/db";

type Offerish = { id: string; title: string; percentOff: number; productId: string | null; categoryId: string | null };
type Priceable = { id: string; categoryId: string; price: number };

export type Pricing = { salePrice: number | null; offerPercent: number | null; offerTitle: string | null };

export function getActiveOffers() {
  const now = new Date();
  return db.offer.findMany({
    where: { isActive: true, startsAt: { lte: now }, endsAt: { gte: now } },
    select: { id: true, title: true, percentOff: true, productId: true, categoryId: true },
  });
}

// Best offer wins: product-specific, category-wide or shop-wide.
export function priceFor(p: Priceable, offers: Offerish[]): Pricing {
  let best: Offerish | null = null;
  for (const o of offers) {
    const applies = o.productId ? o.productId === p.id : o.categoryId ? o.categoryId === p.categoryId : true;
    if (applies && (!best || o.percentOff > best.percentOff)) best = o;
  }
  if (!best) return { salePrice: null, offerPercent: null, offerTitle: null };
  return {
    salePrice: Math.round((p.price * (100 - best.percentOff)) / 100),
    offerPercent: best.percentOff,
    offerTitle: best.title,
  };
}

export const unitPrice = (p: Priceable, offers: Offerish[]) => priceFor(p, offers).salePrice ?? p.price;

export async function withPricing<T extends Priceable>(items: T[]): Promise<(T & Pricing)[]> {
  const offers = await getActiveOffers();
  return items.map((p) => ({ ...p, ...priceFor(p, offers) }));
}
'@

Write-ProjectFile 'backend\src\services\settings.ts' @'
import { db } from "../config/db";

// The shop has one settings row (id = 1). It is created with defaults the first time it is read.
export const getSettings = () => db.shopSettings.upsert({ where: { id: 1 }, update: {}, create: { id: 1 } });

export function deliveryFeeFor(settings: { deliveryFee: number; freeDeliveryOver: number | null }, subtotal: number) {
  if (settings.freeDeliveryOver && subtotal >= settings.freeDeliveryOver) return 0;
  return settings.deliveryFee;
}
'@

Write-ProjectFile 'backend\tsconfig.json' @'
{
  "compilerOptions": {
    "target": "ES2022", "module": "commonjs", "outDir": "dist", "rootDir": "src",
    "strict": true, "esModuleInterop": true, "skipLibCheck": true
  },
  "include": ["src"]
}
'@

Write-ProjectFile 'frontend\index.html' @'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" /><meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Jewellery Store</title>
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bodoni+Moda:opsz,wght@6..96,500;6..96,600&family=Manrope:wght@400;500;600;700&display=swap" />
  </head>
  <body><div id="root"></div><script type="module" src="/src/main.tsx"></script></body>
</html>
'@

Write-ProjectFile 'frontend\package.json' @'
{
  "name": "jewellery-frontend",
  "private": true,
  "type": "module",
  "scripts": { "dev": "vite", "build": "tsc -b && vite build", "preview": "vite preview" },
  "dependencies": { "react": "^18.3.1", "react-dom": "^18.3.1", "react-router-dom": "^6.26.2" },
  "devDependencies": {
    "@types/react": "^18.3.10", "@types/react-dom": "^18.3.0",
    "@vitejs/plugin-react": "^4.3.2", "typescript": "^5.6.2", "vite": "^5.4.8"
  }
}
'@

Write-ProjectFile 'frontend\src\App.tsx' @'
import { Routes, Route } from "react-router-dom";
import Layout from "./components/Layout";
import RequireAdmin from "./components/RequireAdmin";
import RequireAuth from "./components/RequireAuth";
import Home from "./pages/Home";
import Shop from "./pages/Shop";
import ProductDetails from "./pages/ProductDetails";
import TryOn from "./pages/TryOn";
import BuildLook from "./pages/BuildLook";
import CartPage from "./pages/Cart";
import Checkout from "./pages/Checkout";
import OrderConfirmation from "./pages/OrderConfirmation";
import TrackOrder from "./pages/TrackOrder";
import Account from "./pages/Account";
import Login from "./pages/Login";
import Register from "./pages/Register";
import { About, Contact, Delivery, Faq, NotFound } from "./pages/Info";
import AdminLogin from "./pages/admin/AdminLogin";
import AdminLayout from "./pages/admin/AdminLayout";
import Dashboard from "./pages/admin/Dashboard";
import AdminProducts from "./pages/admin/Products";
import ProductForm from "./pages/admin/ProductForm";
import Categories from "./pages/admin/Categories";
import AdminOrders from "./pages/admin/Orders";
import AdminOrderDetail from "./pages/admin/OrderDetail";
import Customers from "./pages/admin/Customers";
import AiModels from "./pages/admin/AiModels";
import Offers from "./pages/admin/Offers";
import Reports from "./pages/admin/Reports";
import SettingsPage from "./pages/admin/Settings";

export default function App() {
  return (
    <Routes>
      <Route element={<Layout />}>
        <Route path="/" element={<Home />} />
        <Route path="/shop" element={<Shop />} />
        <Route path="/shop/:category" element={<Shop />} />
        <Route path="/product/:slug" element={<ProductDetails />} />
        <Route path="/try-on" element={<TryOn />} />
        <Route path="/build-look" element={<BuildLook />} />
        <Route path="/cart" element={<CartPage />} />
        <Route path="/checkout" element={<Checkout />} />
        <Route path="/order/:orderNo" element={<OrderConfirmation />} />
        <Route path="/track" element={<TrackOrder />} />
        <Route path="/about" element={<About />} />
        <Route path="/contact" element={<Contact />} />
        <Route path="/delivery" element={<Delivery />} />
        <Route path="/faq" element={<Faq />} />
        <Route element={<RequireAuth />}>
          <Route path="/account" element={<Account />} />
          <Route path="/account/:tab" element={<Account />} />
        </Route>
        <Route path="*" element={<NotFound />} />
      </Route>

      <Route path="/login" element={<Login />} />
      <Route path="/register" element={<Register />} />
      <Route path="/admin/login" element={<AdminLogin />} />
      <Route element={<RequireAdmin />}>
        <Route path="/admin" element={<AdminLayout />}>
          <Route index element={<Dashboard />} />
          <Route path="orders" element={<AdminOrders />} />
          <Route path="orders/:id" element={<AdminOrderDetail />} />
          <Route path="products" element={<AdminProducts />} />
          <Route path="products/new" element={<ProductForm />} />
          <Route path="products/:id" element={<ProductForm />} />
          <Route path="categories" element={<Categories />} />
          <Route path="customers" element={<Customers />} />
          <Route path="ai-models" element={<AiModels />} />
          <Route path="offers" element={<Offers />} />
          <Route path="reports" element={<Reports />} />
          <Route path="settings" element={<SettingsPage />} />
        </Route>
      </Route>
    </Routes>
  );
}
'@

Write-ProjectFile 'frontend\src\api\client.ts' @'
import type {
  AiModel, AuthResponse, Cart, Category, Customer, CustomerDetail, DashboardData, Offer, Order, OrderStatus,
  OrdersPage, Paged, PaymentStatus, Product, ProductFilters, ProductReport, SalesRow, SavedTryOn, Settings, TryOnJob, User,
} from "./types";

const cartKey = () => {
  let k = localStorage.getItem("cartKey");
  if (!k) {
    k = typeof crypto !== "undefined" && "randomUUID" in crypto ? crypto.randomUUID() : `${Date.now()}-${Math.random().toString(36).slice(2)}`;
    localStorage.setItem("cartKey", k);
  }
  return k;
};

export const auth = {
  get token() { return localStorage.getItem("token"); },
  set(token: string | null) { token ? localStorage.setItem("token", token) : localStorage.removeItem("token"); },
};

export class ApiError extends Error {
  constructor(public status: number, message: string, public field?: string) { super(message); }
}

async function req<T>(path: string, init: RequestInit = {}): Promise<T> {
  const headers: Record<string, string> = { "x-cart-key": cartKey() };
  if (auth.token) headers.Authorization = `Bearer ${auth.token}`;
  if (init.body && !(init.body instanceof FormData)) headers["Content-Type"] = "application/json";

  let res: Response;
  try {
    res = await fetch(`/api${path}`, { ...init, headers: { ...headers, ...(init.headers as Record<string, string>) } });
  } catch {
    throw new ApiError(0, "Can't reach the shop right now. Check your connection and try again.");
  }
  if (res.status === 204) return undefined as T;
  const data = await res.json().catch(() => ({}));
  if (res.status === 401 && auth.token && !path.startsWith("/auth/login")) auth.set(null);
  if (!res.ok) throw new ApiError(res.status, data.error ?? "Something went wrong. Try again.", data.field);
  return data as T;
}

const json = (method: string, body?: unknown): RequestInit => ({ method, body: body === undefined ? undefined : JSON.stringify(body) });
const qs = (o: Record<string, unknown>) =>
  new URLSearchParams(Object.entries(o).filter(([, v]) => v !== undefined && v !== null && v !== "").map(([k, v]) => [k, String(v)])).toString();

export const api = {
  // Account
  login: (email: string, password: string) => req<AuthResponse>("/auth/login", json("POST", { email, password })),
  register: (b: { name: string; email: string; password: string; phone?: string }) => req<AuthResponse>("/auth/register", json("POST", b)),
  me: () => req<User>("/auth/me"),
  updateMe: (b: { name?: string; phone?: string }) => req<User>("/auth/me", json("PATCH", b)),
  changePassword: (current: string, next: string) => req<void>("/auth/password", json("POST", { current, next })),
  mergeCart: () => req<Cart>("/cart/merge", json("POST", { guestKey: cartKey() })),

  // Shop
  settings: () => req<Settings>("/settings"),
  categories: () => req<Category[]>("/categories"),
  products: (f: Record<string, unknown> = {}) => req<Paged<Product>>(`/products?${qs(f)}`),
  productFilters: () => req<ProductFilters>("/products/filters"),
  product: (slug: string) => req<Product>(`/products/${encodeURIComponent(slug)}`),
  related: (slug: string) => req<Product[]>(`/products/${encodeURIComponent(slug)}/related`),

  // Cart & orders
  cart: () => req<Cart>("/cart"),
  addToCart: (items: { productId: string; qty: number }[]) => req<Cart>("/cart/items", json("POST", { items })),
  setQty: (productId: string, qty: number) => req<Cart>(`/cart/items/${productId}`, json("PATCH", { qty })),
  removeItem: (productId: string) => req<Cart>(`/cart/items/${productId}`, json("DELETE")),
  placeOrder: (b: Record<string, unknown>) => req<Order>("/orders", json("POST", b)),
  myOrders: () => req<Order[]>("/orders/mine"),
  trackOrder: (orderNo: string, mobile: string) => req<Order>(`/orders/track?${qs({ orderNo, mobile })}`),

  // Wishlist
  wishlist: () => req<Product[]>("/wishlist"),
  wishlistIds: () => req<string[]>("/wishlist/ids"),
  addWish: (productId: string) => req<void>(`/wishlist/${productId}`, json("POST")),
  removeWish: (productId: string) => req<void>(`/wishlist/${productId}`, json("DELETE")),

  // Try-on
  aiModels: () => req<AiModel[]>("/tryon/models"),
  startTryOn: (fd: FormData) => req<TryOnJob>("/tryon", { method: "POST", body: fd }),
  tryOnStatus: (id: string) => req<TryOnJob>(`/tryon/${id}`),
  myTryOns: () => req<SavedTryOn[]>("/tryon/mine"),

  admin: {
    dashboard: () => req<DashboardData>("/admin/dashboard"),

    products: (f: Record<string, unknown> = {}) => req<Paged<Product>>(`/admin/products?${qs(f)}`),
    product: (id: string) => req<Product>(`/admin/products/${id}`),
    saveProduct: (fd: FormData, id?: string) => req<Product>(id ? `/products/${id}` : "/products", { method: id ? "PUT" : "POST", body: fd }),
    hideProduct: (id: string) => req<void>(`/products/${id}`, json("DELETE")),
    deleteImage: (productId: string, imageId: string) => req<void>(`/products/${productId}/images/${imageId}`, json("DELETE")),
    orderImages: (productId: string, order: string[]) => req<void>(`/products/${productId}/images/order`, json("PUT", { order })),
    removeTryOnAsset: (productId: string) => req<void>(`/products/${productId}/try-on-asset`, json("DELETE")),

    saveCategory: (fd: FormData, id?: string) => req<Category>(id ? `/categories/${id}` : "/categories", { method: id ? "PUT" : "POST", body: fd }),
    deleteCategory: (id: string) => req<void>(`/categories/${id}`, json("DELETE")),

    orders: (f: Record<string, unknown> = {}) => req<OrdersPage>(`/admin/orders?${qs(f)}`),
    order: (id: string) => req<Order>(`/admin/orders/${id}`),
    setStatus: (id: string, status: OrderStatus) => req<Order>(`/admin/orders/${id}/status`, json("PATCH", { status })),
    setPayment: (id: string, paymentStatus: PaymentStatus) => req<Order>(`/admin/orders/${id}/payment`, json("PATCH", { paymentStatus })),

    customers: (f: Record<string, unknown> = {}) => req<Paged<Customer>>(`/admin/customers?${qs(f)}`),
    customer: (id: string) => req<CustomerDetail>(`/admin/customers/${id}`),

    aiModels: () => req<AiModel[]>("/admin/ai-models"),
    addAiModel: (fd: FormData) => req<AiModel>("/admin/ai-models", { method: "POST", body: fd }),
    updateAiModel: (id: string, b: { name?: string; isActive?: boolean }) => req<AiModel>(`/admin/ai-models/${id}`, json("PATCH", b)),
    deleteAiModel: (id: string) => req<{ hidden?: boolean } | undefined>(`/admin/ai-models/${id}`, json("DELETE")),

    offers: () => req<Offer[]>("/admin/offers"),
    saveOffer: (b: Record<string, unknown>, id?: string) => req<Offer>(id ? `/admin/offers/${id}` : "/admin/offers", json(id ? "PUT" : "POST", b)),
    deleteOffer: (id: string) => req<void>(`/admin/offers/${id}`, json("DELETE")),

    salesReport: (range: "daily" | "weekly" | "monthly") => req<SalesRow[]>(`/admin/reports/sales?range=${range}`),
    ordersReport: () => req<{ status: OrderStatus; count: number }[]>("/admin/reports/orders"),
    productsReport: () => req<ProductReport>("/admin/reports/products"),

    saveSettings: (b: Partial<Settings>) => req<Settings>("/settings", json("PUT", b)),
  },
};
'@

Write-ProjectFile 'frontend\src\api\format.ts' @'
import type { DeliveryMethod, JewelleryType, OrderStatus, PaymentMethod, PaymentStatus } from "./types";

export const lkr = (n: number) => `LKR ${Math.round(n).toLocaleString("en-LK")}`;

export const shortDate = (iso: string) => new Date(iso).toLocaleDateString("en-GB", { day: "numeric", month: "short", year: "numeric" });
export const dateTime = (iso: string) =>
  new Date(iso).toLocaleString("en-GB", { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" });

export const statusLabel: Record<OrderStatus, string> = {
  PENDING: "Pending", CONFIRMED: "Confirmed", PROCESSING: "Processing", READY: "Ready",
  DISPATCHED: "Dispatched", DELIVERED: "Delivered", CANCELLED: "Cancelled",
};

export const customerStatus: Record<OrderStatus, string> = {
  PENDING: "Order received", CONFIRMED: "Confirmed", PROCESSING: "Being prepared", READY: "Ready",
  DISPATCHED: "On the way", DELIVERED: "Delivered", CANCELLED: "Cancelled",
};

export const paymentLabel: Record<PaymentMethod, string> = { BANK_TRANSFER: "Bank transfer", COD: "Cash on delivery", ONLINE: "Online payment" };
export const paymentStatusLabel: Record<PaymentStatus, string> = { UNPAID: "Not paid", PAID: "Paid", REFUNDED: "Refunded" };
export const deliveryLabel: Record<DeliveryMethod, string> = { DELIVERY: "Delivery", PICKUP: "Store pickup" };

export const typeLabel: Record<JewelleryType, string> = {
  EARRINGS: "Earrings", NECKLACE: "Necklace", CHAIN: "Chain", LONG_CHAIN: "Long chain", BANGLE: "Bangle",
  BRACELET: "Bracelet", RING: "Ring", ANKLET: "Anklet", HAIR: "Hair accessory", OTHER: "Other",
};
export const jewelleryTypes = Object.keys(typeLabel) as JewelleryType[];

export const phoneLink = (n: string) => `tel:${n.replace(/\s/g, "")}`;
export const whatsappLink = (n: string, text = "") =>
  `https://wa.me/94${n.replace(/\D/g, "").replace(/^(94|0)/, "")}${text ? `?text=${encodeURIComponent(text)}` : ""}`;
'@

Write-ProjectFile 'frontend\src\api\types.ts' @'
export type JewelleryType = "EARRINGS" | "NECKLACE" | "CHAIN" | "LONG_CHAIN" | "BANGLE" | "BRACELET" | "RING" | "ANKLET" | "HAIR" | "OTHER";
export type OrderStatus = "PENDING" | "CONFIRMED" | "PROCESSING" | "READY" | "DISPATCHED" | "DELIVERED" | "CANCELLED";
export type PaymentMethod = "BANK_TRANSFER" | "COD" | "ONLINE";
export type PaymentStatus = "UNPAID" | "PAID" | "REFUNDED";
export type DeliveryMethod = "DELIVERY" | "PICKUP";
export type Role = "CUSTOMER" | "ADMIN";

export type Paged<T> = { items: T[]; total: number; page: number; pages: number };

export type Category = { id: string; name: string; slug: string; imageUrl?: string | null; sort: number; _count?: { products: number } };
export type ProductImage = { id: string; url: string; sort?: number };

export type Pricing = { salePrice: number | null; offerPercent: number | null; offerTitle: string | null };
export type Product = Pricing & {
  id: string; code: string; name: string; slug: string; description?: string | null;
  price: number; stock: number; isActive: boolean; isNewArrival: boolean;
  style?: string | null; colour?: string | null;
  jewelleryType: JewelleryType; tryOnEnabled: boolean; tryOnAssetUrl?: string | null;
  categoryId: string; category?: Category; images: ProductImage[]; createdAt: string;
};
export type ProductFilters = { styles: string[]; colours: string[]; minPrice: number; maxPrice: number };

export type CartItem = { id: string; productId: string; qty: number; unitPrice: number; lineTotal: number; inStock: boolean; product: Product };
export type Cart = { id: string; items: CartItem[]; subtotal: number; deliveryFee: number; total: number; freeDeliveryOver: number | null };

export type OrderItem = { id: string; productId: string; name: string; price: number; qty: number; product?: { slug: string; code?: string; images: ProductImage[] } };
export type StatusLog = { id: string; status: OrderStatus; createdAt: string };
export type Order = {
  id: string; orderNo: string; fullName: string; mobile: string; whatsapp?: string | null; email?: string | null;
  address?: string | null; city?: string | null; postalCode?: string | null; note?: string | null;
  deliveryMethod: DeliveryMethod; paymentMethod: PaymentMethod; paymentStatus: PaymentStatus;
  subtotal: number; deliveryFee: number; total: number; status: OrderStatus; createdAt: string;
  items: OrderItem[]; history?: StatusLog[]; _count?: { items: number };
  nextStatuses?: OrderStatus[]; user?: { id: string; email: string } | null;
};
export type OrdersPage = Paged<Order> & { byStatus: Partial<Record<OrderStatus, number>> };

export type AiModel = { id: string; name: string; imageUrl: string; isActive: boolean; _count?: { tryOns: number } };
export type TryOnJob = { id: string; status: "PENDING" | "PROCESSING" | "DONE" | "FAILED"; resultUrl?: string | null; error?: string | null };
export type SavedTryOn = { id: string; resultUrl: string; createdAt: string; items: { product: { id: string; name: string; slug: string; price: number; isActive: boolean } }[] };

export type User = { id: string; name: string; email?: string; phone?: string | null; role: Role };
export type AuthResponse = { token: string; user: User };

export type Settings = {
  shopName: string; tagline: string; phone: string; whatsapp: string; email: string; address: string;
  deliveryFee: number; freeDeliveryOver: number | null; bankDetails: string;
  codEnabled: boolean; bankEnabled: boolean; onlineEnabled: boolean; pickupEnabled: boolean;
};

export type Offer = {
  id: string; title: string; percentOff: number; startsAt: string; endsAt: string; isActive: boolean;
  productId: string | null; categoryId: string | null;
  product?: { id: string; name: string; code: string } | null; category?: { id: string; name: string } | null;
};

export type Customer = { id: string; name: string; email: string; phone?: string | null; createdAt: string; _count: { orders: number }; totalSpent: number };
export type CustomerDetail = { id: string; name: string; email: string; phone?: string | null; createdAt: string; orders: Pick<Order, "id" | "orderNo" | "total" | "status" | "createdAt">[] };

export type DashboardData = {
  todayOrders: number; pending: number; processing: number; completed: number; todaySales: number;
  last7Days: { date: string; sales: number; orders: number }[];
  recentOrders: { id: string; orderNo: string; fullName: string; total: number; status: OrderStatus; createdAt: string }[];
  lowStock: { id: string; name: string; code: string; stock: number }[];
};
export type SalesRow = { period: string; orders: number; sales: number };
export type ProductReport = {
  top: { productId: string; name: string; qty: number }[];
  outOfStock: { id: string; name: string; code: string }[];
  newest: { id: string; name: string; code: string; createdAt: string }[];
  mostTried: { id?: string; name?: string; code?: string; tries: number }[];
};
'@

Write-ProjectFile 'frontend\src\components\AuthShell.tsx' @'
import { ReactNode } from "react";
import { Link } from "react-router-dom";
import { useSettings } from "../context/SettingsContext";

type Props = { title: string; subtitle: string; aside: ReactNode; children: ReactNode };

export default function AuthShell({ title, subtitle, aside, children }: Props) {
  const s = useSettings();
  return (
    <div className="auth">
      <aside className="auth-aside">
        <Link to="/" className="auth-logo">{s.shopName}</Link>
        <div className="auth-aside-body">{aside}</div>
      </aside>
      <main className="auth-main">
        <div className="auth-card">
          <h1>{title}</h1>
          <p className="auth-sub">{subtitle}</p>
          {children}
        </div>
      </main>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\components\BarChart.tsx' @'
import { lkr } from "../api/format";

// One series of bars (sales per period). Hover or focus a bar to see its value; a hidden table
// gives screen readers the same numbers.
type Bar = { key: string; label: string; fullLabel: string; value: number; orders: number; highlight?: boolean };

const short = (n: number) => (n >= 1_000_000 ? `${Math.round(n / 100_000) / 10}M` : n >= 1000 ? `${Math.round(n / 100) / 10}k` : String(n));

export default function BarChart({ bars, caption, height = 240 }: { bars: Bar[]; caption: string; height?: number }) {
  const max = Math.max(...bars.map((b) => b.value), 1);
  const dense = bars.length > 14;
  return (
    <>
      <div className={`bars ${dense ? "bars-dense" : ""}`} style={{ height, gridTemplateColumns: `repeat(${bars.length}, minmax(0, 1fr))` }}
        role="img" aria-label={`${caption}. Values are in the table that follows.`}>
        <div className="bars-grid" aria-hidden="true">
          <span>{short(max)}</span>
          <span>{short(Math.round(max / 2))}</span>
          <span>0</span>
        </div>
        {bars.map((b, i) => (
          <div key={b.key} className="bar-col" tabIndex={0} aria-label={`${b.fullLabel}: ${lkr(b.value)}, ${b.orders} orders`}>
            <div className="bar-track">
              <div className={`bar ${b.highlight ? "is-highlight" : ""}`} style={{ height: `${(b.value / max) * 100}%` }} />
              <div className={`bar-tip ${i > bars.length * 0.7 ? "tip-left" : i < bars.length * 0.3 ? "tip-right" : ""}`} role="tooltip">
                <strong>{lkr(b.value)}</strong>
                <span>{b.orders} {b.orders === 1 ? "order" : "orders"} · {b.fullLabel}</span>
              </div>
            </div>
            <span className="bar-label">{dense && i % 5 !== 0 && i !== bars.length - 1 ? "" : b.label}</span>
          </div>
        ))}
      </div>
      <div className="sr-only">
        <table>
          <caption>{caption}</caption>
          <thead><tr><th>Period</th><th>Sales</th><th>Orders</th></tr></thead>
          <tbody>{bars.map((b) => <tr key={b.key}><td>{b.fullLabel}</td><td>{lkr(b.value)}</td><td>{b.orders}</td></tr>)}</tbody>
        </table>
      </div>
    </>
  );
}
'@

Write-ProjectFile 'frontend\src\components\Icon.tsx' @'
// Line icons, 24×24, drawn with the current text colour.
const paths = {
  dashboard: "M4 4h7v7H4zM13 4h7v4h-7zM13 10h7v10h-7zM4 13h7v7H4z",
  products: "M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z",
  sparkle: "M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8zM19 16l.7 1.8 1.8.7-1.8.7L19 21l-.7-1.8-1.8-.7 1.8-.7z",
  orders: "M5 8h14l-1 12H6zM9 8a3 3 0 0 1 6 0",
  bag: "M5 8h14l-1 12H6zM9 8a3 3 0 0 1 6 0",
  categories: "M4 5h6v6H4zM14 5h6v6h-6zM4 15h6v4H4zM14 15h6v4h-6z",
  customers: "M9 11a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM3 20c.6-3.5 3-5.5 6-5.5s5.4 2 6 5.5M16 5.5a3 3 0 0 1 0 5.8M18 14.8c1.7.7 2.8 2.4 3 5.2",
  reports: "M4 20V10M10 20V4M16 20v-7M22 20H2",
  offers: "M20 12l-8 8-8-8V4h8zM8 8h.01",
  settings: "M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z",
  model: "M12 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM5 21v-2a5 5 0 0 1 5-5h4a5 5 0 0 1 5 5v2",
  logout: "M15 4h4v16h-4M10 8l-4 4 4 4M6 12h11",
  store: "M4 10l8-6 8 6v10H4zM10 20v-6h4v6",
  home: "M4 10l8-6 8 6v10H4zM10 20v-6h4v6",
  eye: "M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7S2 12 2 12zM12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6",
  eyeOff: "M3 3l18 18M10.6 5.1A10 10 0 0 1 12 5c6.4 0 10 7 10 7a17 17 0 0 1-3.2 4.1M6.6 6.6C3.7 8.3 2 12 2 12s3.6 7 10 7a9.7 9.7 0 0 0 5.4-1.6M9.9 9.9a3 3 0 0 0 4.2 4.2",
  alert: "M12 3l10 18H2zM12 10v4M12 17.5v.01",
  menu: "M4 7h16M4 12h16M4 17h16",
  user: "M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM4 21c1-4 4-6 8-6s7 2 8 6",
  heart: "M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z",
  search: "M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14zM20 20l-4-4",
  close: "M6 6l12 12M18 6L6 18",
  check: "M5 12.5l4.5 4.5L19 7",
  checkCircle: "M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM8 12.5l2.8 2.8L16 10",
  chevronLeft: "M15 6l-6 6 6 6",
  chevronRight: "M9 6l6 6-6 6",
  chevronDown: "M6 9l6 6 6-6",
  arrowLeft: "M19 12H5M11 6l-6 6 6 6",
  plus: "M12 5v14M5 12h14",
  minus: "M5 12h14",
  trash: "M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3",
  edit: "M4 20h4L19 9l-4-4L4 16zM13.5 6.5l4 4",
  upload: "M12 16V4M7 9l5-5 5 5M4 16v4h16v-4",
  camera: "M4 8h3l2-3h6l2 3h3v11H4zM12 17a4 4 0 1 0 0-8 4 4 0 0 0 0 8z",
  image: "M4 5h16v14H4zM4 15l4-4 5 5M13 13l2-2 5 5M15 9h.01",
  share: "M12 3v12M8 7l4-4 4 4M5 12v8h14v-8",
  download: "M12 4v12M7 11l5 5 5-5M5 20h14",
  filter: "M4 6h16M7 12h10M10 18h4",
  truck: "M3 7h11v9H3zM14 10h4l3 3v3h-7M7 19.5a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3zM17 19.5a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3z",
  cash: "M3 6h18v12H3zM12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z",
  bank: "M3 10l9-6 9 6M5 10v8M9.5 10v8M14.5 10v8M19 10v8M3 20h18",
  card: "M3 6h18v12H3zM3 10h18M7 15h4",
  chat: "M4 5h16v11H9l-5 4z",
  phone: "M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a1 1 0 0 1-1 1A16 16 0 0 1 4 5a1 1 0 0 1 1-1z",
  mail: "M3 6h18v12H3zM3 7l9 6 9-6",
  pin: "M12 21s-7-6.2-7-11a7 7 0 1 1 14 0c0 4.8-7 11-7 11zM12 12.5a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5z",
  clock: "M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 7v5l3 2",
  print: "M7 9V4h10v5M7 17H4v-7h16v7h-3M7 14h10v6H7z",
  refresh: "M20 11a8 8 0 0 0-14.8-4M4 5v4h4M4 13a8 8 0 0 0 14.8 4M20 19v-4h-4",
  lock: "M6 11h12v9H6zM8 11V8a4 4 0 0 1 8 0v3",
  gift: "M4 10h16v10H4zM3 7h18v3H3zM12 7v13M12 7c-2-4-6-3-5 0M12 7c2-4 6-3 5 0",
} as const;

export type IconName = keyof typeof paths;

export default function Icon({ name, size = 20, filled = false }: { name: IconName; size?: number; filled?: boolean }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={filled ? "currentColor" : "none"} stroke="currentColor" strokeWidth={1.8}
      strokeLinecap="round" strokeLinejoin="round" aria-hidden="true" focusable="false">
      <path d={paths[name]} />
    </svg>
  );
}
'@

Write-ProjectFile 'frontend\src\components\JewelIcon.tsx' @'
import type { JewelleryType } from "../api/types";

// Simple line drawings of each kind of jewellery, used for category tiles and image placeholders.
type Kind = "earrings" | "stud" | "bangle" | "chain" | "necklace" | "longchain" | "ring" | "bracelet" | "anklet" | "bridal" | "hair" | "gem";

const shapes: Record<Kind, JSX.Element> = {
  earrings: <><circle cx="24" cy="7" r="3" /><path d="M24 10v6M15 26c0-6 4-10 9-10s9 4 9 10zM16 30h16" /><circle cx="24" cy="38" r="2.5" /></>,
  stud: <><path d="M24 14l8 10-8 10-8-10zM16 24h16" /></>,
  bangle: <><circle cx="24" cy="24" r="16" /><circle cx="24" cy="24" r="11" /></>,
  chain: <><ellipse cx="13" cy="24" rx="8" ry="5" /><ellipse cx="24" cy="24" rx="8" ry="5" /><ellipse cx="35" cy="24" rx="8" ry="5" /></>,
  necklace: <><path d="M8 8c0 16 7 24 16 24s16-8 16-24M20 32l4 8 4-8" /></>,
  longchain: <><path d="M8 6c0 20 7 30 16 30s16-10 16-30M24 36v6" /><circle cx="24" cy="44" r="1.5" /></>,
  ring: <><circle cx="24" cy="30" r="12" /><path d="M18 12l6-6 6 6-6 6z" /></>,
  bracelet: <><ellipse cx="24" cy="24" rx="18" ry="10" /><circle cx="10" cy="22" r="2" /><circle cx="24" cy="34" r="2" /><circle cx="38" cy="22" r="2" /></>,
  anklet: <><path d="M8 20c4 8 28 8 32 0" /><circle cx="16" cy="30" r="2" /><circle cx="24" cy="32" r="2" /><circle cx="32" cy="30" r="2" /></>,
  bridal: <><path d="M24 4v10M24 14l7 8-7 8-7-8zM24 30v6" /><circle cx="24" cy="40" r="2.5" /></>,
  hair: <><path d="M10 30c6-14 22-14 28 0M14 26l-4-6M24 22v-8M34 26l4-6" /><circle cx="24" cy="12" r="2" /></>,
  gem: <><path d="M14 10h20l6 9-16 19L8 19zM8 19h32M20 10l-2 9 6 19 6-19-2-9" /></>,
};

const byType: Record<JewelleryType, Kind> = {
  EARRINGS: "earrings", NECKLACE: "necklace", CHAIN: "chain", LONG_CHAIN: "longchain", BANGLE: "bangle",
  BRACELET: "bracelet", RING: "ring", ANKLET: "anklet", HAIR: "hair", OTHER: "gem",
};

const bySlug = (slug: string): Kind => {
  if (slug.includes("long")) return "longchain";
  if (slug.includes("earring")) return "earrings";
  if (slug.includes("bangle")) return "bangle";
  if (slug.includes("chain")) return "chain";
  if (slug.includes("necklace")) return "necklace";
  if (slug.includes("ring")) return "ring";
  if (slug.includes("bracelet")) return "bracelet";
  if (slug.includes("anklet")) return "anklet";
  if (slug.includes("bridal")) return "bridal";
  if (slug.includes("hair")) return "hair";
  return "gem";
};

type Props = { type?: JewelleryType; slug?: string; size?: number; strokeWidth?: number };

export default function JewelIcon({ type, slug, size = 48, strokeWidth = 1.6 }: Props) {
  const kind = type ? byType[type] : bySlug(slug ?? "");
  return (
    <svg width={size} height={size} viewBox="0 0 48 48" fill="none" stroke="currentColor" strokeWidth={strokeWidth}
      strokeLinecap="round" strokeLinejoin="round" aria-hidden="true" focusable="false">
      {shapes[kind]}
    </svg>
  );
}
'@

Write-ProjectFile 'frontend\src\components\Layout.tsx' @'
import { FormEvent, useEffect, useState } from "react";
import { Link, NavLink, Outlet, useLocation, useNavigate } from "react-router-dom";
import { useCart } from "../context/CartContext";
import { useAuth } from "../context/AuthContext";
import { useWishlist } from "../context/WishlistContext";
import { useSettings } from "../context/SettingsContext";
import { phoneLink, whatsappLink } from "../api/format";
import Icon from "./Icon";

const links = [
  { to: "/", label: "Home", end: true },
  { to: "/shop", label: "Shop" },
  { to: "/shop?newArrivals=1", label: "New arrivals" },
  { to: "/shop?onSale=1", label: "Offers" },
  { to: "/build-look", label: "Create your look" },
  { to: "/about", label: "About" },
  { to: "/contact", label: "Contact" },
];

function SearchForm({ onDone, id }: { onDone?: () => void; id: string }) {
  const nav = useNavigate();
  const submit = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const q = String(new FormData(e.currentTarget).get("q") || "").trim();
    nav(q ? `/shop?q=${encodeURIComponent(q)}` : "/shop");
    onDone?.();
  };
  return (
    <form className="search" role="search" onSubmit={submit}>
      <label htmlFor={id} className="sr-only">Search jewellery</label>
      <Icon name="search" size={18} />
      <input id={id} name="q" type="search" placeholder="Search jewellery or code" />
    </form>
  );
}

export default function Layout() {
  const { count } = useCart();
  const { user, logout } = useAuth();
  const { ids } = useWishlist();
  const s = useSettings();
  const loc = useLocation();
  const [menu, setMenu] = useState(false);

  useEffect(() => { setMenu(false); window.scrollTo(0, 0); }, [loc.pathname, loc.search]);
  useEffect(() => {
    document.body.style.overflow = menu ? "hidden" : "";
    return () => { document.body.style.overflow = ""; };
  }, [menu]);

  const isActive = (to: string) => {
    const [path, query] = to.split("?");
    if (query) return loc.pathname === path && loc.search.includes(query);
    if (path === "/shop") return loc.pathname.startsWith("/shop") && !/newArrivals|onSale/.test(loc.search);
    return undefined;
  };

  return (
    <div className="site">
      <a href="#main" className="skip-link">Skip to content</a>
      <header className="site-header">
        <div className="header-row">
          <button className="icon-btn header-menu" aria-label="Open menu" aria-expanded={menu} aria-controls="mobile-menu" onClick={() => setMenu(true)}>
            <Icon name="menu" />
          </button>
          <Link to="/" className="brand">{s.shopName}</Link>
          <nav className="main-nav" aria-label="Main">
            {links.map((l) => {
              const active = isActive(l.to);
              return (
                <NavLink key={l.to} to={l.to} end={l.end}
                  className={({ isActive: a }) => ((active ?? a) ? "active" : "")}>
                  {l.label}
                </NavLink>
              );
            })}
          </nav>
          <div className="header-search"><SearchForm id="search-desktop" /></div>
          <div className="header-icons">
            <Link to={user ? "/account/wishlist" : "/login"} className="icon-btn header-icon" aria-label={`Wishlist${ids.size ? `, ${ids.size} items` : ""}`}>
              <Icon name="heart" />
              {ids.size > 0 && <span className="count-badge">{ids.size}</span>}
            </Link>
            <Link to="/cart" className="icon-btn header-icon" aria-label={`Cart, ${count} ${count === 1 ? "item" : "items"}`}>
              <Icon name="bag" />
              {count > 0 && <span className="count-badge">{count}</span>}
            </Link>
            {user ? (
              <Link to={user.role === "ADMIN" ? "/admin" : "/account"} className="icon-btn header-icon" aria-label={user.role === "ADMIN" ? "Admin" : "My account"}>
                <Icon name="user" />
              </Link>
            ) : (
              <Link to="/login" state={{ from: loc.pathname + loc.search }} className="header-signin">Sign in</Link>
            )}
          </div>
        </div>
      </header>

      {menu && <button className="drawer-scrim" aria-label="Close menu" onClick={() => setMenu(false)} />}
      <aside id="mobile-menu" className={`drawer ${menu ? "is-open" : ""}`} aria-label="Menu" aria-hidden={!menu}>
        <div className="drawer-head">
          <span className="brand">{s.shopName}</span>
          <button className="icon-btn" aria-label="Close menu" onClick={() => setMenu(false)} tabIndex={menu ? 0 : -1}><Icon name="close" /></button>
        </div>
        {menu && <SearchForm id="search-mobile" onDone={() => setMenu(false)} />}
        <nav className="drawer-nav" aria-label="Mobile">
          {links.map((l) => <NavLink key={l.to} to={l.to} end={l.end} tabIndex={menu ? 0 : -1}>{l.label}</NavLink>)}
          <NavLink to="/track" tabIndex={menu ? 0 : -1}>Track your order</NavLink>
        </nav>
        <div className="drawer-foot">
          {user ? (
            <>
              <Link to={user.role === "ADMIN" ? "/admin" : "/account"} tabIndex={menu ? 0 : -1}>{user.role === "ADMIN" ? "Admin" : "My account"}</Link>
              <button className="btn-link" onClick={logout} tabIndex={menu ? 0 : -1}>Sign out</button>
            </>
          ) : (
            <Link to="/login" className="btn btn-primary btn-block" tabIndex={menu ? 0 : -1}>Sign in</Link>
          )}
        </div>
      </aside>

      <main id="main" className="site-main"><Outlet /></main>

      <footer className="site-footer">
        <div className="footer-inner">
          <div className="footer-brand">
            <span className="brand brand-light">{s.shopName}</span>
            <p>{s.tagline}</p>
          </div>
          <div className="footer-col">
            <h2>Shop</h2>
            <Link to="/shop">All jewellery</Link>
            <Link to="/shop?newArrivals=1">New arrivals</Link>
            <Link to="/shop?onSale=1">Offers</Link>
            <Link to="/build-look">Create your look</Link>
          </div>
          <div className="footer-col">
            <h2>Help</h2>
            <Link to="/track">Track your order</Link>
            <Link to="/delivery">Delivery and returns</Link>
            <Link to="/faq">FAQ</Link>
            <Link to="/faq#try-on">How AI try-on works</Link>
          </div>
          <div className="footer-col">
            <h2>Contact</h2>
            {s.phone && <a href={phoneLink(s.phone)}>{s.phone}</a>}
            {s.whatsapp && <a href={whatsappLink(s.whatsapp)} target="_blank" rel="noreferrer">WhatsApp {s.whatsapp}</a>}
            {s.email && <a href={`mailto:${s.email}`}>{s.email}</a>}
            {s.address && <span>{s.address}</span>}
            {!s.phone && !s.whatsapp && !s.email && !s.address && <Link to="/contact">Contact us</Link>}
          </div>
        </div>
        <div className="footer-base">© {new Date().getFullYear()} {s.shopName}</div>
      </footer>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\components\OrderView.tsx' @'
import { Link } from "react-router-dom";
import type { Order, OrderStatus } from "../api/types";
import { customerStatus, dateTime, deliveryLabel, lkr, paymentLabel } from "../api/format";
import Icon from "./Icon";
import { ProductImage } from "./ui";

const flowDelivery: OrderStatus[] = ["PENDING", "CONFIRMED", "PROCESSING", "DISPATCHED", "DELIVERED"];
const flowPickup: OrderStatus[] = ["PENDING", "CONFIRMED", "PROCESSING", "READY", "DELIVERED"];

export function OrderTimeline({ order }: { order: Order }) {
  const history = order.history ?? [];
  const when = (s: OrderStatus) => history.find((h) => h.status === s)?.createdAt;

  if (order.status === "CANCELLED") {
    return (
      <ol className="timeline">
        <li className="tl-step is-done"><span className="tl-dot"><Icon name="check" size={16} /></span><span className="tl-text"><strong>Order received</strong>{when("PENDING") && <span>{dateTime(when("PENDING")!)}</span>}</span></li>
        <li className="tl-step is-current"><span className="tl-dot" /><span className="tl-text"><strong>Cancelled</strong>{when("CANCELLED") && <span>{dateTime(when("CANCELLED")!)}</span>}</span></li>
      </ol>
    );
  }

  const flow = order.deliveryMethod === "PICKUP" ? flowPickup : flowDelivery;
  const reached = history.map((h) => h.status);
  // READY can happen on delivery orders too; place the current step at the furthest reached point.
  const currentIndex = Math.max(flow.indexOf(order.status), ...reached.map((s) => flow.indexOf(s)));
  const labels: Partial<Record<OrderStatus, string>> = order.deliveryMethod === "PICKUP" ? { READY: "Ready to collect", DELIVERED: "Collected" } : {};

  return (
    <ol className="timeline">
      {flow.map((s, i) => {
        const state = i < currentIndex || (i === currentIndex && s === "DELIVERED") ? "is-done" : i === currentIndex ? "is-current" : "";
        return (
          <li key={s} className={`tl-step ${state}`} aria-current={state === "is-current" ? "step" : undefined}>
            <span className="tl-dot">{state === "is-done" && <Icon name="check" size={16} />}</span>
            <span className="tl-text"><strong>{labels[s] ?? customerStatus[s]}</strong>{when(s) && <span>{dateTime(when(s)!)}</span>}</span>
          </li>
        );
      })}
    </ol>
  );
}

export function OrderLines({ order }: { order: Order }) {
  return (
    <>
      <div className="order-lines">
        {order.items.map((i) => (
          <div key={i.id} className="order-line">
            <span className="order-line-img"><ProductImage url={i.product?.images[0]?.url} alt="" /></span>
            <span>{i.product?.slug ? <Link to={`/product/${i.product.slug}`}>{i.name}</Link> : i.name} <span className="muted">× {i.qty}</span></span>
            <span className="num">{lkr(i.price * i.qty)}</span>
          </div>
        ))}
      </div>
      <div className="order-totals">
        <div className="summary-row"><span>Subtotal</span><span>{lkr(order.subtotal)}</span></div>
        <div className="summary-row"><span>{deliveryLabel[order.deliveryMethod]}</span><span>{order.deliveryFee ? lkr(order.deliveryFee) : "Free"}</span></div>
        <div className="summary-row summary-total"><span>Total</span><span>{lkr(order.total)}</span></div>
        <div className="summary-row muted"><span>Payment</span><span>{paymentLabel[order.paymentMethod]}</span></div>
      </div>
    </>
  );
}
'@

Write-ProjectFile 'frontend\src\components\PasswordInput.tsx' @'
import { useState } from "react";
import Icon from "./Icon";

type Props = { name: string; label: string; autoComplete: string; minLength?: number; hint?: string };

export default function PasswordInput({ name, label, autoComplete, minLength, hint }: Props) {
  const [show, setShow] = useState(false);
  return (
    <label className="field">
      <span className="field-label">{label}</span>
      <span className="input-wrap">
        <input name={name} type={show ? "text" : "password"} required minLength={minLength} autoComplete={autoComplete} />
        <button type="button" className="input-icon" aria-label={show ? "Hide password" : "Show password"} onClick={() => setShow(!show)}>
          <Icon name={show ? "eyeOff" : "eye"} size={18} />
        </button>
      </span>
      {hint && <span className="field-hint">{hint}</span>}
    </label>
  );
}
'@

Write-ProjectFile 'frontend\src\components\ProductCard.tsx' @'
import { Link, useNavigate } from "react-router-dom";
import type { Product } from "../api/types";
import { useCart } from "../context/CartContext";
import { useWishlist } from "../context/WishlistContext";
import Icon from "./Icon";
import { Price, ProductImage } from "./ui";

export default function ProductCard({ p }: { p: Product }) {
  const { add } = useCart();
  const { has, toggle } = useWishlist();
  const nav = useNavigate();
  const saved = has(p.id);
  const soldOut = p.stock <= 0;

  return (
    <article className="pcard">
      <div className="pcard-media">
        <Link to={`/product/${p.slug}`} className="pcard-link" tabIndex={-1} aria-hidden="true">
          <ProductImage url={p.images[0]?.url} alt={p.name} type={p.jewelleryType} />
        </Link>
        <div className="pcard-badges">
          {p.salePrice != null && <span className="badge badge-sale">{p.offerPercent}% off</span>}
          {p.isNewArrival && <span className="badge">New</span>}
          {soldOut && <span className="badge badge-muted">Sold out</span>}
        </div>
        <button className={`pcard-wish ${saved ? "is-on" : ""}`} aria-pressed={saved} aria-label={saved ? `Remove ${p.name} from wishlist` : `Save ${p.name} to wishlist`} onClick={() => toggle(p.id, p.name)}>
          <Icon name="heart" size={20} filled={saved} />
        </button>
      </div>
      <div className="pcard-body">
        <h3 className="pcard-name"><Link to={`/product/${p.slug}`}>{p.name}</Link></h3>
        <span className="pcard-code">Code {p.code}</span>
        <Price price={p.price} pricing={p} />
      </div>
      <div className="pcard-actions">
        <button className="btn btn-primary btn-sm pcard-add" disabled={soldOut} onClick={() => add([{ productId: p.id, qty: 1 }], `${p.name} added to cart`)}>
          {soldOut ? "Sold out" : "Add to cart"}
        </button>
        {p.tryOnEnabled && (
          <button className="btn btn-secondary btn-sm btn-icon-text" onClick={() => nav(`/try-on?products=${p.id}`)} aria-label={`Try on ${p.name} with AI`}>
            <Icon name="sparkle" size={16} /><span className="pcard-try-label">Try on</span>
          </button>
        )}
      </div>
    </article>
  );
}
'@

Write-ProjectFile 'frontend\src\components\RequireAdmin.tsx' @'
import { Navigate, Outlet } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { PageLoading } from "./ui";

export default function RequireAdmin() {
  const { user, loading } = useAuth();
  if (loading) return <PageLoading />;
  if (!user) return <Navigate to="/admin/login" replace />;
  if (user.role !== "ADMIN") return <Navigate to="/" replace />;
  return <Outlet />;
}
'@

Write-ProjectFile 'frontend\src\components\RequireAuth.tsx' @'
import { Navigate, Outlet, useLocation } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { PageLoading } from "./ui";

export default function RequireAuth() {
  const { user, loading } = useAuth();
  const loc = useLocation();
  if (loading) return <PageLoading />;
  if (!user) return <Navigate to="/login" replace state={{ from: loc.pathname }} />;
  return <Outlet />;
}
'@

Write-ProjectFile 'frontend\src\components\ui.tsx' @'
import { ReactNode, useEffect, useRef, useState } from "react";
import { Link } from "react-router-dom";
import type { JewelleryType, OrderStatus, Pricing } from "../api/types";
import { lkr, statusLabel } from "../api/format";
import Icon, { IconName } from "./Icon";
import JewelIcon from "./JewelIcon";

/* ---------- Product image with a drawn placeholder ---------- */
export function ProductImage({ url, alt, type, className = "", iconSize = 72 }: { url?: string | null; alt: string; type?: JewelleryType; className?: string; iconSize?: number }) {
  const [failed, setFailed] = useState(false);
  if (url && !failed) return <img src={url} alt={alt} className={`pimg ${className}`} loading="lazy" onError={() => setFailed(true)} />;
  return <span className={`pimg pimg-empty ${className}`} role="img" aria-label={alt}><JewelIcon type={type} size={iconSize} strokeWidth={1.3} /></span>;
}

/* ---------- Price with offer ---------- */
export function Price({ price, pricing, size = "md" }: { price: number; pricing?: Pricing; size?: "md" | "lg" }) {
  const sale = pricing?.salePrice;
  return (
    <span className={`price price-${size}`}>
      {sale != null ? (
        <>
          <span className="price-now">{lkr(sale)}</span>
          <s className="price-was"><span className="sr-only">Was </span>{lkr(price)}</s>
          <span className="price-off">{pricing?.offerPercent}% off</span>
        </>
      ) : <span className="price-now">{lkr(price)}</span>}
    </span>
  );
}

/* ---------- Quantity stepper ---------- */
export function QtyStepper({ value, max, onChange, label = "Quantity", disabled }: { value: number; max: number; onChange: (n: number) => void; label?: string; disabled?: boolean }) {
  return (
    <div className="qty" role="group" aria-label={label}>
      <button type="button" className="qty-btn" aria-label="Decrease quantity" disabled={disabled || value <= 1} onClick={() => onChange(value - 1)}><Icon name="minus" size={16} /></button>
      <output className="qty-value" aria-live="polite">{value}</output>
      <button type="button" className="qty-btn" aria-label="Increase quantity" disabled={disabled || value >= max} onClick={() => onChange(value + 1)}><Icon name="plus" size={16} /></button>
    </div>
  );
}

/* ---------- Order status pill ---------- */
export function StatusPill({ status, label }: { status: OrderStatus; label?: string }) {
  return <span className={`pill pill-${status.toLowerCase()}`}>{label ?? statusLabel[status]}</span>;
}

/* ---------- Loading / empty / error ---------- */
export function PageLoading({ label = "Loading…" }: { label?: string }) {
  return <div className="page-loading" role="status"><span className="spinner" aria-hidden="true" />{label}</div>;
}

export function EmptyState({ icon = "search", title, children, action }: { icon?: IconName; title: string; children?: ReactNode; action?: ReactNode }) {
  return (
    <div className="empty-state">
      <span className="empty-icon"><Icon name={icon} size={28} /></span>
      <h2>{title}</h2>
      {children && <p>{children}</p>}
      {action}
    </div>
  );
}

export function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div className="empty-state">
      <span className="empty-icon empty-icon-error"><Icon name="alert" size={28} /></span>
      <h2>That didn't load</h2>
      <p>{message}</p>
      {onRetry && <button className="btn btn-secondary" onClick={onRetry}><Icon name="refresh" size={18} />Try again</button>}
    </div>
  );
}

/* ---------- Pagination ---------- */
export function Pagination({ page, pages, onPage }: { page: number; pages: number; onPage: (p: number) => void }) {
  if (pages <= 1) return null;
  const nums = Array.from({ length: pages }, (_, i) => i + 1).filter((n) => n === 1 || n === pages || Math.abs(n - page) <= 1);
  return (
    <nav className="pager" aria-label="Pages">
      <button className="pager-btn" disabled={page <= 1} onClick={() => onPage(page - 1)} aria-label="Previous page"><Icon name="chevronLeft" size={18} /></button>
      {nums.map((n, i) => (
        <span key={n} className="pager-group">
          {i > 0 && n - nums[i - 1] > 1 && <span className="pager-gap" aria-hidden="true">…</span>}
          <button className={`pager-btn ${n === page ? "is-current" : ""}`} aria-current={n === page ? "page" : undefined} onClick={() => onPage(n)}>{n}</button>
        </span>
      ))}
      <button className="pager-btn" disabled={page >= pages} onClick={() => onPage(page + 1)} aria-label="Next page"><Icon name="chevronRight" size={18} /></button>
    </nav>
  );
}

/* ---------- Modal (native dialog) ---------- */
export function Modal({ open, title, onClose, children, footer, wide }: { open: boolean; title: string; onClose: () => void; children: ReactNode; footer?: ReactNode; wide?: boolean }) {
  const ref = useRef<HTMLDialogElement>(null);
  useEffect(() => {
    const d = ref.current;
    if (!d) return;
    if (open && !d.open) d.showModal();
    if (!open && d.open) d.close();
  }, [open]);
  return (
    <dialog ref={ref} className={`modal ${wide ? "modal-wide" : ""}`} onClose={onClose} onCancel={(e) => { e.preventDefault(); onClose(); }}
      onClick={(e) => { if (e.target === ref.current) onClose(); }}>
      {open && (
        <div className="modal-inner">
          <header className="modal-head">
            <h2>{title}</h2>
            <button className="icon-btn" aria-label="Close" onClick={onClose}><Icon name="close" /></button>
          </header>
          <div className="modal-body">{children}</div>
          {footer && <footer className="modal-foot">{footer}</footer>}
        </div>
      )}
    </dialog>
  );
}

export function ConfirmDialog({ open, title, body, confirmLabel, danger, busy, onConfirm, onClose }: {
  open: boolean; title: string; body: ReactNode; confirmLabel: string; danger?: boolean; busy?: boolean; onConfirm: () => void; onClose: () => void;
}) {
  return (
    <Modal open={open} title={title} onClose={onClose} footer={
      <>
        <button className="btn btn-secondary" onClick={onClose}>Keep it</button>
        <button className={`btn ${danger ? "btn-danger" : "btn-primary"}`} disabled={busy} onClick={onConfirm}>{busy ? "Working…" : confirmLabel}</button>
      </>
    }>
      <p className="modal-text">{body}</p>
    </Modal>
  );
}

/* ---------- Breadcrumb ---------- */
export function Breadcrumb({ items }: { items: { to?: string; label: string }[] }) {
  return (
    <nav className="crumbs" aria-label="Breadcrumb">
      <ol>
        {items.map((it, i) => (
          <li key={i}>
            {it.to && i < items.length - 1 ? <Link to={it.to}>{it.label}</Link> : <span aria-current={i === items.length - 1 ? "page" : undefined}>{it.label}</span>}
          </li>
        ))}
      </ol>
    </nav>
  );
}

/* ---------- Switch (checkbox styled as a toggle) ---------- */
export function Switch({ name, label, hint, defaultChecked, checked, onChange }: { name?: string; label: string; hint?: string; defaultChecked?: boolean; checked?: boolean; onChange?: (v: boolean) => void }) {
  return (
    <label className="switch">
      <input type="checkbox" role="switch" name={name} defaultChecked={defaultChecked} checked={checked} onChange={onChange ? (e) => onChange(e.target.checked) : undefined} />
      <span className="switch-track" aria-hidden="true"><span className="switch-thumb" /></span>
      <span className="switch-text"><span className="switch-label">{label}</span>{hint && <span className="field-hint">{hint}</span>}</span>
    </label>
  );
}
'@

Write-ProjectFile 'frontend\src\context\AuthContext.tsx' @'
import { createContext, useContext, useEffect, useState, ReactNode } from "react";
import { api, auth } from "../api/client";
import type { User } from "../api/types";
import { useCart } from "./CartContext";

type RegisterInput = { name: string; email: string; password: string; phone?: string };
type Ctx = {
  user: User | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<User>;
  register: (b: RegisterInput) => Promise<User>;
  logout: () => void;
  setUser: (u: User) => void;
};

const AuthContext = createContext<Ctx>(null!);

export function AuthProvider({ children }: { children: ReactNode }) {
  const { refresh } = useCart();
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(!!auth.token);

  useEffect(() => {
    if (!auth.token) return;
    api.me()
      .then(setUser)
      .catch(() => auth.set(null))
      .finally(() => setLoading(false));
  }, []);

  const signIn = async (token: string, u: User) => {
    auth.set(token);
    setUser(u);
    if (u.role === "CUSTOMER") await api.mergeCart().catch(() => undefined);
    await refresh().catch(() => undefined);
    return u;
  };

  const value: Ctx = {
    user,
    loading,
    login: async (email, password) => {
      const r = await api.login(email, password);
      return signIn(r.token, r.user);
    },
    register: async (b) => {
      const r = await api.register(b);
      return signIn(r.token, r.user);
    },
    logout: () => {
      auth.set(null);
      setUser(null);
      refresh().catch(() => undefined);
    },
    setUser,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export const useAuth = () => useContext(AuthContext);
'@

Write-ProjectFile 'frontend\src\context\CartContext.tsx' @'
import { createContext, useContext, useEffect, useState, ReactNode } from "react";
import { api } from "../api/client";
import type { Cart } from "../api/types";
import { useToast } from "./ToastContext";

type Ctx = {
  cart: Cart | null;
  count: number;
  add: (items: { productId: string; qty: number }[], message?: string) => Promise<boolean>;
  setQty: (productId: string, qty: number) => Promise<void>;
  remove: (productId: string) => Promise<void>;
  refresh: () => Promise<void>;
};
const CartContext = createContext<Ctx>(null!);

export function CartProvider({ children }: { children: ReactNode }) {
  const { show } = useToast();
  const [cart, setCart] = useState<Cart | null>(null);
  const refresh = async () => setCart(await api.cart());
  useEffect(() => { refresh().catch(() => undefined); }, []);

  const value: Ctx = {
    cart,
    count: cart?.items.reduce((s, i) => s + i.qty, 0) ?? 0,
    add: async (items, message) => {
      try {
        setCart(await api.addToCart(items));
        show(message ?? "Added to cart", { link: { to: "/cart", label: "View cart" } });
        return true;
      } catch (e) {
        show((e as Error).message, { kind: "error" });
        return false;
      }
    },
    setQty: async (id, qty) => {
      try { setCart(await api.setQty(id, qty)); } catch (e) { show((e as Error).message, { kind: "error" }); }
    },
    remove: async (id) => {
      try { setCart(await api.removeItem(id)); show("Removed from cart"); } catch (e) { show((e as Error).message, { kind: "error" }); }
    },
    refresh,
  };
  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}
export const useCart = () => useContext(CartContext);
'@

Write-ProjectFile 'frontend\src\context\SettingsContext.tsx' @'
import { createContext, useContext, useEffect, useState, ReactNode } from "react";
import { api } from "../api/client";
import type { Settings } from "../api/types";

const defaults: Settings = {
  shopName: "[Shop name]", tagline: "Jewellery for every day and every occasion.",
  phone: "", whatsapp: "", email: "", address: "",
  deliveryFee: 450, freeDeliveryOver: null, bankDetails: "",
  codEnabled: true, bankEnabled: true, onlineEnabled: false, pickupEnabled: true,
};

type Ctx = { settings: Settings; reload: () => Promise<void> };
const SettingsContext = createContext<Ctx>({ settings: defaults, reload: async () => undefined });

export function SettingsProvider({ children }: { children: ReactNode }) {
  const [settings, setSettings] = useState<Settings>(defaults);
  const reload = async () => {
    const data = await api.settings();
    // Keep defaults for anything the server doesn't send (for example an older backend).
    if (data && typeof data === "object" && !Array.isArray(data)) setSettings({ ...defaults, ...data });
  };

  useEffect(() => { reload().catch(() => undefined); }, []);
  useEffect(() => { document.title = settings.shopName.replace(/^\[|\]$/g, "") || "Jewellery"; }, [settings.shopName]);

  return <SettingsContext.Provider value={{ settings, reload }}>{children}</SettingsContext.Provider>;
}

export const useSettings = () => useContext(SettingsContext).settings;
export const useReloadSettings = () => useContext(SettingsContext).reload;
'@

Write-ProjectFile 'frontend\src\context\ToastContext.tsx' @'
import { createContext, useCallback, useContext, useRef, useState, ReactNode } from "react";
import { Link } from "react-router-dom";
import Icon from "../components/Icon";

type Toast = { id: number; text: string; kind: "ok" | "error"; link?: { to: string; label: string } };
type Ctx = { show: (text: string, opts?: { kind?: "ok" | "error"; link?: { to: string; label: string } }) => void };

const ToastContext = createContext<Ctx>({ show: () => undefined });

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);
  const nextId = useRef(1);

  const dismiss = (id: number) => setToasts((t) => t.filter((x) => x.id !== id));
  const show = useCallback<Ctx["show"]>((text, opts = {}) => {
    const id = nextId.current++;
    setToasts((t) => [...t.slice(-2), { id, text, kind: opts.kind ?? "ok", link: opts.link }]);
    window.setTimeout(() => dismiss(id), opts.kind === "error" ? 6000 : 3500);
  }, []);

  return (
    <ToastContext.Provider value={{ show }}>
      {children}
      <div className="toasts" role="status" aria-live="polite">
        {toasts.map((t) => (
          <div key={t.id} className={`toast toast-${t.kind}`}>
            <Icon name={t.kind === "ok" ? "check" : "alert"} size={18} />
            <span className="toast-text">{t.text}</span>
            {t.link && <Link to={t.link.to} className="toast-link" onClick={() => dismiss(t.id)}>{t.link.label}</Link>}
            <button className="icon-btn icon-btn-sm" aria-label="Dismiss" onClick={() => dismiss(t.id)}><Icon name="close" size={16} /></button>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export const useToast = () => useContext(ToastContext);
'@

Write-ProjectFile 'frontend\src\context\WishlistContext.tsx' @'
import { createContext, useContext, useEffect, useState, ReactNode } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { api } from "../api/client";
import { useAuth } from "./AuthContext";
import { useToast } from "./ToastContext";

type Ctx = { ids: Set<string>; has: (id: string) => boolean; toggle: (id: string, name?: string) => Promise<void> };
const WishlistContext = createContext<Ctx>({ ids: new Set(), has: () => false, toggle: async () => undefined });

export function WishlistProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();
  const { show } = useToast();
  const nav = useNavigate();
  const loc = useLocation();
  const [ids, setIds] = useState<Set<string>>(new Set());

  useEffect(() => {
    if (user?.role !== "CUSTOMER") { setIds(new Set()); return; }
    api.wishlistIds().then((list) => setIds(new Set(list))).catch(() => undefined);
  }, [user]);

  const toggle = async (id: string, name?: string) => {
    if (!user) {
      show("Sign in to save pieces to your wishlist");
      nav("/login", { state: { from: loc.pathname + loc.search } });
      return;
    }
    const had = ids.has(id);
    const next = new Set(ids);
    had ? next.delete(id) : next.add(id);
    setIds(next);
    try {
      had ? await api.removeWish(id) : await api.addWish(id);
      show(had ? "Removed from wishlist" : `${name ?? "Saved"} added to your wishlist`, had ? {} : { link: { to: "/account/wishlist", label: "View" } });
    } catch (e) {
      setIds(ids);
      show((e as Error).message, { kind: "error" });
    }
  };

  return <WishlistContext.Provider value={{ ids, has: (id) => ids.has(id), toggle }}>{children}</WishlistContext.Provider>;
}

export const useWishlist = () => useContext(WishlistContext);
'@

Write-ProjectFile 'frontend\src\main.tsx' @'
import React from "react";
import ReactDOM from "react-dom/client";
import { BrowserRouter } from "react-router-dom";
import App from "./App";
import { ToastProvider } from "./context/ToastContext";
import { SettingsProvider } from "./context/SettingsContext";
import { CartProvider } from "./context/CartContext";
import { AuthProvider } from "./context/AuthContext";
import { WishlistProvider } from "./context/WishlistContext";
import "./styles.css";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <BrowserRouter>
      <ToastProvider>
        <SettingsProvider>
          <CartProvider>
            <AuthProvider>
              <WishlistProvider>
                <App />
              </WishlistProvider>
            </AuthProvider>
          </CartProvider>
        </SettingsProvider>
      </ToastProvider>
    </BrowserRouter>
  </React.StrictMode>
);
'@

Write-ProjectFile 'frontend\src\pages\Account.tsx' @'
import { FormEvent, useEffect, useState } from "react";
import { Link, NavLink, Navigate, useNavigate, useParams } from "react-router-dom";
import { api } from "../api/client";
import type { Order, Product, SavedTryOn } from "../api/types";
import { customerStatus, lkr, shortDate } from "../api/format";
import { useAuth } from "../context/AuthContext";
import { useToast } from "../context/ToastContext";
import { useWishlist } from "../context/WishlistContext";
import ProductCard from "../components/ProductCard";
import PasswordInput from "../components/PasswordInput";
import Icon from "../components/Icon";
import { EmptyState, ErrorState, PageLoading, ProductImage, StatusPill } from "../components/ui";
import { OrderLines, OrderTimeline } from "../components/OrderView";

function Orders() {
  const [orders, setOrders] = useState<Order[] | null>(null);
  const [err, setErr] = useState("");
  const [open, setOpen] = useState<string | null>(null);
  const load = () => { setErr(""); api.myOrders().then(setOrders).catch((e) => setErr((e as Error).message)); };
  useEffect(load, []);

  if (err) return <ErrorState message={err} onRetry={load} />;
  if (!orders) return <PageLoading />;
  if (!orders.length) return <EmptyState icon="bag" title="No orders yet" action={<Link to="/shop" className="btn btn-primary">Start shopping</Link>}>Orders you place while signed in show here.</EmptyState>;

  return (
    <div className="stack">
      {orders.map((o) => (
        <article key={o.id} className="order-card">
          <div className="order-card-head">
            <div><strong>{o.orderNo}</strong><div className="muted" style={{ fontSize: 14 }}>Placed {shortDate(o.createdAt)} · {o.items.reduce((s, i) => s + i.qty, 0)} pieces</div></div>
            <StatusPill status={o.status} label={customerStatus[o.status]} />
          </div>
          <div className="order-card-thumbs">
            {o.items.slice(0, 5).map((i) => <span key={i.id} className="order-line-img"><ProductImage url={i.product?.images[0]?.url} alt={i.name} /></span>)}
          </div>
          {open === o.id && (
            <div className="track-grid" style={{ gridTemplateColumns: "minmax(0, 1fr) minmax(0, 1fr)" }}>
              <OrderTimeline order={o} />
              <div><OrderLines order={o} /></div>
            </div>
          )}
          <div className="order-card-foot">
            <strong className="num">{lkr(o.total)}</strong>
            <button className="btn btn-quiet btn-sm" aria-expanded={open === o.id} onClick={() => setOpen(open === o.id ? null : o.id)}>
              {open === o.id ? "Hide details" : "View details"}<Icon name="chevronDown" size={16} />
            </button>
          </div>
        </article>
      ))}
    </div>
  );
}

function Wishlist() {
  const { ids } = useWishlist();
  const [items, setItems] = useState<Product[] | null>(null);
  useEffect(() => { api.wishlist().then(setItems).catch(() => setItems([])); }, []);
  if (!items) return <PageLoading />;
  const shown = items.filter((p) => ids.has(p.id));
  if (!shown.length) return <EmptyState icon="heart" title="Your wishlist is empty" action={<Link to="/shop" className="btn btn-primary">Browse jewellery</Link>}>Tap the heart on any piece to save it here.</EmptyState>;
  return <div className="pgrid" style={{ gridTemplateColumns: "repeat(auto-fill, minmax(200px, 1fr))" }}>{shown.map((p) => <ProductCard key={p.id} p={p} />)}</div>;
}

function TryOns() {
  const [items, setItems] = useState<SavedTryOn[] | null>(null);
  useEffect(() => { api.myTryOns().then(setItems).catch(() => setItems([])); }, []);
  if (!items) return <PageLoading />;
  if (!items.length) return <EmptyState icon="sparkle" title="No try-ons yet" action={<Link to="/shop?tryOn=1" className="btn btn-primary">Try something on</Link>}>Previews you create while signed in are saved here.</EmptyState>;
  return (
    <div className="tryon-grid">
      {items.map((t) => {
        const live = t.items.filter((i) => i.product.isActive);
        return (
          <article key={t.id} className="tryon-card">
            <a href={t.resultUrl} target="_blank" rel="noreferrer"><img src={t.resultUrl} alt={`Try-on of ${t.items.map((i) => i.product.name).join(", ")}`} /></a>
            <div className="tryon-card-body">
              {t.items.map((i) => i.product.isActive ? <Link key={i.product.id} to={`/product/${i.product.slug}`}>{i.product.name}</Link> : <span key={i.product.id} className="muted">{i.product.name}</span>)}
              <span className="muted">{shortDate(t.createdAt)}</span>
              {live.length > 0 && <Link to={`/try-on?products=${live.map((i) => i.product.id).join(",")}`} className="btn btn-quiet btn-sm" style={{ marginTop: 6 }}>Try again</Link>}
            </div>
          </article>
        );
      })}
    </div>
  );
}

function Profile() {
  const { user, setUser } = useAuth();
  const { show } = useToast();
  const [err, setErr] = useState("");
  const [pwErr, setPwErr] = useState("");
  const [busy, setBusy] = useState(false);

  const save = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    setErr(""); setBusy(true);
    try {
      setUser(await api.updateMe({ name: String(f.get("name")), phone: String(f.get("phone") || "") }));
      show("Details saved");
    } catch (e) { setErr((e as Error).message); } finally { setBusy(false); }
  };

  const changePw = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const form = e.currentTarget;
    const f = new FormData(form);
    setPwErr("");
    if (f.get("next") !== f.get("confirm")) { setPwErr("The new passwords don't match."); return; }
    try {
      await api.changePassword(String(f.get("current")), String(f.get("next")));
      form.reset();
      show("Password changed");
    } catch (e) { setPwErr((e as Error).message); }
  };

  return (
    <div className="stack" style={{ maxWidth: 560 }}>
      <form className="card form" onSubmit={save}>
        <h2 style={{ marginBottom: 0 }}>Your details</h2>
        <label className="field"><span className="field-label">Full name</span><input name="name" required minLength={2} defaultValue={user?.name} autoComplete="name" /></label>
        <label className="field"><span className="field-label">Email</span><input value={user?.email ?? ""} disabled /><span className="field-hint">Contact us to change your email.</span></label>
        <label className="field"><span className="field-label">Mobile number <span className="optional">(optional)</span></span><input name="phone" type="tel" pattern="0\d{9}" placeholder="07XXXXXXXX" defaultValue={user?.phone ?? ""} autoComplete="tel" /></label>
        {err && <p className="form-error" role="alert">{err}</p>}
        <button className="btn btn-primary" style={{ alignSelf: "flex-start" }} disabled={busy}>Save details</button>
      </form>
      <form className="card form" onSubmit={changePw}>
        <h2 style={{ marginBottom: 0 }}>Change password</h2>
        <PasswordInput name="current" label="Current password" autoComplete="current-password" />
        <PasswordInput name="next" label="New password" autoComplete="new-password" minLength={6} hint="At least 6 characters" />
        <PasswordInput name="confirm" label="Confirm new password" autoComplete="new-password" minLength={6} />
        {pwErr && <p className="form-error" role="alert">{pwErr}</p>}
        <button className="btn btn-secondary" style={{ alignSelf: "flex-start" }}>Change password</button>
      </form>
    </div>
  );
}

const tabs = [
  { key: "", label: "My orders", icon: "bag" as const, title: "My orders" },
  { key: "wishlist", label: "Wishlist", icon: "heart" as const, title: "Wishlist" },
  { key: "try-ons", label: "Saved try-ons", icon: "sparkle" as const, title: "Saved try-ons" },
  { key: "profile", label: "Profile", icon: "user" as const, title: "Profile" },
];

export default function Account() {
  const { tab = "" } = useParams();
  const { user, logout } = useAuth();
  const nav = useNavigate();
  const current = tabs.find((t) => t.key === tab);
  if (!current) return <Navigate to="/account" replace />;
  if (user?.role === "ADMIN") return <Navigate to="/admin" replace />;

  return (
    <div className="page">
      <div className="page-head"><h1>{current.title}</h1><p>Hi {user?.name.split(" ")[0]}.</p></div>
      <div className="account">
        <nav className="account-nav" aria-label="Account">
          {tabs.map((t) => <NavLink key={t.key} to={t.key ? `/account/${t.key}` : "/account"} end><Icon name={t.icon} size={18} />{t.label}</NavLink>)}
          <button onClick={() => { logout(); nav("/"); }}><Icon name="logout" size={18} />Sign out</button>
        </nav>
        <div>
          {tab === "" && <Orders />}
          {tab === "wishlist" && <Wishlist />}
          {tab === "try-ons" && <TryOns />}
          {tab === "profile" && <Profile />}
        </div>
      </div>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\BuildLook.tsx' @'
import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { api } from "../api/client";
import type { JewelleryType, Product } from "../api/types";
import { lkr } from "../api/format";
import { useCart } from "../context/CartContext";
import Icon from "../components/Icon";
import JewelIcon from "../components/JewelIcon";
import { EmptyState, PageLoading, Price, ProductImage } from "../components/ui";

const steps: { title: string; short: string; types: JewelleryType[] }[] = [
  { title: "Choose earrings", short: "Earrings", types: ["EARRINGS"] },
  { title: "Choose a necklace or chain", short: "Necklace", types: ["NECKLACE", "CHAIN", "LONG_CHAIN"] },
  { title: "Choose bangles or a bracelet", short: "Bangles", types: ["BANGLE", "BRACELET"] },
];

export default function BuildLook() {
  const nav = useNavigate();
  const { add } = useCart();
  const [step, setStep] = useState(0);
  const [options, setOptions] = useState<Product[] | null>(null);
  const [picked, setPicked] = useState<(Product | undefined)[]>([]);

  useEffect(() => {
    if (step >= steps.length) return;
    setOptions(null);
    Promise.all(steps[step].types.map((type) => api.products({ type, inStock: 1, tryOn: 1, limit: 24 })))
      .then((rs) => setOptions(rs.flatMap((r) => r.items)))
      .catch(() => setOptions([]));
  }, [step]);

  const chosen = picked.filter(Boolean) as Product[];
  const total = chosen.reduce((s, p) => s + (p.salePrice ?? p.price), 0);
  const pick = (p: Product) => setPicked((prev) => { const n = [...prev]; n[step] = n[step]?.id === p.id ? undefined : p; return n; });
  const finished = step >= steps.length;

  const tray = (
    <aside className="look-tray" aria-label="Your look">
      <h2>Your look</h2>
      {steps.map((s, i) => {
        const p = picked[i];
        return (
          <div key={s.short} className={`tray-slot ${p ? "" : "tray-slot-empty"}`}>
            <span className="tray-slot-img">{p ? <ProductImage url={p.images[0]?.url} alt="" type={p.jewelleryType} iconSize={28} /> : <JewelIcon type={s.types[0]} size={28} />}</span>
            <span className="tray-slot-text">
              {p ? <><strong>{p.name}</strong><span className="muted">{lkr(p.salePrice ?? p.price)}</span></> : <span className="muted">{s.short}: not chosen</span>}
            </span>
          </div>
        );
      })}
      <div className="tray-total"><span>Total</span><span className="num">{lkr(total)}</span></div>
    </aside>
  );

  if (finished) return (
    <div className="page">
      <div className="page-head"><h1>Your look</h1><p>Preview the full set with AI, or add it straight to your cart.</p></div>
      <div className="look">
        {chosen.length ? (
          <div className="stack">
            <div className="look-options">
              {chosen.map((p) => (
                <div key={p.id} className="look-option" style={{ cursor: "default" }}>
                  <span className="look-option-img"><ProductImage url={p.images[0]?.url} alt="" type={p.jewelleryType} /></span>
                  <Link to={`/product/${p.slug}`} className="look-option-name">{p.name}</Link>
                  <Price price={p.price} pricing={p} />
                </div>
              ))}
            </div>
            <div className="look-nav">
              <button className="btn btn-quiet" onClick={() => setStep(0)}><Icon name="edit" size={18} />Change pieces</button>
              <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
                <button className="btn btn-secondary" onClick={() => nav(`/try-on?products=${chosen.map((p) => p.id).join(",")}`)}><Icon name="sparkle" size={18} />Preview with AI</button>
                <button className="btn btn-primary" onClick={async () => { if (await add(chosen.map((p) => ({ productId: p.id, qty: 1 })), "Your look was added to the cart")) nav("/cart"); }}>Add all to cart · {lkr(total)}</button>
              </div>
            </div>
          </div>
        ) : (
          <EmptyState icon="sparkle" title="You haven't picked anything yet" action={<button className="btn btn-primary" onClick={() => setStep(0)}>Start again</button>}>
            Go back and choose at least one piece.
          </EmptyState>
        )}
        {tray}
      </div>
    </div>
  );

  return (
    <div className="page">
      <div className="page-head"><h1>Create your look</h1><p>Choose a piece at each step, or skip any you don't need.</p></div>
      <ol className="stepper" aria-label="Steps">
        {[...steps.map((s) => s.short), "Review"].map((label, i) => (
          <li key={label} className={step === i ? "is-current" : step > i ? "is-done" : ""} aria-current={step === i ? "step" : undefined}>
            <span className="step-dot">{step > i ? <Icon name="check" size={14} /> : i + 1}</span>{label}
          </li>
        ))}
      </ol>
      <div className="look">
        <div>
          <h2 style={{ fontSize: 28, marginBottom: 20 }}>{steps[step].title}</h2>
          {!options ? <PageLoading /> : !options.length ? (
            <p className="empty-note" style={{ textAlign: "left" }}>No pieces available for this step right now. Skip to the next one.</p>
          ) : (
            <div className="look-options">
              {options.map((p) => (
                <button key={p.id} className="look-option" aria-pressed={picked[step]?.id === p.id} onClick={() => pick(p)}>
                  <span className="look-option-img"><ProductImage url={p.images[0]?.url} alt="" type={p.jewelleryType} /></span>
                  <span className="look-option-name">{p.name}</span>
                  <Price price={p.price} pricing={p} />
                  <span className="look-option-check" aria-hidden="true"><Icon name="check" size={16} /></span>
                </button>
              ))}
            </div>
          )}
          <div className="look-nav">
            {step > 0 ? <button className="btn btn-quiet" onClick={() => setStep(step - 1)}><Icon name="arrowLeft" size={18} />Back</button> : <span />}
            <button className="btn btn-primary" onClick={() => setStep(step + 1)}>
              {picked[step] ? (step === steps.length - 1 ? "Review your look" : "Next") : "Skip this step"}<Icon name="chevronRight" size={18} />
            </button>
          </div>
        </div>
        {tray}
      </div>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\Cart.tsx' @'
import { Link } from "react-router-dom";
import { lkr } from "../api/format";
import { useCart } from "../context/CartContext";
import Icon from "../components/Icon";
import { EmptyState, PageLoading, Price, ProductImage, QtyStepper } from "../components/ui";

export function FreeDeliveryBar({ subtotal, over }: { subtotal: number; over: number | null }) {
  if (!over) return null;
  const left = over - subtotal;
  return (
    <div className="free-bar">
      <span>{left > 0 ? <>Add <strong>{lkr(left)}</strong> more for free delivery</> : <strong>You get free delivery</strong>}</span>
      <span className="free-bar-track"><span className="free-bar-fill" style={{ width: `${Math.min(100, (subtotal / over) * 100)}%` }} /></span>
    </div>
  );
}

export default function CartPage() {
  const { cart, setQty, remove } = useCart();
  if (!cart) return <PageLoading />;
  if (!cart.items.length) return (
    <div className="page">
      <EmptyState icon="bag" title="Your cart is empty" action={<Link to="/shop" className="btn btn-primary">Browse jewellery</Link>}>
        Pieces you add will show here.
      </EmptyState>
    </div>
  );

  const blocked = cart.items.some((i) => !i.inStock);
  const count = cart.items.reduce((s, i) => s + i.qty, 0);

  return (
    <div className="page">
      <div className="page-head"><h1>Your cart</h1><p>{count} {count === 1 ? "piece" : "pieces"}</p></div>
      <div className="cart">
        <div className="cart-lines">
          {cart.items.map((i) => (
            <div key={i.id} className="cart-line">
              <Link to={`/product/${i.product.slug}`} className="cart-line-img" tabIndex={-1} aria-hidden="true">
                <ProductImage url={i.product.images[0]?.url} alt="" type={i.product.jewelleryType} />
              </Link>
              <div className="cart-line-info">
                <Link to={`/product/${i.product.slug}`} className="cart-line-name">{i.product.name}</Link>
                <Price price={i.product.price} pricing={i.product} />
                {!i.inStock && <span className="cart-line-warn">{i.product.stock ? `Only ${i.product.stock} left. Lower the quantity to continue.` : "Sold out. Remove it to continue."}</span>}
                <div className="cart-line-controls">
                  <QtyStepper value={i.qty} max={Math.max(1, Math.min(i.product.stock, 20))} onChange={(n) => setQty(i.productId, n)} label={`Quantity of ${i.product.name}`} />
                  <button className="btn-link" onClick={() => remove(i.productId)} style={{ fontSize: 14 }}>Remove</button>
                </div>
              </div>
              <span className="cart-line-total">{lkr(i.lineTotal)}</span>
            </div>
          ))}
        </div>

        <aside className="summary" aria-label="Order summary">
          <h2>Summary</h2>
          <div className="summary-row"><span>Subtotal</span><span>{lkr(cart.subtotal)}</span></div>
          <div className="summary-row"><span>Delivery</span><span>{cart.deliveryFee ? lkr(cart.deliveryFee) : "Free"}</span></div>
          <FreeDeliveryBar subtotal={cart.subtotal} over={cart.freeDeliveryOver} />
          <div className="summary-row summary-total"><span>Total</span><span>{lkr(cart.total)}</span></div>
          <p className="summary-note">Store pickup is free. You'll choose at checkout.</p>
          {blocked ? (
            <button className="btn btn-primary btn-lg btn-block" disabled>Checkout</button>
          ) : (
            <Link to="/checkout" className="btn btn-primary btn-lg btn-block"><Icon name="lock" size={18} />Checkout</Link>
          )}
          <Link to="/shop" className="btn btn-quiet btn-block">Continue shopping</Link>
        </aside>
      </div>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\Checkout.tsx' @'
import { FormEvent, useEffect, useState } from "react";
import { Link, Navigate, useNavigate } from "react-router-dom";
import { api, ApiError } from "../api/client";
import type { DeliveryMethod, PaymentMethod } from "../api/types";
import { lkr, paymentLabel } from "../api/format";
import { useCart } from "../context/CartContext";
import { useAuth } from "../context/AuthContext";
import { useSettings } from "../context/SettingsContext";
import Icon, { IconName } from "../components/Icon";
import { PageLoading, ProductImage } from "../components/ui";
import { FreeDeliveryBar } from "./Cart";

const paymentInfo: Record<PaymentMethod, { icon: IconName; note: string }> = {
  COD: { icon: "cash", note: "Pay in cash when your order arrives." },
  BANK_TRANSFER: { icon: "bank", note: "Transfer the total and send us the slip on WhatsApp." },
  ONLINE: { icon: "card", note: "Pay securely by card." },
};

export default function Checkout() {
  const nav = useNavigate();
  const { cart, refresh } = useCart();
  const { user } = useAuth();
  const s = useSettings();
  const methods = (["COD", "BANK_TRANSFER", "ONLINE"] as PaymentMethod[]).filter((m) => ({ COD: s.codEnabled, BANK_TRANSFER: s.bankEnabled, ONLINE: s.onlineEnabled })[m]);
  const [delivery, setDelivery] = useState<DeliveryMethod>("DELIVERY");
  const [payment, setPayment] = useState<PaymentMethod | "">("");
  const [err, setErr] = useState("");
  const [badField, setBadField] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => { if (!payment && methods.length) setPayment(methods[0]); }, [methods, payment]);

  if (!cart) return <PageLoading />;
  if (!cart.items.length && !busy) return <Navigate to="/cart" replace />;

  const fee = delivery === "DELIVERY" ? cart.deliveryFee : 0;
  const total = cart.subtotal + fee;

  const submit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setErr(""); setBadField("");
    const body = Object.fromEntries(new FormData(e.currentTarget));
    setBusy(true);
    try {
      const order = await api.placeOrder(body);
      await refresh();
      nav(`/order/${order.orderNo}`, { state: order, replace: true });
    } catch (e) {
      setBusy(false);
      setErr((e as Error).message);
      if (e instanceof ApiError && e.field) {
        setBadField(e.field);
        document.querySelector<HTMLInputElement>(`[name="${e.field}"]`)?.focus();
      } else window.scrollTo({ top: 0, behavior: "smooth" });
    }
  };
  const invalid = (name: string) => (badField === name ? { "aria-invalid": true as const } : {});

  return (
    <div className="page">
      <div className="page-head"><h1>Checkout</h1><p>{user ? `Signed in as ${user.email}` : <>Checking out as a guest. <Link to="/login" state={{ from: "/checkout" }}>Sign in</Link> to track orders in your account.</>}</p></div>
      <form className="cart" onSubmit={submit} noValidate={false}>
        <div className="checkout-sections">
          {err && <p className="form-error" role="alert">{err}</p>}

          <section className="checkout-section" aria-labelledby="co-details">
            <h2 id="co-details"><span className="checkout-num">1</span>Your details</h2>
            <div className="form-grid">
              <label className="field span-2"><span className="field-label">Full name</span><input name="fullName" required minLength={2} autoComplete="name" defaultValue={user?.name ?? ""} {...invalid("fullName")} /></label>
              <label className="field"><span className="field-label">Mobile number</span><input name="mobile" type="tel" required pattern="0\d{9}" placeholder="07XXXXXXXX" autoComplete="tel" inputMode="tel" defaultValue={user?.phone ?? ""} {...invalid("mobile")} /><span className="field-hint">We'll call or message about your order</span></label>
              <label className="field"><span className="field-label">WhatsApp number <span className="optional">(optional)</span></span><input name="whatsapp" type="tel" placeholder="If different from mobile" inputMode="tel" /></label>
              <label className="field span-2"><span className="field-label">Email <span className="optional">(optional)</span></span><input name="email" type="email" autoComplete="email" defaultValue={user?.email ?? ""} {...invalid("email")} /></label>
            </div>
          </section>

          <section className="checkout-section" aria-labelledby="co-delivery">
            <h2 id="co-delivery"><span className="checkout-num">2</span>Delivery</h2>
            <fieldset className="fieldset">
              <legend className="sr-only">Delivery method</legend>
              <div className="choices choices-2">
                <label className="choice">
                  <input type="radio" name="deliveryMethod" value="DELIVERY" checked={delivery === "DELIVERY"} onChange={() => setDelivery("DELIVERY")} />
                  <span className="choice-dot" aria-hidden="true" />
                  <span className="choice-body"><span className="choice-title"><Icon name="truck" size={18} />Deliver to me</span><span className="choice-note">{cart.deliveryFee ? lkr(cart.deliveryFee) : "Free"} · islandwide</span></span>
                </label>
                {s.pickupEnabled && (
                  <label className="choice">
                    <input type="radio" name="deliveryMethod" value="PICKUP" checked={delivery === "PICKUP"} onChange={() => setDelivery("PICKUP")} />
                    <span className="choice-dot" aria-hidden="true" />
                    <span className="choice-body"><span className="choice-title"><Icon name="store" size={18} />Store pickup</span><span className="choice-note">Free{s.address ? ` · ${s.address}` : ""}</span></span>
                  </label>
                )}
              </div>
            </fieldset>
            {delivery === "DELIVERY" && (
              <div className="form-grid">
                <label className="field span-2"><span className="field-label">Address</span><textarea name="address" required rows={2} autoComplete="street-address" {...invalid("address")} /></label>
                <label className="field"><span className="field-label">City</span><input name="city" required autoComplete="address-level2" {...invalid("city")} /></label>
                <label className="field"><span className="field-label">Postal code <span className="optional">(optional)</span></span><input name="postalCode" autoComplete="postal-code" inputMode="numeric" /></label>
              </div>
            )}
            <label className="field"><span className="field-label">Order note <span className="optional">(optional)</span></span><textarea name="note" rows={2} placeholder="Gift wrapping, a delivery time, anything we should know" /></label>
          </section>

          <section className="checkout-section" aria-labelledby="co-payment">
            <h2 id="co-payment"><span className="checkout-num">3</span>Payment</h2>
            {methods.length ? (
              <fieldset className="fieldset">
                <legend className="sr-only">Payment method</legend>
                <div className="choices">
                  {methods.map((m) => (
                    <label key={m} className="choice">
                      <input type="radio" name="paymentMethod" value={m} checked={payment === m} onChange={() => setPayment(m)} required />
                      <span className="choice-dot" aria-hidden="true" />
                      <span className="choice-body"><span className="choice-title"><Icon name={paymentInfo[m].icon} size={18} />{paymentLabel[m]}</span><span className="choice-note">{paymentInfo[m].note}</span></span>
                    </label>
                  ))}
                </div>
              </fieldset>
            ) : <p className="form-error">No payment methods are available right now. Contact the shop to order.</p>}
            {payment === "BANK_TRANSFER" && s.bankDetails && <div className="bank-box"><strong>Bank details</strong>{"\n"}{s.bankDetails}</div>}
          </section>
        </div>

        <aside className="summary" aria-label="Order summary">
          <h2>Your order</h2>
          <div className="summary-items">
            {cart.items.map((i) => (
              <div key={i.id} className="summary-item">
                <span className="summary-item-img"><ProductImage url={i.product.images[0]?.url} alt="" type={i.product.jewelleryType} /><span className="summary-item-qty" aria-label={`Quantity ${i.qty}`}>{i.qty}</span></span>
                <span>{i.product.name}</span>
                <span className="num">{lkr(i.lineTotal)}</span>
              </div>
            ))}
          </div>
          <div className="summary-row"><span>Subtotal</span><span>{lkr(cart.subtotal)}</span></div>
          <div className="summary-row"><span>Delivery</span><span>{fee ? lkr(fee) : "Free"}</span></div>
          {delivery === "DELIVERY" && <FreeDeliveryBar subtotal={cart.subtotal} over={cart.freeDeliveryOver} />}
          <div className="summary-row summary-total"><span>Total</span><span>{lkr(total)}</span></div>
          <button className="btn btn-primary btn-lg btn-block" disabled={busy || !methods.length}>{busy ? "Placing order…" : `Place order · ${lkr(total)}`}</button>
          <p className="summary-note">We'll confirm your order by phone or WhatsApp before it's sent.</p>
        </aside>
      </form>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\Home.tsx' @'
import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../api/client";
import type { Category, Product } from "../api/types";
import { lkr } from "../api/format";
import { useSettings } from "../context/SettingsContext";
import ProductCard from "../components/ProductCard";
import Icon from "../components/Icon";
import JewelIcon from "../components/JewelIcon";
import { ProductImage } from "../components/ui";

function ProductRow({ items, loading, emptyText }: { items: Product[]; loading: boolean; emptyText: string }) {
  if (loading) return <div className="pgrid">{[0, 1, 2, 3].map((i) => <div key={i} className="skeleton skeleton-card" />)}</div>;
  if (!items.length) return <p className="empty-note">{emptyText}</p>;
  return <div className="pgrid">{items.map((p) => <ProductCard key={p.id} p={p} />)}</div>;
}

export default function Home() {
  const s = useSettings();
  const [cats, setCats] = useState<Category[]>([]);
  const [fresh, setFresh] = useState<Product[]>([]);
  const [sale, setSale] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      api.categories().then(setCats),
      api.products({ newArrivals: 1, limit: 8 }).then(async (r) => {
        // Fall back to the newest pieces when nothing is marked as a new arrival.
        setFresh(r.items.length ? r.items : (await api.products({ limit: 8 })).items);
      }),
      api.products({ onSale: 1, limit: 4 }).then((r) => setSale(r.items)),
    ]).catch(() => undefined).finally(() => setLoading(false));
  }, []);

  const heroPick = fresh.find((p) => p.tryOnEnabled) ?? fresh[0];

  return (
    <>
      <section className="hero">
        <div className="hero-inner">
          <div className="hero-copy">
            <h1>Discover your perfect jewellery</h1>
            <p>Earrings, bangles, chains, necklaces, rings and more. See any piece on a model or on your own photo before you order.</p>
            <div className="hero-actions">
              <Link to="/shop" className="btn btn-gold btn-lg">Shop now</Link>
              <Link to={heroPick?.tryOnEnabled ? `/try-on?products=${heroPick.id}` : "/shop?tryOn=1"} className="btn btn-outline-light btn-lg">
                <Icon name="sparkle" size={18} />Try it on with AI
              </Link>
            </div>
          </div>
          <div className="hero-visual" aria-hidden={!heroPick}>
            <div className="hero-arch">
              {heroPick?.images[0] ? <img src={heroPick.images[0].url} alt="" /> : <JewelIcon type={heroPick?.jewelleryType ?? "EARRINGS"} size={140} strokeWidth={1} />}
            </div>
            <span className="hero-chip"><Icon name="sparkle" size={14} />AI preview</span>
            {heroPick && (
              <Link to={`/product/${heroPick.slug}`} className="hero-card">
                <span className="hero-card-img"><ProductImage url={heroPick.images[0]?.url} alt="" type={heroPick.jewelleryType} iconSize={34} /></span>
                <span>
                  <span className="hero-card-name">{heroPick.name}</span><br />
                  <span className="muted">{lkr(heroPick.salePrice ?? heroPick.price)}</span>
                </span>
              </Link>
            )}
          </div>
        </div>
      </section>

      <section className="home-section" aria-labelledby="cat-title">
        <div className="section-head">
          <h2 id="cat-title">Shop by category</h2>
          <Link to="/shop">View all</Link>
        </div>
        <div className="cat-grid">
          {cats.map((c) => (
            <Link key={c.id} to={`/shop/${c.slug}`} className="cat-tile">
              <span className="cat-circle">{c.imageUrl ? <img src={c.imageUrl} alt="" /> : <JewelIcon slug={c.slug} size={52} />}</span>
              <span className="cat-name">{c.name}</span>
            </Link>
          ))}
        </div>
      </section>

      <section className="home-section" aria-labelledby="new-title">
        <div className="section-head">
          <h2 id="new-title">New arrivals</h2>
          <Link to="/shop?newArrivals=1">See all new pieces</Link>
        </div>
        <ProductRow items={fresh} loading={loading} emptyText="New pieces are on their way. Check back soon." />
      </section>

      {sale.length > 0 && (
        <section className="home-section" aria-labelledby="sale-title">
          <div className="section-head">
            <h2 id="sale-title">On offer now</h2>
            <Link to="/shop?onSale=1">See all offers</Link>
          </div>
          <ProductRow items={sale} loading={false} emptyText="" />
        </section>
      )}

      <section className="home-section" aria-labelledby="look-title">
        <div className="look-band" style={{ marginTop: 8 }}>
          <div className="look-copy">
            <h2 id="look-title">Create your look</h2>
            <p>Pick earrings, a necklace and bangles, then see the whole set on an AI model before you order. Mix any pieces you like.</p>
            <Link to="/build-look" className="btn btn-primary btn-lg">Start your look</Link>
          </div>
          <ol className="look-steps">
            <li className="look-step"><span className="look-step-num">1</span><span className="look-step-art"><JewelIcon type="EARRINGS" size={46} /></span><span className="look-step-name">Choose earrings</span></li>
            <li className="look-step"><span className="look-step-num">2</span><span className="look-step-art"><JewelIcon type="NECKLACE" size={46} /></span><span className="look-step-name">Choose a necklace</span></li>
            <li className="look-step"><span className="look-step-num">3</span><span className="look-step-art"><JewelIcon type="BANGLE" size={46} /></span><span className="look-step-name">Choose bangles</span></li>
            <li className="look-step look-step-final"><span className="look-step-num"><Icon name="sparkle" size={16} /></span><span className="look-step-art"><Icon name="model" size={40} /></span><span className="look-step-name">See it on with AI</span></li>
          </ol>
        </div>
      </section>

      <section className="trust" aria-label="Why shop with us">
        <div className="trust-item"><span className="trust-icon"><Icon name="truck" /></span><span><strong>Islandwide delivery</strong><span>{s.freeDeliveryOver ? `Free over ${lkr(s.freeDeliveryOver)}, otherwise ${lkr(s.deliveryFee)}` : `Delivered to your door for ${lkr(s.deliveryFee)}`}</span></span></div>
        {s.codEnabled && <div className="trust-item"><span className="trust-icon"><Icon name="cash" /></span><span><strong>Cash on delivery</strong><span>{s.bankEnabled ? "Or pay by bank transfer" : "Pay when it arrives"}</span></span></div>}
        <div className="trust-item"><span className="trust-icon"><Icon name="chat" /></span><span><strong>Help on WhatsApp</strong><span>Ask about any piece or order</span></span></div>
        {s.pickupEnabled && <div className="trust-item"><span className="trust-icon"><Icon name="store" /></span><span><strong>Store pickup</strong><span>{s.address ? `Collect from ${s.address}` : "Collect from our shop"}</span></span></div>}
      </section>
    </>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\Info.tsx' @'
import { Link } from "react-router-dom";
import { lkr, phoneLink, whatsappLink } from "../api/format";
import { useSettings } from "../context/SettingsContext";
import Icon from "../components/Icon";
import JewelIcon from "../components/JewelIcon";

// Text marked [LIKE THIS] is a placeholder for the shop to replace with its own details.

export function About() {
  const s = useSettings();
  return (
    <div className="page page-narrow">
      <div className="page-head"><h1>About {s.shopName}</h1><p>{s.tagline}</p></div>
      <div className="prose">
        <p>[Tell your story here: when the shop started, who runs it and what kind of jewellery you love to sell.]</p>
        <h2>See it on before you buy</h2>
        <p>Choosing jewellery online is hard when you can't hold it up to yourself. That's why every piece that supports it can be tried on with AI, either on one of our models or on your own photo, before you order.</p>
        <h2>Order your way</h2>
        <p>Pay by cash on delivery or bank transfer, have it delivered anywhere in Sri Lanka, or collect it from our shop. If you have a question about a piece, message us on WhatsApp and we'll help.</p>
        <p><Link to="/shop" className="btn btn-primary">Browse jewellery</Link></p>
      </div>
    </div>
  );
}

export function Contact() {
  const s = useSettings();
  const cards = [
    s.whatsapp && { href: whatsappLink(s.whatsapp, "Hi, I have a question."), icon: "chat" as const, title: "WhatsApp", text: s.whatsapp, external: true },
    s.phone && { href: phoneLink(s.phone), icon: "phone" as const, title: "Call us", text: s.phone },
    s.email && { href: `mailto:${s.email}`, icon: "mail" as const, title: "Email", text: s.email },
  ].filter(Boolean) as { href: string; icon: "chat" | "phone" | "mail"; title: string; text: string; external?: boolean }[];

  return (
    <div className="page page-narrow">
      <div className="page-head"><h1>Contact us</h1><p>Questions about a piece, an order or a custom request? We're happy to help.</p></div>
      <div className="contact-grid">
        {cards.map((c) => (
          <a key={c.title} href={c.href} className="contact-card" {...(c.external ? { target: "_blank", rel: "noreferrer" } : {})}>
            <span className="contact-card-icon"><Icon name={c.icon} /></span>
            <strong>{c.title}</strong><span>{c.text}</span>
          </a>
        ))}
        <div className="contact-card">
          <span className="contact-card-icon"><Icon name="pin" /></span>
          <strong>Visit the shop</strong><span>{s.address || "[Shop address]"}</span>
        </div>
        <div className="contact-card">
          <span className="contact-card-icon"><Icon name="clock" /></span>
          <strong>Opening hours</strong><span>[Days and hours]</span>
        </div>
      </div>
      {!cards.length && <p className="muted" style={{ marginTop: 20 }}>Contact details will appear here once they're added in the admin settings.</p>}
    </div>
  );
}

export function Delivery() {
  const s = useSettings();
  return (
    <div className="page page-narrow">
      <div className="page-head"><h1>Delivery and returns</h1></div>
      <div className="prose">
        <h2>Delivery</h2>
        <p>We deliver anywhere in Sri Lanka for {lkr(s.deliveryFee)}{s.freeDeliveryOver ? `, and free on orders over ${lkr(s.freeDeliveryOver)}` : ""}. Most orders arrive within [X–Y] working days after we confirm them.</p>
        {s.pickupEnabled && <p>Prefer to collect? Choose store pickup at checkout. It's free, and we'll message you when your order is ready{s.address ? ` at ${s.address}` : ""}.</p>}
        <h2>Payment</h2>
        <p>{[s.codEnabled && "cash on delivery", s.bankEnabled && "bank transfer", s.onlineEnabled && "online card payment"].filter(Boolean).join(", ").replace(/^./, (c) => c.toUpperCase())}. For bank transfers, use your order number as the reference and send us the slip on WhatsApp.</p>
        <h2>Returns and exchanges</h2>
        <p>[Your return policy: how many days customers have, what condition items must be in, and which items can't be returned, for example earrings for hygiene reasons.]</p>
        <p>To start a return, <Link to="/contact">contact us</Link> with your order number.</p>
      </div>
    </div>
  );
}

const faqs = [
  { id: "order", q: "How do I place an order?", a: <>Add pieces to your cart and go to checkout. You can order as a guest or sign in. We'll contact you to confirm the order before it's sent.</> },
  { id: "try-on", q: "How does AI try-on work?", a: <>On any piece marked “Try on”, choose an AI model or upload a clear, front-facing photo of yourself. Our AI places the piece where it's worn, for example earrings on the earlobes and necklaces around the neck, and shows you a preview in a few seconds. Previews show how a piece may look; size and colour can vary slightly in real life.</> },
  { id: "photo", q: "What happens to my photo?", a: <>Your photo is only used to create your preview. If you're signed in, the preview is saved to your account so you can see it again.</> },
  { id: "look", q: "Can I try on a full set?", a: <>Yes. Use <Link to="/build-look">Create your look</Link> to pick earrings, a necklace and bangles, then preview them together.</> },
  { id: "track", q: "How do I track my order?", a: <>Go to <Link to="/track">Track your order</Link> and enter your order number and mobile number.</> },
  { id: "pay", q: "How can I pay?", a: <>Cash on delivery or bank transfer. See <Link to="/delivery">Delivery and returns</Link> for details.</> },
];

export function Faq() {
  return (
    <div className="page page-narrow">
      <div className="page-head"><h1>Questions and answers</h1></div>
      <div className="faq">
        {faqs.map((f) => (
          <details key={f.id} id={f.id} open={typeof window !== "undefined" && window.location.hash === `#${f.id}`}>
            <summary>{f.q}<Icon name="chevronDown" /></summary>
            <div>{f.a}</div>
          </details>
        ))}
      </div>
    </div>
  );
}

export function NotFound() {
  return (
    <div className="not-found">
      <span className="not-found-art"><JewelIcon type="OTHER" size={96} strokeWidth={1.2} /></span>
      <h1>Page not found</h1>
      <p>The page you're looking for doesn't exist or has moved.</p>
      <div className="card-actions"><Link to="/" className="btn btn-primary">Go to home</Link><Link to="/shop" className="btn btn-quiet">Browse jewellery</Link></div>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\Login.tsx' @'
import { FormEvent, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import AuthShell from "../components/AuthShell";
import PasswordInput from "../components/PasswordInput";

export default function Login() {
  const { login } = useAuth();
  const nav = useNavigate();
  const from = (useLocation().state as { from?: string } | null)?.from ?? "/";
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  const submit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    setBusy(true); setErr("");
    try {
      const u = await login(String(f.get("email")), String(f.get("password")));
      nav(u.role === "ADMIN" ? "/admin" : from, { replace: true });
    } catch (e) {
      setErr((e as Error).message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <AuthShell
      title="Sign in"
      subtitle="Welcome back. Sign in to see your orders and saved try-ons."
      aside={<><h2>See it on before you buy</h2><p>Try any piece on a model or your own photo, then order in a few taps.</p></>}
    >
      <form onSubmit={submit} className="form" noValidate={false}>
        <label className="field">
          <span className="field-label">Email</span>
          <input name="email" type="email" required autoComplete="email" />
        </label>
        <PasswordInput name="password" label="Password" autoComplete="current-password" />
        {err && <p className="form-error" role="alert">{err}</p>}
        <button className="btn btn-primary btn-block" disabled={busy}>{busy ? "Signing in…" : "Sign in"}</button>
      </form>
      <p className="auth-switch">New here? <Link to="/register" state={{ from }}>Create an account</Link></p>
      <p className="auth-switch"><Link to="/">Continue as guest</Link></p>
    </AuthShell>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\OrderConfirmation.tsx' @'
import { Link, useLocation, useParams } from "react-router-dom";
import type { Order } from "../api/types";
import { lkr, whatsappLink } from "../api/format";
import { useSettings } from "../context/SettingsContext";
import { useAuth } from "../context/AuthContext";
import Icon from "../components/Icon";
import { OrderLines } from "../components/OrderView";

export default function OrderConfirmation() {
  const { orderNo } = useParams();
  const order = useLocation().state as Order | undefined;
  const s = useSettings();
  const { user } = useAuth();
  const contact = s.whatsapp || s.phone;
  const msg = `Hi, about my order ${orderNo}${order ? ` (${lkr(order.total)})` : ""}.`;

  return (
    <div className="page">
      <div className="confirm">
        <section className="confirm-hero">
          <span className="confirm-icon"><Icon name="check" size={36} /></span>
          <h1>Thank you for your order</h1>
          <p className="order-no">Your order number<strong>{orderNo}</strong></p>
          <p className="muted">We'll contact you{order ? ` on ${order.mobile}` : ""} to confirm it. Keep your order number to track it.</p>
          <div className="card-actions" style={{ marginTop: 8 }}>
            <Link to={`/track?orderNo=${orderNo}${order ? `&mobile=${order.mobile}` : ""}`} className="btn btn-primary">Track order</Link>
            {contact && <a href={whatsappLink(contact, msg)} target="_blank" rel="noreferrer" className="btn btn-secondary"><Icon name="chat" size={18} />WhatsApp us</a>}
          </div>
        </section>

        {order?.paymentMethod === "BANK_TRANSFER" && (
          <section className="card" aria-labelledby="pay-title">
            <h2 id="pay-title">Complete your payment</h2>
            <p style={{ marginBottom: 12 }}>Transfer <strong>{lkr(order.total)}</strong> and use <strong>{orderNo}</strong> as the reference. Then send the slip to us on WhatsApp.</p>
            {s.bankDetails ? <div className="bank-box">{s.bankDetails}</div> : <p className="muted">We'll send you our bank details when we confirm your order.</p>}
          </section>
        )}

        {order && (
          <section className="card" aria-labelledby="sum-title">
            <h2 id="sum-title">Order summary</h2>
            <OrderLines order={order} />
          </section>
        )}

        <div className="card-actions">
          {user?.role === "CUSTOMER" && <Link to="/account" className="btn btn-quiet">View my orders</Link>}
          <Link to="/shop" className="btn btn-quiet">Continue shopping</Link>
        </div>
      </div>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\ProductDetails.tsx' @'
import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { api } from "../api/client";
import type { Product } from "../api/types";
import { typeLabel } from "../api/format";
import { useCart } from "../context/CartContext";
import { useWishlist } from "../context/WishlistContext";
import { useToast } from "../context/ToastContext";
import ProductCard from "../components/ProductCard";
import Icon from "../components/Icon";
import { Breadcrumb, EmptyState, PageLoading, Price, ProductImage, QtyStepper } from "../components/ui";

export default function ProductDetails() {
  const { slug } = useParams();
  const { add } = useCart();
  const { has, toggle } = useWishlist();
  const { show } = useToast();
  const [p, setP] = useState<Product | null>(null);
  const [related, setRelated] = useState<Product[]>([]);
  const [missing, setMissing] = useState(false);
  const [img, setImg] = useState(0);
  const [qty, setQty] = useState(1);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    setP(null); setMissing(false); setImg(0); setQty(1);
    api.product(slug!).then(setP).catch(() => setMissing(true));
    api.related(slug!).then(setRelated).catch(() => setRelated([]));
  }, [slug]);

  if (missing) return (
    <div className="page">
      <EmptyState icon="search" title="This piece isn't available" action={<Link to="/shop" className="btn btn-primary">Browse jewellery</Link>}>
        It may have sold out or been removed.
      </EmptyState>
    </div>
  );
  if (!p) return <PageLoading />;

  const images = p.images;
  const saved = has(p.id);
  const soldOut = p.stock <= 0;
  const low = !soldOut && p.stock <= 3;

  const addToCart = async () => {
    setBusy(true);
    await add([{ productId: p.id, qty }], `${p.name} added to cart`);
    setBusy(false);
  };

  const share = async () => {
    const url = window.location.href;
    try {
      if (navigator.share) await navigator.share({ title: p.name, url });
      else { await navigator.clipboard.writeText(url); show("Link copied"); }
    } catch { /* closed the share sheet */ }
  };

  return (
    <div className="page">
      <Breadcrumb items={[{ to: "/", label: "Home" }, { to: "/shop", label: "Shop" }, ...(p.category ? [{ to: `/shop/${p.category.slug}`, label: p.category.name }] : []), { label: p.name }]} />

      <div className="pdp">
        <div className="gallery">
          <div className="gallery-main">
            <ProductImage url={images[img]?.url} alt={`${p.name}${images.length > 1 ? `, photo ${img + 1} of ${images.length}` : ""}`} type={p.jewelleryType} iconSize={160} />
            {images.length > 1 && (
              <>
                <button className="icon-btn gallery-nav gallery-prev" aria-label="Previous photo" onClick={() => setImg((img - 1 + images.length) % images.length)}><Icon name="chevronLeft" /></button>
                <button className="icon-btn gallery-nav gallery-next" aria-label="Next photo" onClick={() => setImg((img + 1) % images.length)}><Icon name="chevronRight" /></button>
              </>
            )}
          </div>
          {images.length > 1 && (
            <div className="thumbs">
              {images.map((im, i) => (
                <button key={im.id} className="thumb" aria-current={i === img} aria-label={`Show photo ${i + 1}`} onClick={() => setImg(i)}>
                  <ProductImage url={im.url} alt="" type={p.jewelleryType} iconSize={32} />
                </button>
              ))}
            </div>
          )}
        </div>

        <div className="pdp-info">
          <div className="pdp-meta">
            <span>Code {p.code}</span>
            {soldOut ? <span className="stock stock-out"><Icon name="close" size={16} />Sold out</span>
              : low ? <span className="stock stock-low"><Icon name="alert" size={16} />Only {p.stock} left</span>
              : <span className="stock stock-in"><Icon name="check" size={16} />In stock</span>}
          </div>
          <h1>{p.name}</h1>
          <Price price={p.price} pricing={p} size="lg" />
          {p.offerTitle && <p className="pdp-offer">{p.offerTitle}: {p.offerPercent}% off</p>}
          {p.description && <p className="pdp-desc">{p.description}</p>}

          <div className="pdp-buy">
            <div className="pdp-buy-row">
              {!soldOut && <QtyStepper value={qty} max={Math.min(p.stock, 20)} onChange={setQty} />}
              <button className="btn btn-primary btn-lg" disabled={soldOut || busy} onClick={addToCart}>
                {soldOut ? "Sold out" : busy ? "Adding…" : "Add to cart"}
              </button>
            </div>
            {p.tryOnEnabled && (
              <Link to={`/try-on?products=${p.id}`} className="try-cta">
                <span className="try-cta-icon"><Icon name="sparkle" size={22} /></span>
                <span><strong>Try it on with AI</strong><span>See it on a model or on your own photo</span></span>
                <Icon name="chevronRight" />
              </Link>
            )}
          </div>

          <div className="pdp-actions">
            <button className="btn btn-quiet btn-sm" aria-pressed={saved} onClick={() => toggle(p.id, p.name)}>
              <Icon name="heart" size={18} filled={saved} />{saved ? "Saved" : "Save to wishlist"}
            </button>
            <button className="btn btn-quiet btn-sm" onClick={share}><Icon name="share" size={18} />Share</button>
          </div>

          <dl className="pdp-details">
            <dt>Type</dt><dd>{typeLabel[p.jewelleryType]}</dd>
            {p.category && <><dt>Category</dt><dd><Link to={`/shop/${p.category.slug}`}>{p.category.name}</Link></dd></>}
            {p.style && <><dt>Style</dt><dd>{p.style}</dd></>}
            {p.colour && <><dt>Colour</dt><dd>{p.colour}</dd></>}
          </dl>
        </div>
      </div>

      {related.length > 0 && (
        <section className="related" aria-labelledby="related-title">
          <div className="section-head"><h2 id="related-title">You may also like</h2>{p.category && <Link to={`/shop/${p.category.slug}`}>More {p.category.name.toLowerCase()}</Link>}</div>
          <div className="pgrid">{related.map((r) => <ProductCard key={r.id} p={r} />)}</div>
        </section>
      )}
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\Register.tsx' @'
import { FormEvent, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import AuthShell from "../components/AuthShell";
import PasswordInput from "../components/PasswordInput";

export default function Register() {
  const { register } = useAuth();
  const nav = useNavigate();
  const from = (useLocation().state as { from?: string } | null)?.from ?? "/";
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  const submit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    setBusy(true); setErr("");
    try {
      await register({
        name: String(f.get("name")),
        email: String(f.get("email")),
        phone: String(f.get("phone") || "") || undefined,
        password: String(f.get("password")),
      });
      nav(from, { replace: true });
    } catch (e) {
      setErr((e as Error).message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <AuthShell
      title="Create your account"
      subtitle="Track orders, keep a wishlist and save your AI try-ons."
      aside={<><h2>Your jewellery, your way</h2><p>Mix earrings, necklaces and bangles into a full look, and see it on before you order.</p></>}
    >
      <form onSubmit={submit} className="form">
        <label className="field">
          <span className="field-label">Full name</span>
          <input name="name" required minLength={2} autoComplete="name" />
        </label>
        <label className="field">
          <span className="field-label">Email</span>
          <input name="email" type="email" required autoComplete="email" />
        </label>
        <label className="field">
          <span className="field-label">Mobile number <span className="optional">(optional)</span></span>
          <input name="phone" type="tel" placeholder="07XXXXXXXX" pattern="0\d{9}" autoComplete="tel" />
        </label>
        <PasswordInput name="password" label="Password" autoComplete="new-password" minLength={6} hint="At least 6 characters" />
        {err && <p className="form-error" role="alert">{err}</p>}
        <button className="btn btn-primary btn-block" disabled={busy}>{busy ? "Creating account…" : "Create account"}</button>
      </form>
      <p className="auth-switch">Already have an account? <Link to="/login" state={{ from }}>Sign in</Link></p>
    </AuthShell>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\Shop.tsx' @'
import { FormEvent, useEffect, useMemo, useState } from "react";
import { Link, useParams, useSearchParams } from "react-router-dom";
import { api } from "../api/client";
import type { Category, Paged, Product, ProductFilters } from "../api/types";
import ProductCard from "../components/ProductCard";
import Icon from "../components/Icon";
import { Breadcrumb, EmptyState, ErrorState, Pagination } from "../components/ui";

const sorts = [
  { v: "new", label: "Newest" },
  { v: "price_asc", label: "Price: low to high" },
  { v: "price_desc", label: "Price: high to low" },
  { v: "name", label: "Name A–Z" },
];

export default function Shop() {
  const { category } = useParams();
  const [sp, setSp] = useSearchParams();
  const [data, setData] = useState<Paged<Product> | null>(null);
  const [cats, setCats] = useState<Category[]>([]);
  const [facets, setFacets] = useState<ProductFilters | null>(null);
  const [err, setErr] = useState("");
  const [open, setOpen] = useState(false);
  const [reload, setReload] = useState(0);

  useEffect(() => {
    api.categories().then(setCats).catch(() => undefined);
    api.productFilters().then(setFacets).catch(() => undefined);
  }, []);

  useEffect(() => {
    setErr("");
    setData(null);
    api.products({ category, ...Object.fromEntries(sp), limit: 24 }).then(setData).catch((e) => setErr((e as Error).message));
  }, [category, sp, reload]);

  useEffect(() => { setOpen(false); }, [category, sp]);

  const set = (k: string, v: string | null) => {
    const n = new URLSearchParams(sp);
    v ? n.set(k, v) : n.delete(k);
    if (k !== "page") n.delete("page");
    setSp(n);
  };
  const toggle = (k: string) => set(k, sp.get(k) ? null : "1");

  const current = cats.find((c) => c.slug === category);
  const q = sp.get("q");
  const title = q ? `Results for “${q}”` : current?.name ?? (sp.get("newArrivals") ? "New arrivals" : sp.get("onSale") ? "Offers" : sp.get("tryOn") ? "Try on with AI" : "All jewellery");

  const activeChips = useMemo(() => {
    const chips: { label: string; clear: () => void }[] = [];
    if (q) chips.push({ label: `“${q}”`, clear: () => set("q", null) });
    if (sp.get("minPrice") || sp.get("maxPrice")) chips.push({ label: `LKR ${sp.get("minPrice") || "0"} – ${sp.get("maxPrice") || "any"}`, clear: () => { const n = new URLSearchParams(sp); n.delete("minPrice"); n.delete("maxPrice"); n.delete("page"); setSp(n); } });
    if (sp.get("style")) chips.push({ label: sp.get("style")!, clear: () => set("style", null) });
    if (sp.get("colour")) chips.push({ label: sp.get("colour")!, clear: () => set("colour", null) });
    if (sp.get("inStock")) chips.push({ label: "In stock", clear: () => set("inStock", null) });
    if (sp.get("onSale")) chips.push({ label: "On offer", clear: () => set("onSale", null) });
    if (sp.get("newArrivals")) chips.push({ label: "New arrivals", clear: () => set("newArrivals", null) });
    if (sp.get("tryOn")) chips.push({ label: "AI try-on", clear: () => set("tryOn", null) });
    return chips;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [sp]);

  const applyPrice = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    const n = new URLSearchParams(sp);
    const min = String(f.get("minPrice") || ""), max = String(f.get("maxPrice") || "");
    min ? n.set("minPrice", min) : n.delete("minPrice");
    max ? n.set("maxPrice", max) : n.delete("maxPrice");
    n.delete("page");
    setSp(n);
  };

  const keep = sp.toString() ? `?${new URLSearchParams([...sp].filter(([k]) => k !== "page")).toString()}` : "";

  return (
    <div className="page">
      <Breadcrumb items={[{ to: "/", label: "Home" }, { to: "/shop", label: "Shop" }, ...(current ? [{ label: current.name }] : [])]} />
      <div className="shop-head">
        <h1>{title}</h1>
      </div>

      <div className="shop">
        {open && <button className="drawer-scrim" aria-label="Close filters" onClick={() => setOpen(false)} />}
        <aside className={`filters ${open ? "is-open" : ""}`} aria-label="Filters">
          <div className="filters-head">
            <h2>Filters</h2>
            <button className="icon-btn" aria-label="Close filters" onClick={() => setOpen(false)}><Icon name="close" /></button>
          </div>

          <div className="filter-group">
            <h2>Category</h2>
            <div className="filter-list">
              <Link to={`/shop${keep}`} className={`filter-link ${!category ? "is-on" : ""}`}>All jewellery</Link>
              {cats.map((c) => (
                <Link key={c.id} to={`/shop/${c.slug}${keep}`} className={`filter-link ${category === c.slug ? "is-on" : ""}`} aria-current={category === c.slug ? "page" : undefined}>
                  {c.name}<span className="muted">{c._count?.products ?? ""}</span>
                </Link>
              ))}
            </div>
          </div>

          <form className="filter-group" onSubmit={applyPrice} key={`${sp.get("minPrice")}-${sp.get("maxPrice")}`}>
            <h2>Price (LKR)</h2>
            <div className="price-inputs">
              <label className="sr-only" htmlFor="minPrice">Minimum price</label>
              <input id="minPrice" name="minPrice" type="number" min={0} inputMode="numeric" placeholder={facets ? String(facets.minPrice) : "Min"} defaultValue={sp.get("minPrice") ?? ""} />
              <span aria-hidden="true">–</span>
              <label className="sr-only" htmlFor="maxPrice">Maximum price</label>
              <input id="maxPrice" name="maxPrice" type="number" min={0} inputMode="numeric" placeholder={facets ? String(facets.maxPrice) : "Max"} defaultValue={sp.get("maxPrice") ?? ""} />
            </div>
            <button className="btn btn-quiet btn-sm">Apply price</button>
          </form>

          {!!facets?.styles.length && (
            <div className="filter-group">
              <h2>Style</h2>
              <div className="chips">
                {facets.styles.map((st) => <button key={st} type="button" className="chip" aria-pressed={sp.get("style") === st} onClick={() => set("style", sp.get("style") === st ? null : st)}>{st}</button>)}
              </div>
            </div>
          )}
          {!!facets?.colours.length && (
            <div className="filter-group">
              <h2>Colour</h2>
              <div className="chips">
                {facets.colours.map((c) => <button key={c} type="button" className="chip" aria-pressed={sp.get("colour") === c} onClick={() => set("colour", sp.get("colour") === c ? null : c)}>{c}</button>)}
              </div>
            </div>
          )}

          <div className="filter-group">
            <h2>Show</h2>
            <label className="check"><input type="checkbox" checked={!!sp.get("inStock")} onChange={() => toggle("inStock")} />In stock only</label>
            <label className="check"><input type="checkbox" checked={!!sp.get("onSale")} onChange={() => toggle("onSale")} />On offer</label>
            <label className="check"><input type="checkbox" checked={!!sp.get("newArrivals")} onChange={() => toggle("newArrivals")} />New arrivals</label>
            <label className="check"><input type="checkbox" checked={!!sp.get("tryOn")} onChange={() => toggle("tryOn")} />Can try on with AI</label>
          </div>
        </aside>

        <div>
          <div className="shop-toolbar">
            <span className="shop-count" aria-live="polite">{data ? `${data.total} ${data.total === 1 ? "piece" : "pieces"}` : "Loading…"}</span>
            <div className="shop-toolbar-right">
              <button className="btn btn-quiet btn-sm filters-toggle" onClick={() => setOpen(true)} aria-expanded={open}><Icon name="filter" size={18} />Filters{activeChips.length ? ` (${activeChips.length})` : ""}</button>
              <label className="sort">
                <span className="sr-only">Sort by</span>
                <select value={sp.get("sort") ?? "new"} onChange={(e) => set("sort", e.target.value === "new" ? null : e.target.value)}>
                  {sorts.map((s) => <option key={s.v} value={s.v}>{s.label}</option>)}
                </select>
              </label>
            </div>
          </div>

          {activeChips.length > 0 && (
            <div className="active-filters">
              {activeChips.map((c) => <button key={c.label} className="chip" onClick={c.clear} aria-label={`Remove filter ${c.label}`}>{c.label}<Icon name="close" size={14} /></button>)}
              <Link to={category ? `/shop/${category}` : "/shop"} className="btn-link" style={{ minHeight: 36, fontSize: 14 }}>Clear all</Link>
            </div>
          )}

          {err ? <ErrorState message={err} onRetry={() => setReload((n) => n + 1)} />
            : !data ? <div className="pgrid">{Array.from({ length: 8 }, (_, i) => <div key={i} className="skeleton skeleton-card" />)}</div>
            : !data.items.length ? (
              <EmptyState title="No pieces match" action={<Link to="/shop" className="btn btn-primary">See all jewellery</Link>}>
                {activeChips.length ? "Remove a filter or search for something else." : "There's nothing in this category yet."}
              </EmptyState>
            ) : (
              <>
                <div className="pgrid">{data.items.map((p) => <ProductCard key={p.id} p={p} />)}</div>
                <Pagination page={data.page} pages={data.pages} onPage={(p) => set("page", p === 1 ? null : String(p))} />
              </>
            )}
        </div>
      </div>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\TrackOrder.tsx' @'
import { FormEvent, useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { api } from "../api/client";
import type { Order } from "../api/types";
import { customerStatus, shortDate, whatsappLink } from "../api/format";
import { useSettings } from "../context/SettingsContext";
import Icon from "../components/Icon";
import { OrderLines, OrderTimeline } from "../components/OrderView";

export default function TrackOrder() {
  const [sp, setSp] = useSearchParams();
  const s = useSettings();
  const [order, setOrder] = useState<Order | null>(null);
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  const lookup = async (orderNo: string, mobile: string) => {
    setBusy(true); setErr("");
    try { setOrder(await api.trackOrder(orderNo, mobile)); }
    catch (e) { setErr((e as Error).message); setOrder(null); }
    finally { setBusy(false); }
  };

  useEffect(() => {
    const o = sp.get("orderNo"), m = sp.get("mobile");
    if (o && m) lookup(o, m);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const submit = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    const orderNo = String(f.get("orderNo")).trim(), mobile = String(f.get("mobile")).trim();
    setSp({ orderNo, mobile }, { replace: true });
    lookup(orderNo, mobile);
  };

  const contact = s.whatsapp || s.phone;

  return (
    <div className="page">
      <div className="page-head"><h1>Track your order</h1><p>Enter your order number and the mobile number you used at checkout.</p></div>
      <div className="track-grid">
        <form className="card form" onSubmit={submit}>
          <label className="field"><span className="field-label">Order number</span><input name="orderNo" required placeholder="ORD-000125" defaultValue={sp.get("orderNo") ?? ""} autoCapitalize="characters" /></label>
          <label className="field"><span className="field-label">Mobile number</span><input name="mobile" type="tel" required placeholder="07XXXXXXXX" inputMode="tel" defaultValue={sp.get("mobile") ?? ""} /></label>
          {err && <p className="form-error" role="alert">{err}</p>}
          <button className="btn btn-primary btn-block" disabled={busy}>{busy ? "Checking…" : "Track order"}</button>
        </form>

        {order ? (
          <div className="stack">
            <section className="card" aria-labelledby="status-title">
              <div className="order-card-head" style={{ marginBottom: 20 }}>
                <div><h2 id="status-title" style={{ marginBottom: 4 }}>{customerStatus[order.status]}</h2><span className="muted">{order.orderNo} · placed {shortDate(order.createdAt)}</span></div>
                {contact && <a href={whatsappLink(contact, `Hi, about my order ${order.orderNo}.`)} target="_blank" rel="noreferrer" className="btn btn-quiet btn-sm"><Icon name="chat" size={16} />Ask on WhatsApp</a>}
              </div>
              <OrderTimeline order={order} />
            </section>
            <section className="card" aria-labelledby="items-title">
              <h2 id="items-title">Items</h2>
              <OrderLines order={order} />
            </section>
          </div>
        ) : (
          <div className="card" style={{ display: "flex", gap: 16, alignItems: "center" }}>
            <span className="empty-icon" style={{ flexShrink: 0 }}><Icon name="truck" size={26} /></span>
            <p className="muted">Your order number is on the confirmation page and in the message we sent you. It looks like ORD-000125.</p>
          </div>
        )}
      </div>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\TryOn.tsx' @'
import { DragEvent, useEffect, useRef, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { api } from "../api/client";
import type { AiModel, Product, TryOnJob } from "../api/types";
import { lkr } from "../api/format";
import { useCart } from "../context/CartContext";
import { useToast } from "../context/ToastContext";
import Icon from "../components/Icon";
import { EmptyState, PageLoading, Price, ProductImage } from "../components/ui";

type Mode = "AI_MODEL" | "UPLOAD";
const MAX_MB = 8;

export default function TryOn() {
  const [sp] = useSearchParams();
  const ids = (sp.get("products") ?? "").split(",").filter(Boolean);
  const { add } = useCart();
  const { show } = useToast();

  const [items, setItems] = useState<Product[] | null>(null);
  const [mode, setMode] = useState<Mode | null>(null);
  const [models, setModels] = useState<AiModel[] | null>(null);
  const [modelId, setModelId] = useState<string>();
  const [photo, setPhoto] = useState<File>();
  const [preview, setPreview] = useState<string>();
  const [over, setOver] = useState(false);
  const [job, setJob] = useState<TryOnJob | null>(null);
  const [err, setErr] = useState("");
  const timer = useRef<number>();
  const started = useRef(0);

  useEffect(() => {
    if (!ids.length) { setItems([]); return; }
    api.products({ ids: ids.join(","), limit: 20 }).then((r) => setItems(r.items.filter((p) => p.tryOnEnabled))).catch(() => setItems([]));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [sp.get("products")]);

  useEffect(() => { if (mode === "AI_MODEL" && !models) api.aiModels().then(setModels).catch(() => setModels([])); }, [mode, models]);
  useEffect(() => () => { window.clearInterval(timer.current); }, []);
  useEffect(() => {
    if (!photo) { setPreview(undefined); return; }
    const url = URL.createObjectURL(photo);
    setPreview(url);
    return () => URL.revokeObjectURL(url);
  }, [photo]);

  if (!items) return <PageLoading />;
  if (!items.length) return (
    <div className="page">
      <EmptyState icon="sparkle" title="Choose a piece to try on" action={<Link to="/shop?tryOn=1" className="btn btn-primary">Browse pieces you can try on</Link>}>
        Open any product and select “Try it on with AI”, or build a full set in Create your look.
      </EmptyState>
    </div>
  );

  const pickFile = (f?: File) => {
    setErr("");
    if (!f) return;
    if (!/image\/(jpeg|png|webp)/.test(f.type)) { setErr("Choose a JPG, PNG or WebP photo."); return; }
    if (f.size > MAX_MB * 1024 * 1024) { setErr(`That photo is over ${MAX_MB} MB. Choose a smaller one.`); return; }
    setPhoto(f);
  };
  const onDrop = (e: DragEvent) => { e.preventDefault(); setOver(false); pickFile(e.dataTransfer.files[0]); };

  const poll = (id: string) => {
    started.current = Date.now();
    timer.current = window.setInterval(async () => {
      try {
        const s = await api.tryOnStatus(id);
        setJob(s);
        if (s.status === "DONE" || s.status === "FAILED") window.clearInterval(timer.current);
      } catch { /* keep polling */ }
      if (Date.now() - started.current > 120_000) {
        window.clearInterval(timer.current);
        setJob({ id, status: "FAILED", error: "This is taking longer than expected. Try again in a moment." });
      }
    }, 2000);
  };

  const generate = async () => {
    setErr("");
    const fd = new FormData();
    fd.append("productIds", JSON.stringify(items.map((p) => p.id)));
    fd.append("source", mode!);
    if (mode === "AI_MODEL" && modelId) fd.append("aiModelId", modelId);
    if (mode === "UPLOAD" && photo) fd.append("photo", photo);
    try {
      const j = await api.startTryOn(fd);
      setJob(j);
      poll(j.id);
    } catch (e) { setErr((e as Error).message); }
  };

  const reset = () => { window.clearInterval(timer.current); setJob(null); };
  const step = job ? 3 : mode ? 2 : 1;
  const total = items.reduce((s, p) => s + (p.salePrice ?? p.price), 0);
  const ready = (mode === "AI_MODEL" && !!modelId) || (mode === "UPLOAD" && !!photo);

  const save = async () => {
    if (!job?.resultUrl) return;
    try {
      const blob = await (await fetch(job.resultUrl)).blob();
      const a = document.createElement("a");
      a.href = URL.createObjectURL(blob);
      a.download = "my-try-on.jpg";
      a.click();
      URL.revokeObjectURL(a.href);
    } catch { window.open(job.resultUrl, "_blank"); }
  };
  const share = async () => {
    if (!job?.resultUrl) return;
    try {
      if (navigator.share) await navigator.share({ title: "My try-on", url: job.resultUrl });
      else { await navigator.clipboard.writeText(job.resultUrl); show("Link copied"); }
    } catch { /* closed */ }
  };

  return (
    <div className="page">
      <div className="page-head"><h1>Virtual try-on</h1></div>
      <ol className="stepper" aria-label="Steps">
        {["Choose how", mode === "UPLOAD" ? "Add your photo" : "Pick a model", "Your preview"].map((label, i) => (
          <li key={label} className={step === i + 1 ? "is-current" : step > i + 1 ? "is-done" : ""} aria-current={step === i + 1 ? "step" : undefined}>
            <span className="step-dot">{step > i + 1 ? <Icon name="check" size={14} /> : i + 1}</span>{label}
          </li>
        ))}
      </ol>

      <div className="tryon">
        <div>
          {job ? (
            job.status === "DONE" && job.resultUrl ? (
              <div className="result">
                <div className="result-img"><img src={job.resultUrl} alt={`Preview wearing ${items.map((p) => p.name).join(", ")}`} /></div>
                <div className="result-info">
                  <h2>Here's how it looks</h2>
                  <p className="muted">Wearing {items.map((p) => p.name).join(", ")}.</p>
                  <button className="btn btn-primary btn-lg" onClick={() => add(items.map((p) => ({ productId: p.id, qty: 1 })), items.length > 1 ? "Your look was added to the cart" : `${items[0].name} added to cart`)}>
                    Add {items.length > 1 ? `all ${items.length} to cart` : "to cart"} · {lkr(total)}
                  </button>
                  <div className="tryon-actions" style={{ marginTop: 0 }}>
                    <button className="btn btn-quiet" onClick={save}><Icon name="download" size={18} />Save</button>
                    <button className="btn btn-quiet" onClick={share}><Icon name="share" size={18} />Share</button>
                    <button className="btn btn-quiet" onClick={reset}><Icon name="refresh" size={18} />Try again</button>
                  </div>
                  <p className="result-note">AI previews show how a piece may look. Size and colour can vary slightly in real life.</p>
                </div>
              </div>
            ) : job.status === "FAILED" ? (
              <div className="empty-state">
                <span className="empty-icon empty-icon-error"><Icon name="alert" size={28} /></span>
                <h2>We couldn't make the preview</h2>
                <p>{job.error ?? "Try a different photo or model."}</p>
                <button className="btn btn-primary" onClick={reset}>Try again</button>
              </div>
            ) : (
              <div className="generating" role="status">
                <span className="generating-art"><Icon name="sparkle" size={44} /></span>
                <h2>Creating your preview</h2>
                <p>This usually takes a few seconds. Keep this page open.</p>
              </div>
            )
          ) : !mode ? (
            <>
              <h2 className="sr-only">How would you like to try it on?</h2>
              <div className="method-grid">
                <button className="method" onClick={() => setMode("AI_MODEL")}>
                  <span className="method-icon"><Icon name="model" size={28} /></span>
                  <strong>Use an AI model</strong>
                  <span>Pick a model and see the piece on them. Quick, and no photo needed.</span>
                </button>
                <button className="method" onClick={() => setMode("UPLOAD")}>
                  <span className="method-icon"><Icon name="camera" size={28} /></span>
                  <strong>Upload your photo</strong>
                  <span>See it on yourself. Your photo is only used to make this preview.</span>
                </button>
              </div>
            </>
          ) : mode === "AI_MODEL" ? (
            <>
              <h2 className="sr-only">Pick a model</h2>
              {!models ? <PageLoading label="Loading models…" /> : !models.length ? (
                <EmptyState icon="model" title="No models yet" action={<button className="btn btn-primary" onClick={() => setMode("UPLOAD")}>Upload your photo instead</button>}>
                  The shop hasn't added AI models yet.
                </EmptyState>
              ) : (
                <div className="model-grid">
                  {models.map((m) => (
                    <button key={m.id} className="model-card" aria-pressed={modelId === m.id} onClick={() => setModelId(m.id)} aria-label={`Model ${m.name}`}>
                      <img src={m.imageUrl} alt="" />
                      <span className="model-card-check"><Icon name="check" size={16} /></span>
                      <span className="model-card-name">{m.name}</span>
                    </button>
                  ))}
                </div>
              )}
            </>
          ) : (
            <>
              <h2 className="sr-only">Add your photo</h2>
              {preview ? (
                <div className="photo-preview">
                  <img src={preview} alt="Your photo" />
                  <div className="stack">
                    <ul className="tips">
                      <li><Icon name="checkCircle" />Face clearly visible</li>
                      <li><Icon name="checkCircle" />Good, even lighting</li>
                      <li><Icon name="checkCircle" />Facing the camera</li>
                    </ul>
                    <label className="btn btn-quiet" style={{ alignSelf: "flex-start" }}>
                      <Icon name="refresh" size={18} />Choose another photo
                      <input type="file" accept="image/jpeg,image/png,image/webp" className="sr-only" onChange={(e) => pickFile(e.target.files?.[0])} />
                    </label>
                  </div>
                </div>
              ) : (
                <label className={`dropzone ${over ? "is-over" : ""}`} onDragOver={(e) => { e.preventDefault(); setOver(true); }} onDragLeave={() => setOver(false)} onDrop={onDrop}>
                  <span className="dropzone-icon"><Icon name="upload" size={26} /></span>
                  <strong>Choose a photo or drop it here</strong>
                  <span>JPG, PNG or WebP, up to {MAX_MB} MB. A clear, front-facing photo works best.</span>
                  <input type="file" accept="image/jpeg,image/png,image/webp" capture="user" className="sr-only" onChange={(e) => pickFile(e.target.files?.[0])} />
                </label>
              )}
            </>
          )}

          {err && <p className="form-error" role="alert" style={{ marginTop: 16 }}>{err}</p>}

          {!job && mode && (
            <div className="tryon-actions">
              <button className="btn btn-quiet" onClick={() => { setMode(null); setErr(""); }}><Icon name="arrowLeft" size={18} />Back</button>
              <button className="btn btn-primary" disabled={!ready} onClick={generate}><Icon name="sparkle" size={18} />Create preview</button>
            </div>
          )}
        </div>

        <aside className="tryon-side" aria-label="Pieces you're trying on">
          <h2>Trying on</h2>
          {items.map((p) => (
            <div key={p.id} className="mini-item">
              <span className="mini-item-img"><ProductImage url={p.images[0]?.url} alt="" type={p.jewelleryType} iconSize={30} /></span>
              <span>
                <Link to={`/product/${p.slug}`} className="mini-item-name">{p.name}</Link><br />
                <Price price={p.price} pricing={p} />
              </span>
            </div>
          ))}
          {items.length > 1 && <div className="tray-total"><span>Total</span><span>{lkr(total)}</span></div>}
        </aside>
      </div>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\admin\AdminLayout.tsx' @'
import { useEffect, useState } from "react";
import { Link, NavLink, Outlet, useLocation, useNavigate } from "react-router-dom";
import { api } from "../../api/client";
import { useAuth } from "../../context/AuthContext";
import { useSettings } from "../../context/SettingsContext";
import Icon, { IconName } from "../../components/Icon";

const links: { to: string; label: string; icon: IconName; end?: boolean }[] = [
  { to: "/admin", label: "Dashboard", icon: "dashboard", end: true },
  { to: "/admin/orders", label: "Orders", icon: "orders" },
  { to: "/admin/products", label: "Products", icon: "products" },
  { to: "/admin/categories", label: "Categories", icon: "categories" },
  { to: "/admin/customers", label: "Customers", icon: "customers" },
  { to: "/admin/ai-models", label: "AI models", icon: "model" },
  { to: "/admin/offers", label: "Offers", icon: "offers" },
  { to: "/admin/reports", label: "Reports", icon: "reports" },
  { to: "/admin/settings", label: "Settings", icon: "settings" },
];

export default function AdminLayout() {
  const { user, logout } = useAuth();
  const s = useSettings();
  const nav = useNavigate();
  const loc = useLocation();
  const [open, setOpen] = useState(false);
  const [pending, setPending] = useState(0);

  useEffect(() => {
    setOpen(false);
    api.admin.orders({ status: "PENDING" }).then((r) => setPending(r.total)).catch(() => undefined);
  }, [loc.pathname]);

  const signOut = () => { logout(); nav("/admin/login", { replace: true }); };

  return (
    <div className="admin-shell">
      <aside className={`admin-side ${open ? "is-open" : ""}`} aria-label="Admin menu">
        <Link to="/admin" className="admin-logo">{s.shopName}</Link>
        <nav className="admin-nav" aria-label="Admin">
          {links.map((l) => (
            <NavLink key={l.to} to={l.to} end={l.end}>
              <Icon name={l.icon} />{l.label}
              {l.to === "/admin/orders" && pending > 0 && <span className="admin-nav-count" aria-label={`${pending} pending`}>{pending}</span>}
            </NavLink>
          ))}
        </nav>
        <div className="admin-side-foot">
          <Link to="/" className="admin-side-link" target="_blank"><Icon name="store" />View shop</Link>
          <button className="admin-side-link" onClick={signOut}><Icon name="logout" />Sign out</button>
        </div>
      </aside>

      <div className="admin-main">
        <header className="admin-top">
          <button className="icon-btn admin-menu" aria-label="Open menu" aria-expanded={open} onClick={() => setOpen(!open)}>
            <Icon name="menu" />
          </button>
          <span className="admin-user"><Icon name="user" size={18} />{user?.name}</span>
        </header>
        <div className="admin-content"><Outlet /></div>
      </div>
      {open && <button className="admin-scrim" aria-label="Close menu" onClick={() => setOpen(false)} />}
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\admin\AdminLogin.tsx' @'
import { FormEvent, useState } from "react";
import { Navigate, useNavigate } from "react-router-dom";
import { useAuth } from "../../context/AuthContext";
import AuthShell from "../../components/AuthShell";
import PasswordInput from "../../components/PasswordInput";

export default function AdminLogin() {
  const { user, login, logout } = useAuth();
  const nav = useNavigate();
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  if (user?.role === "ADMIN") return <Navigate to="/admin" replace />;

  const submit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    setBusy(true); setErr("");
    try {
      const u = await login(String(f.get("email")), String(f.get("password")));
      if (u.role !== "ADMIN") {
        logout();
        throw new Error("This account doesn't have admin access.");
      }
      nav("/admin", { replace: true });
    } catch (e) {
      setErr((e as Error).message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <AuthShell
      title="Admin sign in"
      subtitle="Manage products, orders and reports."
      aside={<><h2>Shop admin</h2><p>Confirm orders, update stock and see today's sales in one place.</p></>}
    >
      <form onSubmit={submit} className="form">
        <label className="field">
          <span className="field-label">Email</span>
          <input name="email" type="email" required autoComplete="username" />
        </label>
        <PasswordInput name="password" label="Password" autoComplete="current-password" />
        {err && <p className="form-error" role="alert">{err}</p>}
        <button className="btn btn-primary btn-block" disabled={busy}>{busy ? "Signing in…" : "Sign in"}</button>
      </form>
    </AuthShell>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\admin\AiModels.tsx' @'
import { FormEvent, useEffect, useState } from "react";
import { api } from "../../api/client";
import type { AiModel } from "../../api/types";
import { useToast } from "../../context/ToastContext";
import Icon from "../../components/Icon";
import { ConfirmDialog, EmptyState, ErrorState, Modal, PageLoading } from "../../components/ui";

export default function AiModels() {
  const { show } = useToast();
  const [models, setModels] = useState<AiModel[] | null>(null);
  const [err, setErr] = useState("");
  const [adding, setAdding] = useState(false);
  const [preview, setPreview] = useState<string>();
  const [formErr, setFormErr] = useState("");
  const [busy, setBusy] = useState(false);
  const [deleting, setDeleting] = useState<AiModel | null>(null);

  const load = () => { setErr(""); api.admin.aiModels().then(setModels).catch((e) => setErr((e as Error).message)); };
  useEffect(load, []);

  const add = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);
    if (!(fd.get("image") as File)?.size) { setFormErr("Choose a photo of the model."); return; }
    setBusy(true); setFormErr("");
    try { await api.admin.addAiModel(fd); show("Model added"); setAdding(false); setPreview(undefined); load(); }
    catch (e) { setFormErr((e as Error).message); } finally { setBusy(false); }
  };
  const toggle = async (m: AiModel) => {
    try { await api.admin.updateAiModel(m.id, { isActive: !m.isActive }); show(m.isActive ? `${m.name} is hidden from customers` : `${m.name} is available`); load(); }
    catch (e) { show((e as Error).message, { kind: "error" }); }
  };
  const remove = async () => {
    setBusy(true);
    try {
      const r = await api.admin.deleteAiModel(deleting!.id);
      show(r?.hidden ? `${deleting!.name} has past try-ons, so it was hidden instead of deleted` : "Model deleted");
      setDeleting(null); load();
    } catch (e) { show((e as Error).message, { kind: "error" }); } finally { setBusy(false); }
  };

  return (
    <div className="admin-page">
      <div className="admin-head">
        <div><h1>AI models</h1><p>Customers who don't upload their own photo choose one of these models for their try-on.</p></div>
        <button className="btn btn-primary" onClick={() => { setAdding(true); setFormErr(""); }}><Icon name="plus" size={18} />Add model</button>
      </div>

      {err ? <ErrorState message={err} onRetry={load} /> : !models ? <PageLoading /> : !models.length ? (
        <div className="panel">
          <EmptyState icon="model" title="No models yet" action={<button className="btn btn-primary" onClick={() => setAdding(true)}>Add your first model</button>}>
            Add a few front-facing portrait photos with the ears, neck and wrists visible. Use photos you have the rights to.
          </EmptyState>
        </div>
      ) : (
        <div className="gallery-admin">
          {models.map((m) => (
            <article key={m.id} className={`model-admin ${m.isActive ? "" : "is-off"}`}>
              <img src={m.imageUrl} alt={`Model ${m.name}`} />
              <div className="model-admin-body">
                <span><strong>{m.name}</strong><span className="muted" style={{ display: "block", fontSize: 13 }}>{m._count?.tryOns ?? 0} try-ons</span></span>
                <span className={`pill ${m.isActive ? "pill-on" : "pill-off"}`}>{m.isActive ? "Shown" : "Hidden"}</span>
              </div>
              <div className="model-admin-actions">
                <button className="btn btn-quiet btn-sm" style={{ flex: 1 }} onClick={() => toggle(m)}>{m.isActive ? "Hide" : "Show"}</button>
                <button className="icon-btn" aria-label={`Delete ${m.name}`} onClick={() => setDeleting(m)}><Icon name="trash" size={18} /></button>
              </div>
            </article>
          ))}
        </div>
      )}

      <Modal open={adding} title="Add model" onClose={() => { setAdding(false); setPreview(undefined); }}>
        <form className="form" onSubmit={add}>
          <label className="field"><span className="field-label">Name</span><input name="name" required maxLength={40} placeholder="Model 1" autoFocus /><span className="field-hint">Customers see this name</span></label>
          <div className="field">
            <span className="field-label">Photo</span>
            {preview && <img src={preview} alt="Preview" style={{ width: 140, aspectRatio: "3 / 4", objectFit: "cover", borderRadius: 12 }} />}
            <label className="btn btn-quiet btn-sm" style={{ alignSelf: "flex-start" }}><Icon name="upload" size={16} />{preview ? "Choose another" : "Choose photo"}
              <input name="image" type="file" accept="image/jpeg,image/png,image/webp" className="sr-only" onChange={(e) => { const f = e.target.files?.[0]; setPreview(f ? URL.createObjectURL(f) : undefined); }} />
            </label>
            <span className="field-hint">Front-facing, good light, ears, neck and wrists visible.</span>
          </div>
          {formErr && <p className="form-error" role="alert">{formErr}</p>}
          <div className="modal-foot" style={{ margin: "4px -24px -24px" }}>
            <button type="button" className="btn btn-secondary" onClick={() => setAdding(false)}>Cancel</button>
            <button className="btn btn-primary" disabled={busy}>{busy ? "Uploading…" : "Add model"}</button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog open={!!deleting} danger title="Delete this model?" confirmLabel="Delete model" busy={busy} onConfirm={remove} onClose={() => setDeleting(null)}
        body={deleting?._count?.tryOns ? <>{deleting.name} was used in {deleting._count.tryOns} try-ons, so it will be hidden instead of deleted.</> : <>{deleting?.name} will be removed.</>} />
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\admin\Categories.tsx' @'
import { FormEvent, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../../api/client";
import type { Category } from "../../api/types";
import { useToast } from "../../context/ToastContext";
import Icon from "../../components/Icon";
import JewelIcon from "../../components/JewelIcon";
import { ConfirmDialog, ErrorState, Modal, PageLoading } from "../../components/ui";

export default function Categories() {
  const { show } = useToast();
  const [cats, setCats] = useState<Category[] | null>(null);
  const [err, setErr] = useState("");
  const [editing, setEditing] = useState<Category | "new" | null>(null);
  const [deleting, setDeleting] = useState<Category | null>(null);
  const [formErr, setFormErr] = useState("");
  const [busy, setBusy] = useState(false);
  const [preview, setPreview] = useState<string>();

  const load = () => { setErr(""); api.categories().then(setCats).catch((e) => setErr((e as Error).message)); };
  useEffect(load, []);

  const open = (c: Category | "new") => { setFormErr(""); setPreview(undefined); setEditing(c); };

  const save = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);
    if (!(fd.get("image") as File)?.size) fd.delete("image");
    setBusy(true); setFormErr("");
    try {
      await api.admin.saveCategory(fd, editing === "new" ? undefined : editing!.id);
      show(editing === "new" ? "Category added" : "Category saved");
      setEditing(null); load();
    } catch (e) { setFormErr((e as Error).message); } finally { setBusy(false); }
  };

  const remove = async () => {
    setBusy(true);
    try { await api.admin.deleteCategory(deleting!.id); show("Category deleted"); setDeleting(null); load(); }
    catch (e) { show((e as Error).message, { kind: "error" }); setDeleting(null); }
    finally { setBusy(false); }
  };

  const current = editing && editing !== "new" ? editing : null;

  return (
    <div className="admin-page">
      <div className="admin-head">
        <div><h1>Categories</h1><p>Shown on the home page and as filters in the shop, in this order.</p></div>
        <button className="btn btn-primary" onClick={() => open("new")}><Icon name="plus" size={18} />Add category</button>
      </div>

      {err ? <ErrorState message={err} onRetry={load} /> : !cats ? <PageLoading /> : (
        <div className="panel panel-flush">
          <div className="table-scroll">
            <table className="table">
              <thead><tr><th>Category</th><th className="num">Order</th><th className="num">Products</th><th><span className="sr-only">Actions</span></th></tr></thead>
              <tbody>
                {cats.map((c) => (
                  <tr key={c.id}>
                    <td><div className="cell-product"><span className="cat-row-img">{c.imageUrl ? <img src={c.imageUrl} alt="" /> : <JewelIcon slug={c.slug} size={26} />}</span><strong>{c.name}</strong></div></td>
                    <td className="num">{c.sort}</td>
                    <td className="num"><Link to={`/admin/products?category=${c.id}`}>{c._count?.products ?? 0}</Link></td>
                    <td>
                      <div className="row-actions">
                        <button className="icon-btn" aria-label={`Edit ${c.name}`} onClick={() => open(c)}><Icon name="edit" size={18} /></button>
                        <button className="icon-btn" aria-label={`Delete ${c.name}`} onClick={() => setDeleting(c)}><Icon name="trash" size={18} /></button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      <Modal open={!!editing} title={editing === "new" ? "Add category" : "Edit category"} onClose={() => setEditing(null)}>
        {editing && (
          <form className="form" onSubmit={save} id="cat-form">
            <label className="field"><span className="field-label">Name</span><input name="name" required maxLength={60} defaultValue={current?.name} autoFocus /></label>
            <label className="field"><span className="field-label">Order</span><input name="sort" type="number" step={1} defaultValue={current?.sort ?? (cats?.length ?? 0)} /><span className="field-hint">Lower numbers show first</span></label>
            <div className="field">
              <span className="field-label">Image <span className="optional">(optional)</span></span>
              <div className="asset-row">
                <span className="cat-row-img" style={{ width: 72, height: 72 }}>{preview || current?.imageUrl ? <img src={preview ?? current!.imageUrl!} alt="" /> : <JewelIcon slug={current?.slug ?? ""} size={36} />}</span>
                <label className="btn btn-quiet btn-sm"><Icon name="upload" size={16} />Choose image
                  <input name="image" type="file" accept="image/jpeg,image/png,image/webp" className="sr-only" onChange={(e) => { const f = e.target.files?.[0]; setPreview(f ? URL.createObjectURL(f) : undefined); }} />
                </label>
              </div>
              <span className="field-hint">Without an image, a drawing that matches the name is shown.</span>
            </div>
            {formErr && <p className="form-error" role="alert">{formErr}</p>}
            <div className="modal-foot" style={{ margin: "4px -24px -24px" }}>
              <button type="button" className="btn btn-secondary" onClick={() => setEditing(null)}>Cancel</button>
              <button className="btn btn-primary" disabled={busy}>{busy ? "Saving…" : "Save category"}</button>
            </div>
          </form>
        )}
      </Modal>

      <ConfirmDialog open={!!deleting} danger title="Delete this category?" confirmLabel="Delete category" busy={busy} onConfirm={remove} onClose={() => setDeleting(null)}
        body={deleting?._count?.products ? <>{deleting.name} still has {deleting._count.products} products. Move them to another category first.</> : <>{deleting?.name} will be removed from the shop.</>} />
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\admin\Customers.tsx' @'
import { FormEvent, useEffect, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { api } from "../../api/client";
import type { Customer, CustomerDetail, Paged } from "../../api/types";
import { lkr, phoneLink, shortDate, whatsappLink } from "../../api/format";
import Icon from "../../components/Icon";
import { EmptyState, ErrorState, Modal, PageLoading, Pagination, StatusPill } from "../../components/ui";

export default function Customers() {
  const [sp, setSp] = useSearchParams();
  const [data, setData] = useState<Paged<Customer> | null>(null);
  const [err, setErr] = useState("");
  const [detail, setDetail] = useState<CustomerDetail | null>(null);

  const load = () => { setErr(""); api.admin.customers({ q: sp.get("q"), page: sp.get("page") ?? 1 }).then(setData).catch((e) => setErr((e as Error).message)); };
  useEffect(load, [sp]); // eslint-disable-line react-hooks/exhaustive-deps

  const search = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const q = String(new FormData(e.currentTarget).get("q") || "");
    setSp(q ? { q } : {});
  };
  const openCustomer = (id: string) => api.admin.customer(id).then(setDetail).catch(() => undefined);

  return (
    <div className="admin-page">
      <div className="admin-head"><div><h1>Customers</h1><p>People who created an account. Guest orders appear under Orders.</p></div></div>
      <div className="toolbar">
        <form className="search" role="search" onSubmit={search}>
          <Icon name="search" size={18} />
          <label htmlFor="c-search" className="sr-only">Search customers</label>
          <input id="c-search" name="q" type="search" placeholder="Name, email or mobile" defaultValue={sp.get("q") ?? ""} />
        </form>
      </div>

      {err ? <ErrorState message={err} onRetry={load} /> : !data ? <PageLoading /> : !data.items.length ? (
        <div className="panel"><EmptyState icon="customers" title={sp.get("q") ? "No customers match" : "No customers yet"}>{sp.get("q") ? "Try another name, email or number." : "Customers appear here when they create an account."}</EmptyState></div>
      ) : (
        <>
          <div className="panel panel-flush">
            <div className="table-scroll">
              <table className="table">
                <thead><tr><th>Customer</th><th>Mobile</th><th className="num">Orders</th><th className="num">Spent</th><th>Joined</th></tr></thead>
                <tbody>
                  {data.items.map((c) => (
                    <tr key={c.id}>
                      <td><button className="btn-link" style={{ minHeight: 0, textAlign: "left" }} onClick={() => openCustomer(c.id)}>{c.name}</button><span className="muted" style={{ display: "block", fontSize: 13 }}>{c.email}</span></td>
                      <td>{c.phone || <span className="muted">—</span>}</td>
                      <td className="num">{c._count.orders}</td>
                      <td className="num">{lkr(c.totalSpent)}</td>
                      <td className="muted">{shortDate(c.createdAt)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
          <Pagination page={data.page} pages={data.pages} onPage={(p) => { const n = new URLSearchParams(sp); n.set("page", String(p)); setSp(n); }} />
        </>
      )}

      <Modal open={!!detail} title={detail?.name ?? ""} onClose={() => setDetail(null)} wide>
        {detail && (
          <div className="stack">
            <dl className="kv">
              <dt>Email</dt><dd><a href={`mailto:${detail.email}`}>{detail.email}</a></dd>
              <dt>Mobile</dt><dd>{detail.phone || "—"}</dd>
              <dt>Joined</dt><dd>{shortDate(detail.createdAt)}</dd>
            </dl>
            {detail.phone && (
              <div className="contact-actions" style={{ marginTop: 0 }}>
                <a href={phoneLink(detail.phone)} className="btn btn-quiet btn-sm"><Icon name="phone" size={16} />Call</a>
                <a href={whatsappLink(detail.phone)} target="_blank" rel="noreferrer" className="btn btn-quiet btn-sm"><Icon name="chat" size={16} />WhatsApp</a>
              </div>
            )}
            <h3 style={{ fontSize: 16 }}>Orders ({detail.orders.length})</h3>
            {detail.orders.length ? (
              <div className="table-scroll">
                <table className="table">
                  <thead><tr><th>Order</th><th className="num">Total</th><th>Status</th><th>Placed</th></tr></thead>
                  <tbody>{detail.orders.map((o) => <tr key={o.id}><td><Link to={`/admin/orders/${o.id}`}>{o.orderNo}</Link></td><td className="num">{lkr(o.total)}</td><td><StatusPill status={o.status} /></td><td className="muted">{shortDate(o.createdAt)}</td></tr>)}</tbody>
                </table>
              </div>
            ) : <p className="muted">No orders yet.</p>}
          </div>
        )}
      </Modal>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\admin\Dashboard.tsx' @'
import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../../api/client";
import type { DashboardData } from "../../api/types";
import { dateTime, lkr } from "../../api/format";
import Icon from "../../components/Icon";
import BarChart from "../../components/BarChart";
import { ErrorState, PageLoading, StatusPill } from "../../components/ui";

export default function Dashboard() {
  const [d, setD] = useState<DashboardData | null>(null);
  const [err, setErr] = useState("");

  const load = () => { setErr(""); api.admin.dashboard().then(setD).catch((e) => setErr((e as Error).message)); };
  useEffect(load, []);

  if (err) return <ErrorState message={err} onRetry={load} />;
  if (!d) return <PageLoading label="Loading dashboard…" />;

  const today = new Date().toLocaleDateString("en-GB", { weekday: "long", day: "numeric", month: "long" });
  const weekTotal = d.last7Days.reduce((s, x) => s + x.sales, 0);
  const bars = d.last7Days.map((x, i) => {
    const date = new Date(`${x.date}T00:00:00`);
    return {
      key: x.date,
      label: i === d.last7Days.length - 1 ? "Today" : date.toLocaleDateString("en-GB", { weekday: "short" }),
      fullLabel: date.toLocaleDateString("en-GB", { weekday: "long", day: "numeric", month: "short" }),
      value: x.sales, orders: x.orders, highlight: i === d.last7Days.length - 1,
    };
  });

  return (
    <div className="admin-page">
      <div className="admin-head">
        <div><h1>Dashboard</h1><p>{today}</p></div>
        <div className="admin-head-actions">
          <Link to="/admin/orders" className="btn btn-quiet">View orders</Link>
          <Link to="/admin/products/new" className="btn btn-primary"><Icon name="plus" size={18} />Add product</Link>
        </div>
      </div>

      <section className="stats" aria-label="Today">
        <div className="stat stat-hero">
          <span className="stat-label">Today's sales</span>
          <span className="stat-value">{lkr(d.todaySales)}</span>
          <span className="stat-note">{d.todayOrders} {d.todayOrders === 1 ? "order" : "orders"} today</span>
        </div>
        <Link to="/admin/orders?status=PENDING" className="stat stat-link">
          <span className="stat-label">Waiting to confirm</span>
          <span className="stat-value">{d.pending}</span>
          <span className="stat-note">{d.pending ? "Review pending orders" : "All caught up"}</span>
        </Link>
        <Link to="/admin/orders?status=PROCESSING" className="stat">
          <span className="stat-label">In progress</span>
          <span className="stat-value">{d.processing}</span>
          <span className="stat-note">Confirmed to dispatched</span>
        </Link>
        <div className="stat">
          <span className="stat-label">Delivered today</span>
          <span className="stat-value">{d.completed}</span>
          <span className="stat-note">Completed orders</span>
        </div>
      </section>

      <div className="dash-grid">
        <section className="panel">
          <div className="panel-head"><h2>Sales, last 7 days</h2><span className="panel-meta">{lkr(weekTotal)} total</span></div>
          <BarChart bars={bars} caption="Daily sales for the last 7 days" />
        </section>

        <section className="panel">
          <div className="panel-head"><h2>Low stock</h2><Link to="/admin/products?show=low" className="panel-link">Manage stock</Link></div>
          {d.lowStock.length ? (
            <ul className="stock-list">
              {d.lowStock.map((p) => (
                <li key={p.id}>
                  <Link to={`/admin/products/${p.id}`} className="stock-name" style={{ color: "var(--ink)", textDecoration: "none" }}>{p.name}<span className="muted">{p.code}</span></Link>
                  <span className={`stock-count ${p.stock === 0 ? "is-out" : ""}`}>{p.stock === 0 ? <><Icon name="alert" size={14} />Sold out</> : `${p.stock} left`}</span>
                </li>
              ))}
            </ul>
          ) : <p className="empty-note">Every product has more than 3 in stock.</p>}
        </section>

        <section className="panel panel-wide panel-flush">
          <div className="panel-head" style={{ padding: "22px 22px 0" }}><h2>Recent orders</h2><Link to="/admin/orders" className="panel-link">All orders</Link></div>
          {d.recentOrders.length ? (
            <div className="table-scroll">
              <table className="table">
                <thead><tr><th>Order</th><th>Customer</th><th className="num">Total</th><th>Status</th><th>Placed</th></tr></thead>
                <tbody>
                  {d.recentOrders.map((o) => (
                    <tr key={o.id}>
                      <td><Link to={`/admin/orders/${o.id}`}>{o.orderNo}</Link></td>
                      <td>{o.fullName}</td>
                      <td className="num">{lkr(o.total)}</td>
                      <td><StatusPill status={o.status} /></td>
                      <td className="muted">{dateTime(o.createdAt)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : <p className="empty-note">No orders yet. New orders from the shop appear here.</p>}
        </section>
      </div>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\admin\Offers.tsx' @'
import { FormEvent, useEffect, useState } from "react";
import { api } from "../../api/client";
import type { Category, Offer, Product } from "../../api/types";
import { shortDate } from "../../api/format";
import { useToast } from "../../context/ToastContext";
import Icon from "../../components/Icon";
import { ConfirmDialog, EmptyState, ErrorState, Modal, PageLoading, Switch } from "../../components/ui";

type Scope = "shop" | "category" | "product";
const toInput = (iso?: string) => (iso ? new Date(iso).toISOString().slice(0, 10) : "");
const today = () => new Date().toISOString().slice(0, 10);
const plus = (days: number) => { const d = new Date(); d.setDate(d.getDate() + days); return d.toISOString().slice(0, 10); };

function offerState(o: Offer) {
  const now = Date.now();
  if (!o.isActive) return { label: "Off", cls: "pill-off" };
  if (new Date(o.startsAt).getTime() > now) return { label: "Scheduled", cls: "pill-confirmed" };
  if (new Date(o.endsAt).getTime() < now) return { label: "Ended", cls: "pill-off" };
  return { label: "Live", cls: "pill-on" };
}

export default function Offers() {
  const { show } = useToast();
  const [offers, setOffers] = useState<Offer[] | null>(null);
  const [cats, setCats] = useState<Category[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [err, setErr] = useState("");
  const [editing, setEditing] = useState<Offer | "new" | null>(null);
  const [scope, setScope] = useState<Scope>("shop");
  const [formErr, setFormErr] = useState("");
  const [busy, setBusy] = useState(false);
  const [deleting, setDeleting] = useState<Offer | null>(null);

  const load = () => { setErr(""); api.admin.offers().then(setOffers).catch((e) => setErr((e as Error).message)); };
  useEffect(() => {
    load();
    api.categories().then(setCats).catch(() => undefined);
    api.admin.products({ show: "active" }).then(async (first) => {
      const rest = await Promise.all(Array.from({ length: Math.min(first.pages, 10) - 1 }, (_, i) => api.admin.products({ show: "active", page: i + 2 })));
      setProducts([...first.items, ...rest.flatMap((r) => r.items)]);
    }).catch(() => undefined);
  }, []);

  const open = (o: Offer | "new") => {
    setFormErr("");
    setScope(o !== "new" && o.productId ? "product" : o !== "new" && o.categoryId ? "category" : "shop");
    setEditing(o);
  };

  const save = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    const body = {
      title: f.get("title"), percentOff: Number(f.get("percentOff")),
      startsAt: new Date(`${f.get("startsAt")}T00:00:00`).toISOString(),
      endsAt: new Date(`${f.get("endsAt")}T23:59:59`).toISOString(),
      isActive: !!f.get("isActive"),
      productId: scope === "product" ? f.get("productId") : null,
      categoryId: scope === "category" ? f.get("categoryId") : null,
    };
    setBusy(true); setFormErr("");
    try { await api.admin.saveOffer(body, editing === "new" ? undefined : editing!.id); show("Offer saved"); setEditing(null); load(); }
    catch (e) { setFormErr((e as Error).message); } finally { setBusy(false); }
  };
  const remove = async () => {
    setBusy(true);
    try { await api.admin.deleteOffer(deleting!.id); show("Offer deleted"); setDeleting(null); load(); }
    catch (e) { show((e as Error).message, { kind: "error" }); } finally { setBusy(false); }
  };

  const cur = editing && editing !== "new" ? editing : null;

  return (
    <div className="admin-page">
      <div className="admin-head">
        <div><h1>Offers</h1><p>Discounts show on product cards and are applied in the cart. If two offers cover a piece, the bigger one wins.</p></div>
        <button className="btn btn-primary" onClick={() => open("new")}><Icon name="plus" size={18} />Create offer</button>
      </div>

      {err ? <ErrorState message={err} onRetry={load} /> : !offers ? <PageLoading /> : !offers.length ? (
        <div className="panel"><EmptyState icon="offers" title="No offers yet" action={<button className="btn btn-primary" onClick={() => open("new")}>Create an offer</button>}>Run a sale on one piece, a whole category or the entire shop.</EmptyState></div>
      ) : (
        <div className="panel panel-flush">
          <div className="table-scroll">
            <table className="table">
              <thead><tr><th>Offer</th><th className="num">Discount</th><th>Applies to</th><th>Dates</th><th>Status</th><th><span className="sr-only">Actions</span></th></tr></thead>
              <tbody>
                {offers.map((o) => {
                  const st = offerState(o);
                  return (
                    <tr key={o.id}>
                      <td><strong>{o.title}</strong></td>
                      <td className="num">{o.percentOff}%</td>
                      <td>{o.product ? `${o.product.name} (${o.product.code})` : o.category ? `All ${o.category.name.toLowerCase()}` : "Whole shop"}</td>
                      <td className="muted">{shortDate(o.startsAt)} – {shortDate(o.endsAt)}</td>
                      <td><span className={`pill ${st.cls}`}>{st.label}</span></td>
                      <td><div className="row-actions">
                        <button className="icon-btn" aria-label={`Edit ${o.title}`} onClick={() => open(o)}><Icon name="edit" size={18} /></button>
                        <button className="icon-btn" aria-label={`Delete ${o.title}`} onClick={() => setDeleting(o)}><Icon name="trash" size={18} /></button>
                      </div></td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      <Modal open={!!editing} title={editing === "new" ? "Create offer" : "Edit offer"} onClose={() => setEditing(null)}>
        {editing && (
          <form className="form" onSubmit={save}>
            <label className="field"><span className="field-label">Title</span><input name="title" required maxLength={80} defaultValue={cur?.title} placeholder="Avurudu sale" autoFocus /><span className="field-hint">Shown on the product page</span></label>
            <label className="field"><span className="field-label">Discount (%)</span><input name="percentOff" type="number" required min={1} max={90} defaultValue={cur?.percentOff ?? 10} /></label>
            <fieldset className="fieldset">
              <legend>Applies to</legend>
              <div className="chips">
                {(["shop", "category", "product"] as Scope[]).map((s) => (
                  <button key={s} type="button" className="chip" aria-pressed={scope === s} onClick={() => setScope(s)}>{s === "shop" ? "Whole shop" : s === "category" ? "A category" : "One product"}</button>
                ))}
              </div>
              {scope === "category" && (
                <label className="field"><span className="sr-only">Category</span>
                  <select name="categoryId" required defaultValue={cur?.categoryId ?? ""}><option value="" disabled>Choose a category</option>{cats.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}</select>
                </label>
              )}
              {scope === "product" && (
                <label className="field"><span className="sr-only">Product</span>
                  <select name="productId" required defaultValue={cur?.productId ?? ""}><option value="" disabled>Choose a product</option>{products.map((p) => <option key={p.id} value={p.id}>{p.name} ({p.code})</option>)}</select>
                </label>
              )}
            </fieldset>
            <div className="form-grid">
              <label className="field"><span className="field-label">Starts</span><input name="startsAt" type="date" required defaultValue={toInput(cur?.startsAt) || today()} /></label>
              <label className="field"><span className="field-label">Ends</span><input name="endsAt" type="date" required defaultValue={toInput(cur?.endsAt) || plus(14)} /></label>
            </div>
            <Switch name="isActive" label="Offer is on" hint="Turn off to pause it without deleting" defaultChecked={cur?.isActive ?? true} />
            {formErr && <p className="form-error" role="alert">{formErr}</p>}
            <div className="modal-foot" style={{ margin: "4px -24px -24px" }}>
              <button type="button" className="btn btn-secondary" onClick={() => setEditing(null)}>Cancel</button>
              <button className="btn btn-primary" disabled={busy}>{busy ? "Saving…" : "Save offer"}</button>
            </div>
          </form>
        )}
      </Modal>

      <ConfirmDialog open={!!deleting} danger title="Delete this offer?" confirmLabel="Delete offer" busy={busy} onConfirm={remove} onClose={() => setDeleting(null)}
        body={<>{deleting?.title} will stop applying straight away. Past orders keep the price they were charged.</>} />
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\admin\OrderDetail.tsx' @'
import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { api } from "../../api/client";
import type { Order, OrderStatus, PaymentStatus } from "../../api/types";
import { dateTime, deliveryLabel, lkr, paymentLabel, paymentStatusLabel, phoneLink, statusLabel, whatsappLink } from "../../api/format";
import { useSettings } from "../../context/SettingsContext";
import { useToast } from "../../context/ToastContext";
import Icon from "../../components/Icon";
import { ConfirmDialog, ErrorState, PageLoading, ProductImage, StatusPill } from "../../components/ui";

const actionLabel: Record<OrderStatus, string> = {
  PENDING: "Pending", CONFIRMED: "Confirm order", PROCESSING: "Start processing", READY: "Mark ready",
  DISPATCHED: "Mark dispatched", DELIVERED: "Mark delivered", CANCELLED: "Cancel order",
};

export default function AdminOrderDetail() {
  const { id } = useParams();
  const s = useSettings();
  const { show } = useToast();
  const [o, setO] = useState<Order | null>(null);
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);
  const [cancelling, setCancelling] = useState(false);

  const load = () => { setErr(""); api.admin.order(id!).then(setO).catch((e) => setErr((e as Error).message)); };
  useEffect(load, [id]); // eslint-disable-line react-hooks/exhaustive-deps

  if (err && !o) return <ErrorState message={err} onRetry={load} />;
  if (!o) return <PageLoading />;

  const move = async (to: OrderStatus) => {
    setBusy(true);
    try { await api.admin.setStatus(o.id, to); show(`Order ${statusLabel[to].toLowerCase()}`); setCancelling(false); load(); }
    catch (e) { show((e as Error).message, { kind: "error" }); }
    finally { setBusy(false); }
  };
  const pay = async (ps: PaymentStatus) => {
    try { await api.admin.setPayment(o.id, ps); show(`Payment marked ${paymentStatusLabel[ps].toLowerCase()}`); load(); }
    catch (e) { show((e as Error).message, { kind: "error" }); }
  };

  const actions = (o.nextStatuses ?? []).filter((st) => st !== "CANCELLED");
  const labelFor = (st: OrderStatus) => (st === "DELIVERED" && o.deliveryMethod === "PICKUP" ? "Mark collected" : actionLabel[st]);
  const canCancel = o.nextStatuses?.includes("CANCELLED");
  const msg = `Hi ${o.fullName.split(" ")[0]}, this is ${s.shopName.replace(/^\[|\]$/g, "")} about your order ${o.orderNo}.`;
  const history = o.history ?? [];

  return (
    <div className="admin-page">
      <div className="admin-head">
        <div>
          <Link to="/admin/orders" className="back-link no-print"><Icon name="arrowLeft" size={16} />Orders</Link>
          <h1 style={{ display: "flex", gap: 14, alignItems: "center", flexWrap: "wrap" }}>{o.orderNo} <StatusPill status={o.status} /></h1>
          <p>Placed {dateTime(o.createdAt)}</p>
        </div>
        <div className="admin-head-actions no-print">
          <button className="btn btn-quiet" onClick={() => window.print()}><Icon name="print" size={18} />Print packing slip</button>
        </div>
      </div>

      <div className="print-only"><strong>{s.shopName}</strong>{s.phone && ` · ${s.phone}`}{s.address && ` · ${s.address}`}</div>

      <div className="detail-grid">
        <div className="stack">
          <section className="panel">
            <div className="panel-head"><h2>Items</h2><span className="panel-meta">{o.items.reduce((n, i) => n + i.qty, 0)} pieces</span></div>
            <div className="order-lines">
              {o.items.map((i) => (
                <div key={i.id} className="order-line">
                  <span className="order-line-img"><ProductImage url={i.product?.images[0]?.url} alt="" /></span>
                  <span>
                    <strong>{i.name}</strong> <span className="muted">× {i.qty}</span>
                    <span className="muted" style={{ display: "block", fontSize: 13 }}>{i.product?.code ? `Code ${i.product.code} · ` : ""}{lkr(i.price)} each</span>
                  </span>
                  <span className="num">{lkr(i.price * i.qty)}</span>
                </div>
              ))}
            </div>
            <div className="order-totals">
              <div className="summary-row"><span>Subtotal</span><span>{lkr(o.subtotal)}</span></div>
              <div className="summary-row"><span>{deliveryLabel[o.deliveryMethod]}</span><span>{o.deliveryFee ? lkr(o.deliveryFee) : "Free"}</span></div>
              <div className="summary-row summary-total"><span>Total</span><span>{lkr(o.total)}</span></div>
            </div>
          </section>

          {o.note && (
            <section className="panel"><h2 style={{ fontSize: 22, marginBottom: 10 }}>Customer note</h2><p style={{ whiteSpace: "pre-line" }}>{o.note}</p></section>
          )}

          <section className="panel no-print">
            <h2 style={{ fontSize: 22, marginBottom: 16 }}>History</h2>
            <ol className="timeline">
              {history.map((h, i) => (
                <li key={h.id} className={`tl-step ${i === history.length - 1 ? "is-current" : "is-done"}`}>
                  <span className="tl-dot">{i < history.length - 1 && <Icon name="check" size={16} />}</span>
                  <span className="tl-text"><strong>{statusLabel[h.status]}</strong><span>{dateTime(h.createdAt)}</span></span>
                </li>
              ))}
            </ol>
          </section>
        </div>

        <div className="detail-side">
          {(actions.length > 0 || canCancel) && (
            <section className="panel no-print">
              <h2 style={{ fontSize: 22, marginBottom: 14 }}>Next step</h2>
              <div className="status-actions">
                {actions.map((st, i) => (
                  <button key={st} className={`btn ${i === 0 ? "btn-primary" : "btn-secondary"} btn-block`} disabled={busy} onClick={() => move(st)}>{labelFor(st)}</button>
                ))}
                {canCancel && <button className="btn-link" style={{ color: "var(--error)" }} onClick={() => setCancelling(true)}>Cancel order</button>}
              </div>
            </section>
          )}

          <section className="panel">
            <h2 style={{ fontSize: 22, marginBottom: 14 }}>Customer</h2>
            <dl className="kv">
              <dt>Name</dt><dd>{o.fullName}</dd>
              <dt>Mobile</dt><dd>{o.mobile}</dd>
              {o.whatsapp && <><dt>WhatsApp</dt><dd>{o.whatsapp}</dd></>}
              {o.email && <><dt>Email</dt><dd>{o.email}</dd></>}
              <dt>Account</dt><dd>{o.user ? <Link to={`/admin/customers?q=${encodeURIComponent(o.user.email)}`}>{o.user.email}</Link> : "Guest"}</dd>
            </dl>
            <div className="contact-actions no-print">
              <a href={phoneLink(o.mobile)} className="btn btn-quiet btn-sm"><Icon name="phone" size={16} />Call</a>
              <a href={whatsappLink(o.whatsapp || o.mobile, msg)} target="_blank" rel="noreferrer" className="btn btn-quiet btn-sm"><Icon name="chat" size={16} />WhatsApp</a>
            </div>
          </section>

          <section className="panel">
            <h2 style={{ fontSize: 22, marginBottom: 14 }}>Delivery</h2>
            <dl className="kv">
              <dt>Method</dt><dd>{deliveryLabel[o.deliveryMethod]}</dd>
              {o.deliveryMethod === "DELIVERY" && <><dt>Address</dt><dd style={{ whiteSpace: "pre-line" }}>{[o.address, o.city, o.postalCode].filter(Boolean).join("\n")}</dd></>}
            </dl>
          </section>

          <section className="panel">
            <h2 style={{ fontSize: 22, marginBottom: 14 }}>Payment</h2>
            <dl className="kv">
              <dt>Method</dt><dd>{paymentLabel[o.paymentMethod]}</dd>
              <dt>Status</dt><dd><span className={`pill pill-${o.paymentStatus.toLowerCase()}`}>{paymentStatusLabel[o.paymentStatus]}</span></dd>
            </dl>
            <div className="contact-actions no-print">
              {o.paymentStatus !== "PAID" && <button className="btn btn-secondary btn-sm" onClick={() => pay("PAID")}><Icon name="check" size={16} />Mark as paid</button>}
              {o.paymentStatus === "PAID" && <button className="btn btn-quiet btn-sm" onClick={() => pay("UNPAID")}>Mark as not paid</button>}
              {o.paymentStatus === "PAID" && o.status === "CANCELLED" && <button className="btn btn-quiet btn-sm" onClick={() => pay("REFUNDED")}>Mark refunded</button>}
            </div>
          </section>
        </div>
      </div>

      <ConfirmDialog open={cancelling} danger title="Cancel this order?" confirmLabel="Cancel order" busy={busy} onConfirm={() => move("CANCELLED")} onClose={() => setCancelling(false)}
        body={<>The items go back into stock and the customer is told the order is cancelled.{o.paymentStatus === "PAID" && " This order is marked as paid, so arrange a refund."}</>} />
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\admin\Orders.tsx' @'
import { FormEvent, useEffect, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { api } from "../../api/client";
import type { OrderStatus, OrdersPage } from "../../api/types";
import { dateTime, deliveryLabel, lkr, paymentLabel, statusLabel } from "../../api/format";
import Icon from "../../components/Icon";
import { EmptyState, ErrorState, PageLoading, Pagination, StatusPill } from "../../components/ui";

const tabs: (OrderStatus | "")[] = ["", "PENDING", "CONFIRMED", "PROCESSING", "READY", "DISPATCHED", "DELIVERED", "CANCELLED"];

export default function AdminOrders() {
  const [sp, setSp] = useSearchParams();
  const [data, setData] = useState<OrdersPage | null>(null);
  const [err, setErr] = useState("");
  const status = (sp.get("status") ?? "") as OrderStatus | "";

  const load = () => {
    setErr("");
    api.admin.orders({ status: status || undefined, q: sp.get("q"), page: sp.get("page") ?? 1 }).then(setData).catch((e) => setErr((e as Error).message));
  };
  useEffect(load, [sp]); // eslint-disable-line react-hooks/exhaustive-deps

  const set = (k: string, v: string | null) => {
    const n = new URLSearchParams(sp);
    v ? n.set(k, v) : n.delete(k);
    if (k !== "page") n.delete("page");
    setSp(n);
  };
  const search = (e: FormEvent<HTMLFormElement>) => { e.preventDefault(); set("q", String(new FormData(e.currentTarget).get("q") || "") || null); };
  const all = data ? Object.values(data.byStatus).reduce((s, n) => s + (n ?? 0), 0) : 0;

  return (
    <div className="admin-page">
      <div className="admin-head"><div><h1>Orders</h1><p>{data ? `${data.total} ${status ? statusLabel[status].toLowerCase() : ""} ${data.total === 1 ? "order" : "orders"}` : " "}</p></div></div>

      <div className="tabs" role="group" aria-label="Filter by status">
        {tabs.map((t) => (
          <button key={t || "all"} className="tab" aria-pressed={status === t} onClick={() => set("status", t || null)}>
            {t ? statusLabel[t] : "All"}
            {data && <span className="tab-count">{t ? data.byStatus[t] ?? 0 : all}</span>}
          </button>
        ))}
      </div>
      <div className="toolbar">
        <form className="search" role="search" onSubmit={search}>
          <Icon name="search" size={18} />
          <label htmlFor="o-search" className="sr-only">Search orders</label>
          <input id="o-search" name="q" type="search" placeholder="Order number, name or mobile" defaultValue={sp.get("q") ?? ""} />
        </form>
        {sp.get("q") && <button className="btn-link" onClick={() => set("q", null)} style={{ fontSize: 14 }}>Clear search</button>}
      </div>

      {err ? <ErrorState message={err} onRetry={load} /> : !data ? <PageLoading /> : !data.items.length ? (
        <div className="panel"><EmptyState icon="orders" title={sp.get("q") ? "No orders match" : status ? `No ${statusLabel[status].toLowerCase()} orders` : "No orders yet"}>{sp.get("q") ? "Check the order number or mobile number." : "Orders from the shop appear here."}</EmptyState></div>
      ) : (
        <>
          <div className="panel panel-flush">
            <div className="table-scroll">
              <table className="table">
                <thead><tr><th>Order</th><th>Customer</th><th>Items</th><th className="num">Total</th><th>Payment</th><th>Delivery</th><th>Status</th><th>Placed</th></tr></thead>
                <tbody>
                  {data.items.map((o) => (
                    <tr key={o.id}>
                      <td><Link to={`/admin/orders/${o.id}`}>{o.orderNo}</Link></td>
                      <td>{o.fullName}<span className="muted" style={{ display: "block", fontSize: 13 }}>{o.mobile}</span></td>
                      <td>{o._count?.items ?? o.items?.length}</td>
                      <td className="num">{lkr(o.total)}</td>
                      <td>{paymentLabel[o.paymentMethod]}<span style={{ display: "block", marginTop: 4 }}><span className={`pill pill-${o.paymentStatus.toLowerCase()}`}>{o.paymentStatus === "PAID" ? "Paid" : o.paymentStatus === "REFUNDED" ? "Refunded" : "Not paid"}</span></span></td>
                      <td>{deliveryLabel[o.deliveryMethod]}{o.city && <span className="muted" style={{ display: "block", fontSize: 13 }}>{o.city}</span>}</td>
                      <td><StatusPill status={o.status} /></td>
                      <td className="muted">{dateTime(o.createdAt)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
          <Pagination page={data.page} pages={data.pages} onPage={(p) => set("page", String(p))} />
        </>
      )}
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\admin\ProductForm.tsx' @'
import { FormEvent, useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { api } from "../../api/client";
import type { Category, JewelleryType, Product, ProductImage as Img } from "../../api/types";
import { jewelleryTypes, typeLabel } from "../../api/format";
import { useToast } from "../../context/ToastContext";
import Icon from "../../components/Icon";
import { ErrorState, PageLoading, Switch } from "../../components/ui";

type NewFile = { file: File; url: string };
const okType = (f: File) => /image\/(jpeg|png|webp)/.test(f.type) && f.size <= 8 * 1024 * 1024;

export default function ProductForm() {
  const { id } = useParams();
  const isNew = !id;
  const nav = useNavigate();
  const { show } = useToast();
  const [p, setP] = useState<Product | null>(null);
  const [cats, setCats] = useState<Category[]>([]);
  const [images, setImages] = useState<Img[]>([]);
  const [files, setFiles] = useState<NewFile[]>([]);
  const [asset, setAsset] = useState<NewFile | null>(null);
  const [type, setType] = useState<JewelleryType>("EARRINGS");
  const [loadErr, setLoadErr] = useState("");
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    api.categories().then(setCats).catch(() => undefined);
    if (isNew) return;
    api.admin.product(id!).then((prod) => { setP(prod); setImages(prod.images); setType(prod.jewelleryType); }).catch((e) => setLoadErr((e as Error).message));
  }, [id, isNew]);

  useEffect(() => () => { files.forEach((f) => URL.revokeObjectURL(f.url)); if (asset) URL.revokeObjectURL(asset.url); }, []); // eslint-disable-line react-hooks/exhaustive-deps

  if (loadErr) return <ErrorState message={loadErr} />;
  if (!isNew && !p) return <PageLoading />;

  const addFiles = (list: FileList | null) => {
    if (!list) return;
    const good = Array.from(list).filter(okType);
    if (good.length < list.length) show("Some files were skipped. Use JPG, PNG or WebP up to 8 MB.", { kind: "error" });
    setFiles((prev) => [...prev, ...good.map((file) => ({ file, url: URL.createObjectURL(file) }))].slice(0, 10));
  };
  const removeNew = (i: number) => setFiles((prev) => { URL.revokeObjectURL(prev[i].url); return prev.filter((_, j) => j !== i); });

  const deleteImage = async (img: Img) => {
    try { await api.admin.deleteImage(p!.id, img.id); setImages((prev) => prev.filter((x) => x.id !== img.id)); show("Photo removed"); }
    catch (e) { show((e as Error).message, { kind: "error" }); }
  };
  const makeMain = async (img: Img) => {
    const order = [img.id, ...images.filter((x) => x.id !== img.id).map((x) => x.id)];
    try { await api.admin.orderImages(p!.id, order); setImages((prev) => [img, ...prev.filter((x) => x.id !== img.id)]); show("Main photo updated"); }
    catch (e) { show((e as Error).message, { kind: "error" }); }
  };
  const removeAsset = async () => {
    if (asset) { URL.revokeObjectURL(asset.url); setAsset(null); return; }
    try { await api.admin.removeTryOnAsset(p!.id); setP({ ...p!, tryOnAssetUrl: null }); show("Try-on image removed"); }
    catch (e) { show((e as Error).message, { kind: "error" }); }
  };

  const submit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);
    for (const k of ["isActive", "isNewArrival", "tryOnEnabled"]) fd.set(k, fd.get(k) ? "true" : "false");
    fd.delete("imagesPicker"); fd.delete("assetPicker");
    files.forEach((f) => fd.append("images", f.file));
    if (asset) fd.set("tryOnAsset", asset.file);
    setBusy(true); setErr("");
    try {
      const saved = await api.admin.saveProduct(fd, id);
      show(isNew ? `${saved.name} added to the shop` : "Changes saved");
      nav(isNew ? "/admin/products" : `/admin/products`, { replace: isNew });
    } catch (e) {
      setErr((e as Error).message);
      window.scrollTo({ top: 0, behavior: "smooth" });
    } finally { setBusy(false); }
  };

  const assetUrl = asset?.url ?? p?.tryOnAssetUrl;

  return (
    <form className="admin-page" onSubmit={submit}>
      <div className="admin-head">
        <div>
          <Link to="/admin/products" className="back-link"><Icon name="arrowLeft" size={16} />Products</Link>
          <h1>{isNew ? "Add product" : p!.name}</h1>
        </div>
        {!isNew && p!.isActive && <a href={`/product/${p!.slug}`} target="_blank" rel="noreferrer" className="btn btn-quiet"><Icon name="eye" size={18} />View in shop</a>}
      </div>
      {err && <p className="form-error" role="alert">{err}</p>}

      <div className="admin-form">
        <div className="admin-form-main">
          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>Details</h2>
            <div className="form-grid">
              <label className="field span-2"><span className="field-label">Product name</span><input name="name" required minLength={2} maxLength={120} defaultValue={p?.name} placeholder="Gold jhumka earrings" /></label>
              <label className="field"><span className="field-label">Product code</span><input name="code" required maxLength={30} defaultValue={p?.code} placeholder="ER025" autoCapitalize="characters" /></label>
              <label className="field"><span className="field-label">Category</span>
                <select name="categoryId" required defaultValue={p?.categoryId ?? ""}>
                  <option value="" disabled>Choose a category</option>
                  {cats.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
                </select>
              </label>
              <label className="field span-2"><span className="field-label">Description</span><textarea name="description" rows={5} maxLength={4000} defaultValue={p?.description ?? ""} placeholder="Materials, size, finish and how to care for it" /></label>
              <label className="field"><span className="field-label">Style <span className="optional">(optional)</span></span><input name="style" maxLength={40} defaultValue={p?.style ?? ""} placeholder="Traditional, Modern…" /><span className="field-hint">Shown as a filter in the shop</span></label>
              <label className="field"><span className="field-label">Colour <span className="optional">(optional)</span></span><input name="colour" maxLength={40} defaultValue={p?.colour ?? ""} placeholder="Gold, Silver, Rose gold…" /></label>
            </div>
          </section>

          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>Photos</h2>
            <p className="field-hint" style={{ marginTop: -8 }}>The first photo is the main one in the shop. JPG, PNG or WebP, up to 8 MB each.</p>
            <div className="image-manager">
              {images.map((img, i) => (
                <div key={img.id} className="im-tile">
                  <img src={img.url} alt={`Photo ${i + 1}`} />
                  {i === 0 && <span className="im-tile-main">Main</span>}
                  <div className="im-tile-actions">
                    {i > 0 && <button type="button" className="icon-btn" aria-label={`Make photo ${i + 1} the main photo`} title="Make main" onClick={() => makeMain(img)}><Icon name="check" size={16} /></button>}
                    <button type="button" className="icon-btn" aria-label={`Remove photo ${i + 1}`} title="Remove" onClick={() => deleteImage(img)}><Icon name="trash" size={16} /></button>
                  </div>
                </div>
              ))}
              {files.map((f, i) => (
                <div key={f.url} className="im-tile">
                  <img src={f.url} alt={`New photo ${i + 1}`} />
                  <span className={images.length === 0 && i === 0 ? "im-tile-main" : "im-tile-new"}>{images.length === 0 && i === 0 ? "Main" : "New"}</span>
                  <div className="im-tile-actions"><button type="button" className="icon-btn" aria-label={`Remove new photo ${i + 1}`} onClick={() => removeNew(i)}><Icon name="close" size={16} /></button></div>
                </div>
              ))}
              {images.length + files.length < 10 && (
                <label className="im-add">
                  <Icon name="image" size={24} />Add photos
                  <input name="imagesPicker" type="file" accept="image/jpeg,image/png,image/webp" multiple onChange={(e) => { addFiles(e.target.files); e.target.value = ""; }} />
                </label>
              )}
            </div>
          </section>

          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>AI try-on</h2>
            <Switch name="tryOnEnabled" label="Customers can try this on with AI" defaultChecked={p?.tryOnEnabled ?? true} />
            <label className="field"><span className="field-label">Jewellery type</span>
              <select name="jewelleryType" value={type} onChange={(e) => setType(e.target.value as JewelleryType)}>
                {jewelleryTypes.map((t) => <option key={t} value={t}>{typeLabel[t]}</option>)}
              </select>
              <span className="field-hint">Tells the AI where the piece is worn, for example earrings on the earlobes.</span>
            </label>
            <div className="field">
              <span className="field-label">Try-on image <span className="optional">(optional)</span></span>
              <div className="asset-row">
                <span className="asset-preview">{assetUrl ? <img src={assetUrl} alt="Try-on image" /> : <Icon name="image" size={28} />}</span>
                <div className="stack" style={{ gap: 8 }}>
                  <span className="field-hint">A PNG of just the piece on a transparent background gives the best results. Without one, the main photo is used.</span>
                  <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                    <label className="btn btn-quiet btn-sm">
                      <Icon name="upload" size={16} />{assetUrl ? "Replace" : "Upload PNG"}
                      <input name="assetPicker" type="file" accept="image/png,image/webp" className="sr-only" onChange={(e) => { const f = e.target.files?.[0]; if (f && okType(f)) setAsset({ file: f, url: URL.createObjectURL(f) }); e.target.value = ""; }} />
                    </label>
                    {assetUrl && <button type="button" className="btn btn-quiet btn-sm" onClick={removeAsset}>Remove</button>}
                  </div>
                </div>
              </div>
            </div>
          </section>
        </div>

        <div className="admin-form-side">
          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>Price and stock</h2>
            <label className="field"><span className="field-label">Price (LKR)</span><input name="price" type="number" required min={1} step={1} inputMode="numeric" defaultValue={p?.price} /></label>
            <label className="field"><span className="field-label">Stock</span><input name="stock" type="number" required min={0} step={1} inputMode="numeric" defaultValue={p?.stock ?? 1} /><span className="field-hint">Shows as sold out at 0</span></label>
          </section>
          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>Visibility</h2>
            <Switch name="isActive" label="Show in the shop" defaultChecked={p?.isActive ?? true} />
            <Switch name="isNewArrival" label="Show in New arrivals" defaultChecked={p?.isNewArrival ?? true} />
          </section>
        </div>
      </div>

      <div className="save-bar">
        <Link to="/admin/products" className="btn btn-quiet">Cancel</Link>
        <button className="btn btn-primary" disabled={busy}>{busy ? "Saving…" : isNew ? "Add product" : "Save changes"}</button>
      </div>
    </form>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\admin\Products.tsx' @'
import { FormEvent, useEffect, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { api } from "../../api/client";
import type { Category, Paged, Product } from "../../api/types";
import { lkr } from "../../api/format";
import { useToast } from "../../context/ToastContext";
import Icon from "../../components/Icon";
import { ConfirmDialog, EmptyState, ErrorState, PageLoading, Pagination, ProductImage } from "../../components/ui";

const shows = [
  { v: "all", label: "All" },
  { v: "active", label: "In the shop" },
  { v: "low", label: "Low stock" },
  { v: "hidden", label: "Hidden" },
];

export default function AdminProducts() {
  const [sp, setSp] = useSearchParams();
  const { show } = useToast();
  const [data, setData] = useState<Paged<Product> | null>(null);
  const [cats, setCats] = useState<Category[]>([]);
  const [err, setErr] = useState("");
  const [hiding, setHiding] = useState<Product | null>(null);
  const [busy, setBusy] = useState(false);

  const load = () => {
    setErr("");
    api.admin.products({ q: sp.get("q"), categoryId: sp.get("category"), show: sp.get("show") ?? "all", page: sp.get("page") ?? 1 })
      .then(setData).catch((e) => setErr((e as Error).message));
  };
  useEffect(load, [sp]);
  useEffect(() => { api.categories().then(setCats).catch(() => undefined); }, []);

  const set = (k: string, v: string | null) => {
    const n = new URLSearchParams(sp);
    v ? n.set(k, v) : n.delete(k);
    if (k !== "page") n.delete("page");
    setSp(n);
  };
  const search = (e: FormEvent<HTMLFormElement>) => { e.preventDefault(); set("q", String(new FormData(e.currentTarget).get("q") || "") || null); };

  const hide = async () => {
    if (!hiding) return;
    setBusy(true);
    try { await api.admin.hideProduct(hiding.id); show(`${hiding.name} is hidden from the shop`); setHiding(null); load(); }
    catch (e) { show((e as Error).message, { kind: "error" }); }
    finally { setBusy(false); }
  };

  return (
    <div className="admin-page">
      <div className="admin-head">
        <div><h1>Products</h1><p>{data ? `${data.total} ${data.total === 1 ? "product" : "products"}` : " "}</p></div>
        <Link to="/admin/products/new" className="btn btn-primary"><Icon name="plus" size={18} />Add product</Link>
      </div>

      <div className="toolbar">
        <form className="search" role="search" onSubmit={search}>
          <Icon name="search" size={18} />
          <label htmlFor="p-search" className="sr-only">Search products</label>
          <input id="p-search" name="q" type="search" placeholder="Name or code" defaultValue={sp.get("q") ?? ""} />
        </form>
        <label><span className="sr-only">Category</span>
          <select value={sp.get("category") ?? ""} onChange={(e) => set("category", e.target.value || null)}>
            <option value="">All categories</option>
            {cats.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
          </select>
        </label>
        <div className="tabs" role="group" aria-label="Show">
          {shows.map((s) => <button key={s.v} className="tab" aria-pressed={(sp.get("show") ?? "all") === s.v} onClick={() => set("show", s.v === "all" ? null : s.v)}>{s.label}</button>)}
        </div>
      </div>

      {err ? <ErrorState message={err} onRetry={load} /> : !data ? <PageLoading /> : !data.items.length ? (
        <div className="panel">
          <EmptyState icon="products" title={sp.toString() ? "No products match" : "No products yet"} action={<Link to="/admin/products/new" className="btn btn-primary">Add your first product</Link>}>
            {sp.toString() ? "Try another search or filter." : "Products you add appear in the shop straight away."}
          </EmptyState>
        </div>
      ) : (
        <>
          <div className="panel panel-flush">
            <div className="table-scroll">
              <table className="table">
                <thead><tr><th>Product</th><th>Category</th><th className="num">Price</th><th className="num">Stock</th><th>Try-on</th><th>Status</th><th><span className="sr-only">Actions</span></th></tr></thead>
                <tbody>
                  {data.items.map((p) => (
                    <tr key={p.id} className={p.isActive ? "" : "is-hidden-row"}>
                      <td>
                        <div className="cell-product">
                          <span className="table-thumb"><ProductImage url={p.images[0]?.url} alt="" type={p.jewelleryType} iconSize={24} /></span>
                          <span><Link to={`/admin/products/${p.id}`}>{p.name}</Link><span className="muted" style={{ display: "block" }}>{p.code}</span></span>
                        </div>
                      </td>
                      <td>{p.category?.name}</td>
                      <td className="num">{lkr(p.price)}</td>
                      <td className="num"><span className={p.stock === 0 ? "stock-num-out" : p.stock <= 3 ? "stock-num-low" : ""}>{p.stock}</span></td>
                      <td>{p.tryOnEnabled ? <span className="pill pill-on">On</span> : <span className="pill pill-off">Off</span>}</td>
                      <td>{p.isActive ? <span className="pill pill-on">In shop</span> : <span className="pill pill-off">Hidden</span>}</td>
                      <td>
                        <div className="row-actions">
                          <Link to={`/admin/products/${p.id}`} className="icon-btn" aria-label={`Edit ${p.name}`}><Icon name="edit" size={18} /></Link>
                          {p.isActive && <a href={`/product/${p.slug}`} target="_blank" rel="noreferrer" className="icon-btn" aria-label={`View ${p.name} in the shop`}><Icon name="eye" size={18} /></a>}
                          {p.isActive && <button className="icon-btn" aria-label={`Hide ${p.name}`} onClick={() => setHiding(p)}><Icon name="eyeOff" size={18} /></button>}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
          <Pagination page={data.page} pages={data.pages} onPage={(p) => set("page", String(p))} />
        </>
      )}

      <ConfirmDialog open={!!hiding} title="Hide this product?" confirmLabel="Hide product" busy={busy} onConfirm={hide} onClose={() => setHiding(null)}
        body={<>{hiding?.name} will be removed from the shop. Past orders keep it, and you can show it again from its edit page.</>} />
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\admin\Reports.tsx' @'
import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../../api/client";
import type { OrderStatus, ProductReport, SalesRow } from "../../api/types";
import { lkr, shortDate, statusLabel } from "../../api/format";
import BarChart from "../../components/BarChart";
import { ErrorState, PageLoading } from "../../components/ui";

type Range = "daily" | "weekly" | "monthly";
const ranges: { v: Range; label: string }[] = [{ v: "daily", label: "Daily" }, { v: "weekly", label: "Weekly" }, { v: "monthly", label: "Monthly" }];

function periodLabels(iso: string, range: Range) {
  const d = new Date(iso);
  if (range === "monthly") return { label: d.toLocaleDateString("en-GB", { month: "short" }), full: d.toLocaleDateString("en-GB", { month: "long", year: "numeric" }) };
  if (range === "weekly") return { label: d.toLocaleDateString("en-GB", { day: "numeric", month: "short" }), full: `Week of ${d.toLocaleDateString("en-GB", { day: "numeric", month: "long" })}` };
  return { label: d.toLocaleDateString("en-GB", { day: "numeric" }), full: d.toLocaleDateString("en-GB", { weekday: "short", day: "numeric", month: "short" }) };
}

export default function Reports() {
  const [range, setRange] = useState<Range>("daily");
  const [sales, setSales] = useState<SalesRow[] | null>(null);
  const [byStatus, setByStatus] = useState<{ status: OrderStatus; count: number }[] | null>(null);
  const [prod, setProd] = useState<ProductReport | null>(null);
  const [err, setErr] = useState("");

  useEffect(() => { setSales(null); api.admin.salesReport(range).then(setSales).catch((e) => setErr((e as Error).message)); }, [range]);
  useEffect(() => {
    api.admin.ordersReport().then(setByStatus).catch((e) => setErr((e as Error).message));
    api.admin.productsReport().then(setProd).catch((e) => setErr((e as Error).message));
  }, []);

  if (err) return <ErrorState message={err} />;

  const total = sales?.reduce((s, r) => s + r.sales, 0) ?? 0;
  const orders = sales?.reduce((s, r) => s + r.orders, 0) ?? 0;
  const maxStatus = Math.max(1, ...(byStatus ?? []).map((s) => s.count));

  return (
    <div className="admin-page">
      <div className="admin-head"><div><h1>Reports</h1><p>Cancelled orders are left out of sales.</p></div></div>

      <section className="panel">
        <div className="panel-head">
          <h2>Sales</h2>
          <div className="tabs" role="group" aria-label="Period">
            {ranges.map((r) => <button key={r.v} className="tab" aria-pressed={range === r.v} onClick={() => setRange(r.v)}>{r.label}</button>)}
          </div>
        </div>
        {!sales ? <PageLoading /> : !sales.length ? <p className="empty-note">No sales yet.</p> : (
          <>
            <p className="panel-meta" style={{ marginBottom: 16 }}>{lkr(total)} from {orders} orders · average {lkr(orders ? total / orders : 0)} per order</p>
            <BarChart caption={`${ranges.find((r) => r.v === range)!.label} sales`} height={260}
              bars={sales.map((r, i) => { const l = periodLabels(r.period, range); return { key: r.period, label: l.label, fullLabel: l.full, value: r.sales, orders: r.orders, highlight: i === sales.length - 1 }; })} />
          </>
        )}
      </section>

      <div className="report-grid">
        <section className="panel">
          <div className="panel-head"><h2>Orders by status</h2><Link to="/admin/orders" className="panel-link">All orders</Link></div>
          {!byStatus ? <PageLoading /> : (
            <div className="hbars">
              {byStatus.map((s) => (
                <Link key={s.status} to={`/admin/orders?status=${s.status}`} className="hbar" style={{ color: "var(--ink)", textDecoration: "none" }}>
                  <span>{statusLabel[s.status]}</span>
                  <span className="hbar-track" aria-hidden="true"><span className="hbar-fill" style={{ display: "block", width: `${(s.count / maxStatus) * 100}%` }} /></span>
                  <span className="hbar-value">{s.count}</span>
                </Link>
              ))}
            </div>
          )}
        </section>

        <section className="panel">
          <div className="panel-head"><h2>Best sellers</h2><span className="panel-meta">Pieces sold</span></div>
          {!prod ? <PageLoading /> : prod.top.length ? (
            <ol className="rank-list">{prod.top.map((t) => <li key={t.productId}><Link to={`/admin/products/${t.productId}`}>{t.name}</Link><strong>{t.qty}</strong></li>)}</ol>
          ) : <p className="empty-note">No sales yet.</p>}
        </section>

        <section className="panel">
          <div className="panel-head"><h2>Most tried on</h2><span className="panel-meta">AI try-ons</span></div>
          {!prod ? <PageLoading /> : prod.mostTried.length ? (
            <ol className="rank-list">{prod.mostTried.map((t, i) => <li key={t.id ?? i}>{t.id ? <Link to={`/admin/products/${t.id}`}>{t.name}</Link> : <span className="muted">Deleted product</span>}<strong>{t.tries}</strong></li>)}</ol>
          ) : <p className="empty-note">No try-ons yet.</p>}
        </section>

        <section className="panel">
          <div className="panel-head"><h2>Sold out</h2><Link to="/admin/products?show=low" className="panel-link">Update stock</Link></div>
          {!prod ? <PageLoading /> : prod.outOfStock.length ? (
            <ul className="stock-list">{prod.outOfStock.map((p) => <li key={p.id}><Link to={`/admin/products/${p.id}`} className="stock-name">{p.name}<span className="muted">{p.code}</span></Link><span className="stock-count is-out">Sold out</span></li>)}</ul>
          ) : <p className="empty-note">Nothing is sold out.</p>}
        </section>

        <section className="panel panel-wide" style={{ gridColumn: "1 / -1" }}>
          <div className="panel-head"><h2>Newest products</h2><Link to="/admin/products" className="panel-link">All products</Link></div>
          {!prod ? <PageLoading /> : prod.newest.length ? (
            <ul className="stock-list">{prod.newest.map((p) => <li key={p.id}><Link to={`/admin/products/${p.id}`} className="stock-name">{p.name}<span className="muted">{p.code}</span></Link><span className="muted" style={{ fontSize: 14 }}>Added {shortDate(p.createdAt)}</span></li>)}</ul>
          ) : <p className="empty-note">No products yet.</p>}
        </section>
      </div>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\admin\Settings.tsx' @'
import { FormEvent, useState } from "react";
import { api } from "../../api/client";
import { useReloadSettings, useSettings } from "../../context/SettingsContext";
import { useToast } from "../../context/ToastContext";
import { Switch } from "../../components/ui";

export default function SettingsPage() {
  const s = useSettings();
  const reload = useReloadSettings();
  const { show } = useToast();
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  const save = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    const text = (k: string) => String(f.get(k) ?? "").trim();
    const body = {
      shopName: text("shopName"), tagline: text("tagline"), phone: text("phone"), whatsapp: text("whatsapp"),
      email: text("email"), address: text("address"), bankDetails: text("bankDetails"),
      deliveryFee: Number(f.get("deliveryFee") || 0),
      freeDeliveryOver: f.get("freeDeliveryOver") ? Number(f.get("freeDeliveryOver")) : null,
      codEnabled: !!f.get("codEnabled"), bankEnabled: !!f.get("bankEnabled"), onlineEnabled: !!f.get("onlineEnabled"), pickupEnabled: !!f.get("pickupEnabled"),
    };
    if (!body.codEnabled && !body.bankEnabled && !body.onlineEnabled) { setErr("Turn on at least one payment method so customers can order."); return; }
    setBusy(true); setErr("");
    try { await api.admin.saveSettings(body); await reload(); show("Settings saved"); }
    catch (e) { setErr((e as Error).message); } finally { setBusy(false); }
  };

  return (
    <form className="admin-page" onSubmit={save} key={s.shopName + s.phone}>
      <div className="admin-head"><div><h1>Settings</h1><p>These details appear across the shop, at checkout and in messages to customers.</p></div></div>
      {err && <p className="form-error" role="alert">{err}</p>}

      <div className="admin-form">
        <div className="admin-form-main">
          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>Shop</h2>
            <div className="form-grid">
              <label className="field"><span className="field-label">Shop name</span><input name="shopName" required maxLength={80} defaultValue={s.shopName} /></label>
              <label className="field"><span className="field-label">Tagline</span><input name="tagline" maxLength={200} defaultValue={s.tagline} /></label>
              <label className="field span-2"><span className="field-label">Address</span><textarea name="address" rows={2} maxLength={300} defaultValue={s.address} /><span className="field-hint">Shown for store pickup and on the contact page</span></label>
            </div>
          </section>
          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>Contact</h2>
            <div className="form-grid">
              <label className="field"><span className="field-label">Phone</span><input name="phone" type="tel" maxLength={30} defaultValue={s.phone} placeholder="0XX XXX XXXX" /></label>
              <label className="field"><span className="field-label">WhatsApp</span><input name="whatsapp" type="tel" maxLength={30} defaultValue={s.whatsapp} placeholder="07XXXXXXXX" /><span className="field-hint">Used for WhatsApp buttons and new-order alerts</span></label>
              <label className="field span-2"><span className="field-label">Email</span><input name="email" type="email" maxLength={120} defaultValue={s.email} /></label>
            </div>
          </section>
          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>Payment</h2>
            <Switch name="codEnabled" label="Cash on delivery" defaultChecked={s.codEnabled} />
            <Switch name="bankEnabled" label="Bank transfer" defaultChecked={s.bankEnabled} />
            <label className="field"><span className="field-label">Bank details</span><textarea name="bankDetails" rows={4} maxLength={1000} defaultValue={s.bankDetails} placeholder={"Bank: \nBranch: \nAccount name: \nAccount number: "} /><span className="field-hint">Shown to customers who choose bank transfer</span></label>
            <Switch name="onlineEnabled" label="Online card payment" hint="Needs a payment gateway such as PayHere to be connected first" defaultChecked={s.onlineEnabled} />
          </section>
        </div>
        <div className="admin-form-side">
          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>Delivery</h2>
            <label className="field"><span className="field-label">Delivery fee (LKR)</span><input name="deliveryFee" type="number" min={0} step={1} required defaultValue={s.deliveryFee} /></label>
            <label className="field"><span className="field-label">Free delivery over (LKR) <span className="optional">(optional)</span></span><input name="freeDeliveryOver" type="number" min={0} step={1} defaultValue={s.freeDeliveryOver ?? ""} /><span className="field-hint">Leave empty to always charge</span></label>
            <Switch name="pickupEnabled" label="Store pickup" hint="Free for the customer" defaultChecked={s.pickupEnabled} />
          </section>
        </div>
      </div>

      <div className="save-bar"><button className="btn btn-primary" disabled={busy}>{busy ? "Saving…" : "Save settings"}</button></div>
    </form>
  );
}
'@

Write-ProjectFile 'frontend\src\styles.css' @'
/* =========================================================
   Tokens
   ========================================================= */
:root {
  --plum: #3b1426;
  --plum-2: #5a2340;
  --plum-soft: #8c5c77;
  --plum-deep: #2a0e1b;
  --plum-hero: #6a3352;
  --gold: #c9a24a;
  --gold-deep: #8a6a24;
  --pearl: #f5f2f5;
  --tint: #ebe3ea;
  --tint-2: #f3eef2;
  --surface: #ffffff;
  --ink: #221a20;
  --ink-2: #4a3f4c;
  --muted: #5e5360;
  --line: #e4dce2;
  --line-2: #cfc3cc;
  --on-dark: #eadce4;
  --error: #a4262c;
  --error-bg: #fbeaeb;
  --ok: #1e5b32;
  --ok-bg: #e1f1e6;
  --warn: #6b4a00;
  --warn-bg: #fbf0d9;
  --info: #1f3f6b;
  --info-bg: #e4ecf7;
  --radius-sm: 10px;
  --radius: 16px;
  --radius-lg: 24px;
  --shadow: 0 18px 40px rgba(20, 4, 12, 0.18);
  --font-body: Manrope, system-ui, -apple-system, "Segoe UI", sans-serif;
  --font-display: "Bodoni Moda", Didot, Georgia, serif;
  --page: 1280px;
  --gutter: 24px;
  font-family: var(--font-body);
  color: var(--ink);
  background: var(--pearl);
  -webkit-font-smoothing: antialiased;
}
@media (max-width: 640px) { :root { --gutter: 16px; } }

/* =========================================================
   Base
   ========================================================= */
* { box-sizing: border-box; }
html { scroll-behavior: smooth; }
@media (prefers-reduced-motion: reduce) { html { scroll-behavior: auto; } *, *::before, *::after { transition: none !important; animation: none !important; } }
body { margin: 0; background: var(--pearl); color: var(--ink); font-size: 16px; line-height: 1.5; }
img { max-width: 100%; display: block; }
a { color: var(--plum); text-underline-offset: 3px; }
a:hover { color: var(--plum-2); }
h1, h2, h3 { margin: 0; line-height: 1.15; }
h1, h2 { font-family: var(--font-display); font-weight: 500; }
p { margin: 0; }
button, input, select, textarea { font: inherit; color: inherit; }
button { cursor: pointer; }
button:disabled { cursor: not-allowed; }
:focus-visible { outline: 2px solid var(--gold-deep); outline-offset: 2px; }
.muted { color: var(--muted); }
.sr-only { position: absolute !important; width: 1px; height: 1px; padding: 0; margin: -1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; border: 0; }
.skip-link { position: absolute; left: 8px; top: -60px; z-index: 100; padding: 10px 16px; background: var(--plum); color: #fff; border-radius: var(--radius-sm); }
.skip-link:focus { top: 8px; color: #fff; }
.wrap { width: 100%; max-width: var(--page); margin: 0 auto; padding: 0 var(--gutter); }
.page { width: 100%; max-width: var(--page); margin: 0 auto; padding: 32px var(--gutter) 80px; }
.page-narrow { max-width: 760px; }
.page-head { display: flex; flex-direction: column; gap: 8px; margin-bottom: 28px; }
.page-head h1 { font-size: clamp(34px, 5vw, 48px); }
.page-head p { color: var(--muted); max-width: 60ch; }
.section-head { display: flex; align-items: baseline; justify-content: space-between; gap: 16px; margin-bottom: 24px; }
.section-head h2 { font-size: clamp(28px, 4vw, 40px); }
.section-head a { font-weight: 700; font-size: 15px; white-space: nowrap; }
.num { font-variant-numeric: tabular-nums; }

/* =========================================================
   Buttons
   ========================================================= */
.btn { display: inline-flex; align-items: center; justify-content: center; gap: 8px; min-height: 48px; padding: 0 24px; border-radius: 999px; border: 1.5px solid transparent; font-size: 15px; font-weight: 700; line-height: 1.2; text-decoration: none; text-align: center; background: none; white-space: nowrap; }
.btn:disabled { opacity: .5; }
.btn-primary { background: var(--plum); color: #fff; border-color: var(--plum); }
.btn-primary:hover:not(:disabled) { background: var(--plum-2); border-color: var(--plum-2); color: #fff; }
.btn-secondary { background: var(--surface); color: var(--plum); border-color: var(--plum); }
.btn-secondary:hover:not(:disabled) { background: var(--tint-2); color: var(--plum); }
.btn-gold { background: var(--gold); color: var(--plum-deep); border-color: var(--gold); }
.btn-gold:hover { background: #d4b060; color: var(--plum-deep); }
.btn-outline-light { color: #fff; border-color: #fff; }
.btn-outline-light:hover { background: rgba(255, 255, 255, .1); color: #fff; }
.btn-danger { background: var(--error); color: #fff; border-color: var(--error); }
.btn-danger:hover:not(:disabled) { background: #85191f; }
.btn-quiet { color: var(--plum); border-color: var(--line-2); background: var(--surface); }
.btn-quiet:hover { border-color: var(--plum); color: var(--plum); }
.btn-sm { min-height: 44px; padding: 0 16px; font-size: 14px; }
.btn-lg { min-height: 56px; padding: 0 32px; font-size: 16px; }
.btn-block { width: 100%; }
.btn-icon-text { padding: 0 14px; }
.btn-link { padding: 0; border: 0; background: none; color: var(--plum); font-weight: 700; text-decoration: underline; text-underline-offset: 3px; min-height: 44px; }
.icon-btn { width: 44px; height: 44px; padding: 0; flex-shrink: 0; display: inline-flex; align-items: center; justify-content: center; border: 0; border-radius: 999px; background: transparent; color: var(--ink); text-decoration: none; position: relative; }
.icon-btn:hover { background: var(--tint); color: var(--ink); }
.icon-btn-sm { width: 36px; height: 36px; }

/* =========================================================
   Forms
   ========================================================= */
.form { display: flex; flex-direction: column; gap: 18px; }
.form-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 18px; }
.form-grid .span-2 { grid-column: 1 / -1; }
@media (max-width: 640px) { .form-grid { grid-template-columns: 1fr; } }
.field { display: flex; flex-direction: column; gap: 6px; min-width: 0; }
.field-label { font-size: 14px; font-weight: 700; }
.field-hint, .optional { font-size: 13px; color: var(--muted); font-weight: 400; }
.input, .field input:not([type="checkbox"]):not([type="radio"]):not([type="file"]), .field select, .field textarea {
  width: 100%; min-height: 48px; padding: 10px 14px; border: 1px solid var(--line-2); border-radius: 12px; background: var(--surface); font-size: 16px; }
.field textarea { min-height: 96px; resize: vertical; }
.input:focus, .field input:focus, .field select:focus, .field textarea:focus { border-color: var(--plum); outline: 2px solid var(--plum); outline-offset: 0; }
.field input[aria-invalid="true"] { border-color: var(--error); }
.input-wrap { position: relative; display: block; }
.input-wrap input { padding-right: 52px !important; }
.input-icon { position: absolute; right: 2px; top: 2px; width: 44px; height: 44px; padding: 0; display: flex; align-items: center; justify-content: center; border: 0; border-radius: 10px; background: transparent; color: var(--muted); }
.input-icon:hover { color: var(--plum); }
.form-error { padding: 12px 14px; border-radius: var(--radius-sm); background: var(--error-bg); color: var(--error); font-size: 14px; font-weight: 600; }
.form-ok { padding: 12px 14px; border-radius: var(--radius-sm); background: var(--ok-bg); color: var(--ok); font-size: 14px; font-weight: 600; }
.fieldset { border: 0; padding: 0; margin: 0; display: flex; flex-direction: column; gap: 12px; }
.fieldset legend { padding: 0; margin-bottom: 12px; font-size: 14px; font-weight: 700; }

/* Choice cards (radio) */
.choices { display: grid; gap: 12px; }
.choices-2 { grid-template-columns: repeat(2, minmax(0, 1fr)); }
@media (max-width: 560px) { .choices-2 { grid-template-columns: 1fr; } }
.choice { position: relative; display: flex; gap: 14px; align-items: flex-start; padding: 16px; border: 1.5px solid var(--line-2); border-radius: var(--radius); background: var(--surface); cursor: pointer; }
.choice:hover { border-color: var(--plum-soft); }
.choice input { position: absolute; opacity: 0; pointer-events: none; }
.choice-dot { flex-shrink: 0; width: 22px; height: 22px; margin-top: 1px; border: 2px solid var(--line-2); border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.choice-dot::after { content: ""; width: 10px; height: 10px; border-radius: 50%; background: transparent; }
.choice:has(input:checked) { border-color: var(--plum); background: var(--tint-2); }
.choice:has(input:checked) .choice-dot { border-color: var(--plum); }
.choice:has(input:checked) .choice-dot::after { background: var(--plum); }
.choice:has(input:focus-visible) { outline: 2px solid var(--gold-deep); outline-offset: 2px; }
.choice-body { display: flex; flex-direction: column; gap: 2px; min-width: 0; }
.choice-title { display: flex; align-items: center; gap: 8px; font-weight: 700; }
.choice-note { font-size: 14px; color: var(--muted); }

/* Switch */
.switch { display: flex; align-items: flex-start; gap: 12px; cursor: pointer; min-height: 44px; padding: 4px 0; }
.switch input { position: absolute; opacity: 0; width: 1px; height: 1px; }
.switch-track { flex-shrink: 0; position: relative; width: 44px; height: 26px; margin-top: 1px; border-radius: 13px; background: var(--line-2); transition: background .15s; }
.switch-thumb { position: absolute; top: 3px; left: 3px; width: 20px; height: 20px; border-radius: 50%; background: #fff; box-shadow: 0 1px 3px rgba(0, 0, 0, .25); transition: transform .15s; }
.switch input:checked + .switch-track { background: var(--plum); }
.switch input:checked + .switch-track .switch-thumb { transform: translateX(18px); }
.switch input:focus-visible + .switch-track { outline: 2px solid var(--gold-deep); outline-offset: 2px; }
.switch-text { display: flex; flex-direction: column; gap: 2px; }
.switch-label { font-weight: 600; }

/* Quantity */
.qty { display: inline-flex; align-items: center; border: 1px solid var(--line-2); border-radius: 999px; background: var(--surface); }
.qty-btn { width: 44px; height: 44px; display: flex; align-items: center; justify-content: center; border: 0; border-radius: 999px; background: none; color: var(--ink); }
.qty-btn:hover:not(:disabled) { background: var(--tint); }
.qty-btn:disabled { color: var(--line-2); }
.qty-value { min-width: 32px; text-align: center; font-weight: 700; font-variant-numeric: tabular-nums; }

/* =========================================================
   Header, drawer, footer
   ========================================================= */
.site { min-height: 100vh; display: flex; flex-direction: column; }
.site-main { flex: 1; }
.site-header { position: sticky; top: 0; z-index: 40; background: var(--surface); border-bottom: 1px solid var(--line); }
.header-row { max-width: 1440px; margin: 0 auto; height: 76px; padding: 0 var(--gutter); display: flex; align-items: center; gap: 28px; }
.brand { font-family: var(--font-display); font-size: 26px; font-weight: 600; color: var(--plum); text-decoration: none; white-space: nowrap; }
.brand:hover { color: var(--plum-2); }
.brand-light { color: #fff; }
.main-nav { display: flex; gap: 22px; flex: 1; min-width: 0; }
.main-nav a { color: var(--ink); text-decoration: none; font-size: 15px; font-weight: 500; white-space: nowrap; padding: 8px 0; border-bottom: 2px solid transparent; }
.main-nav a:hover { color: var(--plum); }
.main-nav a.active { color: var(--plum); font-weight: 700; border-bottom-color: var(--gold); }
.search { display: flex; align-items: center; gap: 8px; height: 44px; padding: 0 14px; border: 1px solid var(--line-2); border-radius: 999px; background: var(--surface); color: var(--muted); }
.search:focus-within { border-color: var(--plum); outline: 2px solid var(--plum); outline-offset: -1px; }
.search input { border: 0; outline: none; background: transparent; width: 100%; min-width: 0; font-size: 15px; color: var(--ink); }
.header-search { width: 240px; flex-shrink: 0; }
.header-icons { display: flex; align-items: center; gap: 2px; }
.count-badge { position: absolute; top: 3px; right: 1px; min-width: 18px; height: 18px; padding: 0 5px; border-radius: 9px; background: var(--plum); color: #fff; font-size: 11px; font-weight: 700; line-height: 18px; text-align: center; }
.header-signin { margin-left: 8px; font-weight: 700; font-size: 15px; white-space: nowrap; }
.header-menu { display: none; margin-left: -10px; }
@media (max-width: 1240px) { .main-nav a:nth-child(n+6) { display: none; } }
@media (max-width: 1060px) {
  .main-nav, .header-search { display: none; }
  .header-menu { display: inline-flex; }
  .header-row { gap: 8px; height: 64px; }
  .brand { flex: 1; font-size: 22px; }
}
.drawer-scrim { position: fixed; inset: 0; z-index: 50; border: 0; padding: 0; background: rgba(20, 4, 12, .45); }
.drawer { position: fixed; z-index: 60; top: 0; left: 0; bottom: 0; width: min(340px, 88vw); display: flex; flex-direction: column; gap: 20px; padding: 16px 20px 24px; background: var(--surface); transform: translateX(-100%); transition: transform .2s ease; overflow-y: auto; visibility: hidden; }
.drawer.is-open { transform: translateX(0); visibility: visible; }
.drawer-head { display: flex; align-items: center; justify-content: space-between; }
.drawer-head .brand { font-size: 22px; }
.drawer-nav { display: flex; flex-direction: column; }
.drawer-nav a { padding: 14px 4px; border-bottom: 1px solid var(--line); color: var(--ink); text-decoration: none; font-size: 17px; font-weight: 600; }
.drawer-nav a.active { color: var(--plum); }
.drawer-foot { margin-top: auto; display: flex; flex-direction: column; gap: 8px; align-items: flex-start; }
.drawer-foot a:not(.btn) { font-weight: 700; padding: 10px 0; }

.site-footer { background: var(--plum-deep); color: var(--on-dark); }
.footer-inner { max-width: var(--page); margin: 0 auto; padding: 64px var(--gutter) 40px; display: grid; grid-template-columns: 2fr repeat(3, minmax(0, 1fr)); gap: 40px; }
.footer-brand { display: flex; flex-direction: column; gap: 12px; max-width: 340px; }
.footer-brand .brand { font-size: 28px; }
.footer-brand p { line-height: 1.6; }
.footer-col { display: flex; flex-direction: column; gap: 10px; font-size: 15px; }
.footer-col h2 { font-family: var(--font-body); font-size: 15px; font-weight: 700; color: var(--gold); margin-bottom: 4px; }
.footer-col a { color: var(--on-dark); text-decoration: none; }
.footer-col a:hover { color: #fff; text-decoration: underline; }
.footer-base { max-width: var(--page); margin: 0 auto; padding: 20px var(--gutter) 32px; border-top: 1px solid #4a2336; font-size: 13px; color: #cdb8c4; }
@media (max-width: 860px) { .footer-inner { grid-template-columns: repeat(2, minmax(0, 1fr)); } .footer-brand { grid-column: 1 / -1; } }
@media (max-width: 480px) { .footer-inner { grid-template-columns: 1fr; gap: 28px; } }

/* =========================================================
   Shared bits: badges, price, pills, crumbs, pager, states
   ========================================================= */
.badge { display: inline-flex; align-items: center; height: 26px; padding: 0 10px; border-radius: 13px; background: var(--surface); color: var(--plum); font-size: 12px; font-weight: 700; }
.badge-sale { background: var(--plum); color: #fff; }
.badge-muted { background: var(--ink); color: #fff; }
.price { display: inline-flex; flex-wrap: wrap; align-items: baseline; gap: 4px 10px; }
.price-now { font-weight: 700; color: var(--plum); font-variant-numeric: tabular-nums; }
.price-was { color: var(--muted); font-size: 14px; }
.price-off { font-size: 12px; font-weight: 700; color: var(--plum); background: var(--tint); padding: 2px 8px; border-radius: 10px; }
.price-md .price-now { font-size: 18px; }
.price-lg .price-now { font-size: 30px; }
.price-lg .price-was { font-size: 17px; }
.pill { font-family: var(--font-body); vertical-align: middle; display: inline-block; padding: 4px 10px; border-radius: 12px; font-size: 12px; font-weight: 700; white-space: nowrap; }
.pill-pending { background: var(--warn-bg); color: var(--warn); }
.pill-confirmed, .pill-processing, .pill-ready, .pill-dispatched { background: var(--info-bg); color: var(--info); }
.pill-delivered, .pill-paid, .pill-on { background: var(--ok-bg); color: var(--ok); }
.pill-cancelled, .pill-off, .pill-refunded { background: #eeeaec; color: var(--muted); }
.pill-unpaid { background: var(--warn-bg); color: var(--warn); }
.crumbs ol { list-style: none; margin: 0 0 20px; padding: 0; display: flex; flex-wrap: wrap; gap: 6px; font-size: 14px; color: var(--muted); }
.crumbs li:not(:last-child)::after { content: "/"; margin-left: 6px; color: var(--line-2); }
.crumbs a { color: var(--muted); }
.crumbs a:hover { color: var(--plum); }
.pager { display: flex; justify-content: center; align-items: center; gap: 6px; margin-top: 40px; flex-wrap: wrap; }
.pager-group { display: inline-flex; align-items: center; gap: 6px; }
.pager-btn { min-width: 44px; height: 44px; padding: 0 10px; display: inline-flex; align-items: center; justify-content: center; border: 1px solid var(--line-2); border-radius: 999px; background: var(--surface); font-weight: 700; }
.pager-btn:hover:not(:disabled) { border-color: var(--plum); }
.pager-btn.is-current { background: var(--plum); border-color: var(--plum); color: #fff; }
.pager-btn:disabled { opacity: .4; }
.pager-gap { color: var(--muted); }
.page-loading { display: flex; align-items: center; justify-content: center; gap: 12px; padding: 80px 16px; color: var(--muted); }
.spinner { width: 22px; height: 22px; border: 3px solid var(--tint); border-top-color: var(--plum); border-radius: 50%; animation: spin .8s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
.empty-state { display: flex; flex-direction: column; align-items: center; text-align: center; gap: 12px; padding: 64px 16px; }
.empty-state h2 { font-size: 28px; }
.empty-state p { color: var(--muted); max-width: 46ch; }
.empty-state .btn { margin-top: 8px; }
.empty-icon { width: 64px; height: 64px; border-radius: 50%; background: var(--tint); color: var(--plum); display: flex; align-items: center; justify-content: center; }
.empty-icon-error { background: var(--error-bg); color: var(--error); }
.empty-note { padding: 24px 0; color: var(--muted); text-align: center; }

/* Product image */
.pimg { width: 100%; height: 100%; object-fit: cover; background: var(--tint); }
.pimg-empty { display: flex; align-items: center; justify-content: center; color: var(--gold-deep); }

/* Toasts */
.toasts { position: fixed; z-index: 90; left: 50%; bottom: 24px; transform: translateX(-50%); width: min(520px, calc(100vw - 32px)); display: flex; flex-direction: column; gap: 8px; pointer-events: none; }
.toast { pointer-events: auto; display: flex; align-items: center; gap: 12px; padding: 8px 8px 8px 16px; border-radius: var(--radius); background: var(--ink); color: #fff; box-shadow: var(--shadow); font-size: 15px; animation: toast-in .2s ease-out; }
.toast-error { background: var(--error); }
.toast-text { flex: 1; }
.toast-link { color: var(--gold) !important; font-weight: 700; white-space: nowrap; }
.toast .icon-btn { color: #fff; }
.toast .icon-btn:hover { background: rgba(255, 255, 255, .15); color: #fff; }
@keyframes toast-in { from { opacity: 0; transform: translateY(8px); } }

/* Modal */
.modal { width: min(520px, calc(100vw - 32px)); max-height: calc(100vh - 32px); padding: 0; border: 0; border-radius: var(--radius-lg); background: var(--surface); color: var(--ink); box-shadow: var(--shadow); }
.modal-wide { width: min(760px, calc(100vw - 32px)); }
.modal::backdrop { background: rgba(20, 4, 12, .5); }
.modal-inner { display: flex; flex-direction: column; max-height: calc(100vh - 32px); }
.modal-head { display: flex; align-items: center; justify-content: space-between; gap: 12px; padding: 20px 20px 12px 24px; }
.modal-head h2 { font-size: 26px; }
.modal-body { padding: 4px 24px 24px; overflow-y: auto; }
.modal-text { color: var(--ink-2); line-height: 1.6; }
.modal-foot { display: flex; justify-content: flex-end; gap: 10px; padding: 16px 24px 20px; border-top: 1px solid var(--line); flex-wrap: wrap; }

/* =========================================================
   Product card and grids
   ========================================================= */
.pgrid { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 24px; }
@media (max-width: 1100px) { .pgrid { grid-template-columns: repeat(3, minmax(0, 1fr)); } }
@media (max-width: 760px) { .pgrid { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 12px; } }
.pcard { display: flex; flex-direction: column; gap: 14px; padding: 10px 10px 16px; background: var(--surface); border-radius: 18px; min-width: 0; }
.pcard-media { position: relative; aspect-ratio: 4 / 5; border-radius: 12px; overflow: hidden; background: var(--tint); }
.pcard-link { display: block; width: 100%; height: 100%; }
.pcard-media .pimg { transition: transform .3s ease; }
.pcard:hover .pcard-media img.pimg { transform: scale(1.03); }
.pcard-badges { position: absolute; left: 10px; top: 10px; display: flex; flex-direction: column; align-items: flex-start; gap: 6px; }
.pcard-wish { position: absolute; top: 8px; right: 8px; width: 44px; height: 44px; border: 0; border-radius: 50%; background: var(--surface); color: var(--ink); display: flex; align-items: center; justify-content: center; }
.pcard-wish:hover { color: var(--plum); }
.pcard-wish.is-on { color: var(--plum); }
.pcard-body { display: flex; flex-direction: column; gap: 4px; padding: 0 6px; }
.pcard-name { font-family: var(--font-body); font-size: 16px; font-weight: 700; line-height: 1.3; }
.pcard-name a { color: var(--ink); text-decoration: none; }
.pcard-name a:hover { color: var(--plum); text-decoration: underline; }
.pcard-code { font-size: 13px; color: var(--muted); }
.pcard-actions { display: flex; gap: 8px; padding: 0 6px; margin-top: auto; }
.pcard-add { flex: 1; min-width: 0; }
@media (max-width: 760px) {
  .pcard { padding: 6px 6px 12px; gap: 10px; border-radius: 14px; }
  .pcard-body, .pcard-actions { padding: 0 4px; }
  .pcard-name { font-size: 14px; }
  .pcard-code { display: none; }
  .pcard .btn-sm { padding: 0 10px; font-size: 13px; }
  .pcard-try-label { display: none; }
  .pcard .btn-icon-text { width: 44px; padding: 0; flex-shrink: 0; }
  .price-md .price-now { font-size: 15px; }
}
.skeleton { background: linear-gradient(90deg, var(--tint) 0%, var(--tint-2) 50%, var(--tint) 100%); background-size: 200% 100%; animation: shimmer 1.2s infinite; border-radius: 18px; }
.skeleton-card { aspect-ratio: 4 / 6.4; }
@keyframes shimmer { to { background-position: -200% 0; } }

/* =========================================================
   Home
   ========================================================= */
.hero { background: var(--plum); color: #fff; }
.hero-inner { max-width: var(--page); margin: 0 auto; padding: 72px var(--gutter); display: grid; grid-template-columns: minmax(0, 1.1fr) minmax(0, .9fr); gap: 64px; align-items: center; }
.hero-copy { display: flex; flex-direction: column; gap: 24px; }
.hero h1 { font-size: clamp(44px, 6.4vw, 80px); line-height: 1.02; letter-spacing: -0.01em; }
.hero p { font-size: 19px; line-height: 1.6; color: var(--on-dark); max-width: 520px; }
.hero-actions { display: flex; gap: 12px; flex-wrap: wrap; margin-top: 8px; }
.hero-visual { position: relative; justify-self: center; width: min(440px, 100%); aspect-ratio: 460 / 540; }
.hero-arch { position: absolute; inset: 0; border-radius: 999px 999px 20px 20px; background: var(--plum-hero); overflow: hidden; display: flex; align-items: center; justify-content: center; color: #e3ccd8; }
.hero-arch img { width: 100%; height: 100%; object-fit: cover; }
.hero-chip { position: absolute; top: 32px; right: -16px; display: inline-flex; align-items: center; gap: 8px; height: 36px; padding: 0 14px; border-radius: 18px; background: var(--gold); color: var(--plum-deep); font-size: 13px; font-weight: 700; }
.hero-card { position: absolute; left: -32px; bottom: 36px; width: min(300px, 80%); display: flex; gap: 14px; align-items: center; padding: 14px; border-radius: var(--radius); background: var(--surface); color: var(--ink); box-shadow: var(--shadow); text-decoration: none; }
.hero-card:hover { color: var(--ink); }
.hero-card-img { width: 60px; height: 60px; flex-shrink: 0; border-radius: 12px; overflow: hidden; }
.hero-card-name { font-weight: 700; font-size: 15px; }
@media (max-width: 900px) {
  .hero-inner { grid-template-columns: 1fr; gap: 40px; padding: 40px var(--gutter) 48px; }
  .hero-visual { width: min(360px, 100%); }
  .hero-chip { right: 8px; }
  .hero-card { left: 12px; right: 12px; width: auto; bottom: 12px; }
}
@media (max-width: 560px) { .hero-actions .btn { flex: 1 1 100%; } }
.home-section { max-width: var(--page); margin: 0 auto; padding: 80px var(--gutter) 0; }
.cat-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(128px, 1fr)); gap: 24px 16px; }
.cat-tile { display: flex; flex-direction: column; align-items: center; gap: 12px; text-decoration: none; color: var(--ink); text-align: center; }
.cat-tile:hover { color: var(--plum); }
.cat-circle { width: 112px; height: 112px; border-radius: 50%; background: var(--tint); color: var(--gold-deep); display: flex; align-items: center; justify-content: center; overflow: hidden; transition: background .15s; }
.cat-circle img { width: 100%; height: 100%; object-fit: cover; }
.cat-tile:hover .cat-circle { background: #e3d7e1; }
.cat-name { font-size: 15px; font-weight: 700; line-height: 1.25; }
@media (max-width: 640px) {
  .cat-grid { display: flex; overflow-x: auto; gap: 14px; margin: 0 calc(-1 * var(--gutter)); padding: 0 var(--gutter) 8px; scroll-snap-type: x mandatory; }
  .cat-tile { flex: 0 0 84px; scroll-snap-align: start; }
  .cat-circle { width: 76px; height: 76px; }
  .cat-circle svg { width: 36px; height: 36px; }
  .cat-name { font-size: 13px; }
}
.look-band { margin-top: 88px; display: grid; grid-template-columns: minmax(0, 380px) minmax(0, 1fr); gap: 56px; align-items: center; padding: 56px; border-radius: 28px; background: var(--tint); }
.look-copy { display: flex; flex-direction: column; gap: 18px; align-items: flex-start; }
.look-copy h2 { font-size: clamp(34px, 4.4vw, 48px); }
.look-copy p { font-size: 17px; line-height: 1.6; color: var(--ink-2); }
.look-steps { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 14px; list-style: none; margin: 0; padding: 0; }
.look-step { display: flex; flex-direction: column; gap: 12px; padding: 18px; border-radius: var(--radius); background: var(--surface); }
.look-step-num { width: 30px; height: 30px; border-radius: 50%; background: var(--plum); color: #fff; font-size: 14px; font-weight: 700; display: flex; align-items: center; justify-content: center; }
.look-step-art { height: 100px; border-radius: 10px; background: var(--pearl); color: var(--gold-deep); display: flex; align-items: center; justify-content: center; }
.look-step-name { font-weight: 700; font-size: 15px; }
.look-step-final { background: var(--plum); color: #fff; }
.look-step-final .look-step-num { background: var(--gold); color: var(--plum-deep); }
.look-step-final .look-step-art { background: var(--plum-hero); color: #e3ccd8; }
@media (max-width: 1000px) { .look-band { grid-template-columns: 1fr; padding: 32px 24px; gap: 32px; } }
@media (max-width: 640px) { .look-band { margin-top: 64px; } .look-steps { grid-template-columns: repeat(2, minmax(0, 1fr)); } .look-step-art { height: 72px; } }
.trust { max-width: var(--page); margin: 0 auto; padding: 80px var(--gutter); display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 24px; }
.trust-item { display: flex; gap: 14px; align-items: flex-start; }
.trust-icon { width: 48px; height: 48px; flex-shrink: 0; border-radius: 50%; background: var(--surface); color: var(--plum); display: flex; align-items: center; justify-content: center; }
.trust-item strong { display: block; font-size: 16px; }
.trust-item span { font-size: 14px; color: var(--muted); line-height: 1.5; }
@media (max-width: 900px) { .trust { grid-template-columns: repeat(2, minmax(0, 1fr)); padding: 64px var(--gutter); } }
@media (max-width: 480px) { .trust { grid-template-columns: 1fr; } }

/* =========================================================
   Shop
   ========================================================= */
.shop { display: grid; grid-template-columns: 248px minmax(0, 1fr); gap: 40px; align-items: start; }
.shop-head { display: flex; flex-direction: column; gap: 6px; margin-bottom: 24px; }
.shop-head h1 { font-size: clamp(34px, 5vw, 48px); }
.shop-toolbar { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-bottom: 20px; flex-wrap: wrap; }
.shop-count { color: var(--muted); font-size: 15px; }
.shop-toolbar-right { display: flex; gap: 10px; align-items: center; }
.sort select { min-height: 44px; padding: 0 36px 0 14px; border: 1px solid var(--line-2); border-radius: 999px; background: var(--surface); font-size: 14px; font-weight: 600; }
.filters-toggle { display: none; }
.filters { position: sticky; top: 100px; display: flex; flex-direction: column; gap: 28px; }
.filters-head { display: none; }
.filter-group { display: flex; flex-direction: column; gap: 10px; }
.filter-group h2 { font-family: var(--font-body); font-size: 14px; font-weight: 700; }
.filter-list { display: flex; flex-direction: column; gap: 2px; }
.filter-link { display: flex; justify-content: space-between; gap: 8px; padding: 8px 12px; border-radius: 10px; color: var(--ink); text-decoration: none; font-size: 15px; }
.filter-link:hover { background: var(--tint); color: var(--ink); }
.filter-link.is-on { background: var(--plum); color: #fff; font-weight: 700; }
.filter-link .muted { font-size: 13px; }
.filter-link.is-on .muted { color: var(--on-dark); }
.price-inputs { display: grid; grid-template-columns: 1fr auto 1fr; align-items: center; gap: 8px; }
.price-inputs input { width: 100%; min-height: 44px; padding: 0 10px; border: 1px solid var(--line-2); border-radius: 10px; background: var(--surface); font-size: 15px; }
.chips { display: flex; flex-wrap: wrap; gap: 8px; }
.chip { min-height: 36px; padding: 0 14px; border: 1px solid var(--line-2); border-radius: 18px; background: var(--surface); font-size: 14px; font-weight: 600; display: inline-flex; align-items: center; gap: 6px; }
.chip:hover { border-color: var(--plum); }
.chip[aria-pressed="true"] { background: var(--plum); border-color: var(--plum); color: #fff; }
.check { display: flex; align-items: center; gap: 10px; min-height: 44px; cursor: pointer; font-size: 15px; }
.check input { width: 20px; height: 20px; accent-color: var(--plum); }
.active-filters { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 20px; }
@media (max-width: 900px) {
  .shop { grid-template-columns: 1fr; }
  .filters-toggle { display: inline-flex; }
  .filters { position: fixed; z-index: 60; inset: auto 0 0 0; top: auto; max-height: 85vh; overflow-y: auto; padding: 20px var(--gutter) 24px; background: var(--surface); border-radius: 24px 24px 0 0; box-shadow: var(--shadow); transform: translateY(100%); transition: transform .2s ease; visibility: hidden; }
  .filters.is-open { transform: translateY(0); visibility: visible; }
  .filters-head { display: flex; align-items: center; justify-content: space-between; }
  .filters-head h2 { font-size: 26px; }
}

/* =========================================================
   Product details
   ========================================================= */
.pdp { display: grid; grid-template-columns: minmax(0, 1.05fr) minmax(0, 1fr); gap: 56px; align-items: start; }
.gallery { display: flex; flex-direction: column; gap: 12px; position: sticky; top: 100px; }
.gallery-main { position: relative; aspect-ratio: 1; border-radius: var(--radius-lg); overflow: hidden; background: var(--tint); }
.gallery-main .pimg-empty svg { width: 160px; height: 160px; }
.gallery-nav { position: absolute; top: 50%; transform: translateY(-50%); background: var(--surface) !important; box-shadow: 0 2px 8px rgba(0, 0, 0, .12); }
.gallery-prev { left: 12px; }
.gallery-next { right: 12px; }
.thumbs { display: flex; gap: 10px; overflow-x: auto; padding: 2px; }
.thumb { width: 76px; height: 76px; flex-shrink: 0; padding: 0; border: 2px solid transparent; border-radius: 12px; overflow: hidden; background: var(--tint); }
.thumb[aria-current="true"] { border-color: var(--plum); }
.pdp-info { display: flex; flex-direction: column; gap: 20px; }
.pdp-info h1 { font-size: clamp(32px, 4.4vw, 48px); }
.pdp-meta { display: flex; flex-wrap: wrap; gap: 8px 16px; align-items: center; font-size: 14px; color: var(--muted); }
.stock { display: inline-flex; align-items: center; gap: 6px; font-weight: 700; font-size: 14px; }
.stock-in { color: var(--ok); }
.stock-low { color: var(--warn); }
.stock-out { color: var(--error); }
.pdp-offer { padding: 10px 14px; border-radius: var(--radius-sm); background: var(--tint); color: var(--plum); font-weight: 700; font-size: 14px; }
.pdp-desc { color: var(--ink-2); line-height: 1.7; white-space: pre-line; }
.pdp-buy { display: flex; flex-direction: column; gap: 14px; padding: 20px 0; border-top: 1px solid var(--line); border-bottom: 1px solid var(--line); }
.pdp-buy-row { display: flex; gap: 12px; align-items: center; flex-wrap: wrap; }
.pdp-buy-row .btn-primary { flex: 1; min-width: 180px; }
.try-cta { display: flex; gap: 16px; align-items: center; padding: 18px; border-radius: var(--radius); background: var(--plum); color: #fff; text-decoration: none; }
.try-cta:hover { background: var(--plum-2); color: #fff; }
.try-cta-icon { width: 48px; height: 48px; flex-shrink: 0; border-radius: 50%; background: var(--gold); color: var(--plum-deep); display: flex; align-items: center; justify-content: center; }
.try-cta strong { display: block; font-size: 17px; }
.try-cta span { font-size: 14px; color: var(--on-dark); }
.try-cta > svg:last-child { margin-left: auto; flex-shrink: 0; }
.pdp-actions { display: flex; gap: 8px; flex-wrap: wrap; }
.pdp-details { display: grid; grid-template-columns: auto 1fr; gap: 8px 24px; font-size: 15px; }
.pdp-details dt { color: var(--muted); }
.pdp-details dd { margin: 0; font-weight: 600; }
.related { margin-top: 88px; }
@media (max-width: 900px) { .pdp { grid-template-columns: 1fr; gap: 28px; } .gallery { position: static; } }

/* =========================================================
   Try-on
   ========================================================= */
.tryon { display: grid; grid-template-columns: minmax(0, 1fr) 320px; gap: 40px; align-items: start; }
.stepper { display: flex; gap: 8px; list-style: none; margin: 0 0 28px; padding: 0; counter-reset: step; flex-wrap: wrap; }
.stepper li { display: flex; align-items: center; gap: 8px; font-size: 14px; font-weight: 600; color: var(--muted); }
.stepper li:not(:last-child)::after { content: ""; width: 28px; height: 1px; background: var(--line-2); margin-left: 4px; }
.step-dot { width: 28px; height: 28px; border-radius: 50%; border: 1.5px solid var(--line-2); display: flex; align-items: center; justify-content: center; font-size: 13px; }
.stepper li.is-current { color: var(--ink); }
.stepper li.is-current .step-dot { background: var(--plum); border-color: var(--plum); color: #fff; }
.stepper li.is-done .step-dot { background: var(--tint); border-color: var(--tint); color: var(--plum); }
.method-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px; }
.method { display: flex; flex-direction: column; align-items: flex-start; gap: 12px; padding: 28px; border: 1.5px solid var(--line-2); border-radius: var(--radius-lg); background: var(--surface); text-align: left; }
.method:hover { border-color: var(--plum); }
.method-icon { width: 56px; height: 56px; border-radius: 50%; background: var(--tint); color: var(--plum); display: flex; align-items: center; justify-content: center; }
.method strong { font-size: 20px; font-family: var(--font-display); font-weight: 500; }
.method span { color: var(--muted); font-size: 15px; line-height: 1.5; }
@media (max-width: 640px) { .method-grid { grid-template-columns: 1fr; } .method { padding: 20px; } }
.model-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 14px; }
.model-card { position: relative; padding: 0; border: 3px solid transparent; border-radius: var(--radius); overflow: hidden; background: var(--tint); aspect-ratio: 3 / 4; }
.model-card img { width: 100%; height: 100%; object-fit: cover; }
.model-card[aria-pressed="true"] { border-color: var(--plum); }
.model-card-check { position: absolute; top: 8px; right: 8px; width: 28px; height: 28px; border-radius: 50%; background: var(--plum); color: #fff; display: none; align-items: center; justify-content: center; }
.model-card[aria-pressed="true"] .model-card-check { display: flex; }
.model-card-name { position: absolute; left: 0; right: 0; bottom: 0; padding: 20px 10px 8px; background: linear-gradient(transparent, rgba(20, 4, 12, .7)); color: #fff; font-size: 13px; font-weight: 700; }
.dropzone { display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 10px; min-height: 260px; padding: 24px; border: 2px dashed var(--line-2); border-radius: var(--radius-lg); background: var(--surface); text-align: center; cursor: pointer; }
.dropzone:hover, .dropzone.is-over { border-color: var(--plum); background: var(--tint-2); }
.dropzone:focus-within { outline: 2px solid var(--gold-deep); outline-offset: 2px; }
.dropzone strong { font-size: 17px; }
.dropzone span { color: var(--muted); font-size: 14px; }
.dropzone-icon { width: 56px; height: 56px; border-radius: 50%; background: var(--tint); color: var(--plum); display: flex; align-items: center; justify-content: center; }
.photo-preview { display: grid; grid-template-columns: 200px 1fr; gap: 20px; align-items: start; }
.photo-preview img { width: 200px; aspect-ratio: 3 / 4; object-fit: cover; border-radius: var(--radius); }
.tips { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 10px; }
.tips li { display: flex; gap: 10px; align-items: center; font-size: 15px; }
.tips svg { color: var(--ok); flex-shrink: 0; }
@media (max-width: 560px) { .photo-preview { grid-template-columns: 1fr; } .photo-preview img { width: 100%; max-width: 260px; } }
.tryon-actions { display: flex; gap: 12px; margin-top: 28px; flex-wrap: wrap; }
.tryon-side { position: sticky; top: 100px; display: flex; flex-direction: column; gap: 14px; padding: 20px; border-radius: var(--radius-lg); background: var(--surface); }
.tryon-side h2 { font-family: var(--font-body); font-size: 15px; font-weight: 700; }
.mini-item { display: flex; gap: 12px; align-items: center; }
.mini-item-img { width: 56px; height: 56px; flex-shrink: 0; border-radius: 10px; overflow: hidden; }
.mini-item-img .pimg-empty svg { width: 30px; height: 30px; }
.mini-item-name { font-weight: 700; font-size: 14px; line-height: 1.3; }
.mini-item .price-now { font-size: 14px; }
.generating { display: flex; flex-direction: column; align-items: center; gap: 20px; padding: 64px 16px; text-align: center; }
.generating-art { position: relative; width: 120px; height: 120px; border-radius: 50%; background: var(--tint); color: var(--plum); display: flex; align-items: center; justify-content: center; }
.generating-art::after { content: ""; position: absolute; inset: -6px; border-radius: 50%; border: 3px solid transparent; border-top-color: var(--gold); animation: spin 1.2s linear infinite; }
.generating h2 { font-size: 30px; }
.generating p { color: var(--muted); }
.result { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 32px; align-items: start; }
.result-img { border-radius: var(--radius-lg); overflow: hidden; background: var(--tint); aspect-ratio: 3 / 4; }
.result-img img { width: 100%; height: 100%; object-fit: cover; }
.result-info { display: flex; flex-direction: column; gap: 18px; }
.result-info h2 { font-size: 36px; }
.result-note { font-size: 13px; color: var(--muted); }
@media (max-width: 900px) { .tryon { grid-template-columns: 1fr; } .tryon-side { position: static; order: -1; } .result { grid-template-columns: 1fr; } }

/* =========================================================
   Create your look
   ========================================================= */
.look { display: grid; grid-template-columns: minmax(0, 1fr) 320px; gap: 40px; align-items: start; }
.look-options { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 14px; }
.look-option { position: relative; display: flex; flex-direction: column; gap: 10px; padding: 8px 8px 14px; border: 2px solid transparent; border-radius: 18px; background: var(--surface); text-align: left; }
.look-option:hover { border-color: var(--line-2); }
.look-option[aria-pressed="true"] { border-color: var(--plum); }
.look-option-img { aspect-ratio: 1; border-radius: 12px; overflow: hidden; }
.look-option-name { padding: 0 6px; font-weight: 700; font-size: 14px; line-height: 1.3; }
.look-option .price { padding: 0 6px; }
.look-option .price-now { font-size: 15px; }
.look-option-check { position: absolute; top: 14px; right: 14px; width: 30px; height: 30px; border-radius: 50%; background: var(--plum); color: #fff; display: none; align-items: center; justify-content: center; }
.look-option[aria-pressed="true"] .look-option-check { display: flex; }
.look-tray { position: sticky; top: 100px; display: flex; flex-direction: column; gap: 14px; padding: 20px; border-radius: var(--radius-lg); background: var(--surface); }
.look-tray h2 { font-size: 24px; }
.tray-slot { display: flex; gap: 12px; align-items: center; min-height: 56px; }
.tray-slot-img { width: 56px; height: 56px; flex-shrink: 0; border-radius: 10px; overflow: hidden; background: var(--tint); color: var(--gold-deep); display: flex; align-items: center; justify-content: center; }
.tray-slot-empty .tray-slot-img { border: 1.5px dashed var(--line-2); background: transparent; color: var(--line-2); }
.tray-slot-text { display: flex; flex-direction: column; min-width: 0; font-size: 14px; }
.tray-slot-text strong { line-height: 1.3; }
.tray-total { display: flex; justify-content: space-between; padding-top: 14px; border-top: 1px solid var(--line); font-weight: 700; font-size: 17px; }
.look-nav { display: flex; gap: 12px; margin-top: 28px; justify-content: space-between; flex-wrap: wrap; }
@media (max-width: 900px) { .look { grid-template-columns: 1fr; } .look-tray { position: static; } }

/* =========================================================
   Cart & checkout
   ========================================================= */
.cart { display: grid; grid-template-columns: minmax(0, 1fr) 380px; gap: 40px; align-items: start; }
.cart-lines { display: flex; flex-direction: column; background: var(--surface); border-radius: var(--radius-lg); padding: 8px 24px; }
.cart-line { display: grid; grid-template-columns: 96px minmax(0, 1fr) auto; gap: 20px; padding: 20px 0; border-bottom: 1px solid var(--line); align-items: center; }
.cart-line:last-child { border-bottom: 0; }
.cart-line-img { width: 96px; height: 96px; border-radius: 12px; overflow: hidden; }
.cart-line-img .pimg-empty svg { width: 44px; height: 44px; }
.cart-line-info { display: flex; flex-direction: column; gap: 6px; min-width: 0; }
.cart-line-name { font-weight: 700; color: var(--ink); text-decoration: none; }
.cart-line-name:hover { text-decoration: underline; color: var(--plum); }
.cart-line-controls { display: flex; gap: 12px; align-items: center; margin-top: 4px; flex-wrap: wrap; }
.cart-line-total { font-weight: 700; font-size: 17px; text-align: right; font-variant-numeric: tabular-nums; }
.cart-line-warn { font-size: 13px; color: var(--error); font-weight: 600; }
@media (max-width: 560px) {
  .cart-lines { padding: 4px 16px; }
  .cart-line { grid-template-columns: 72px minmax(0, 1fr); gap: 14px; }
  .cart-line-img { width: 72px; height: 72px; }
  .cart-line-total { grid-column: 2; text-align: left; }
}
.summary { position: sticky; top: 100px; display: flex; flex-direction: column; gap: 14px; padding: 24px; border-radius: var(--radius-lg); background: var(--surface); }
.summary h2 { font-size: 26px; }
.summary-row { display: flex; justify-content: space-between; gap: 12px; font-size: 15px; }
.summary-row span:last-child { font-variant-numeric: tabular-nums; }
.summary-total { padding-top: 14px; border-top: 1px solid var(--line); font-size: 19px; font-weight: 700; }
.summary-note { font-size: 13px; color: var(--muted); }
.free-bar { display: flex; flex-direction: column; gap: 6px; font-size: 13px; color: var(--ink-2); }
.free-bar-track { height: 6px; border-radius: 3px; background: var(--tint); overflow: hidden; }
.free-bar-fill { height: 100%; border-radius: 3px; background: var(--plum); }
.summary-items { display: flex; flex-direction: column; gap: 12px; max-height: 320px; overflow-y: auto; padding: 8px 8px 4px 0; margin-top: -8px; }
.summary-item { display: grid; grid-template-columns: 52px minmax(0, 1fr) auto; gap: 12px; align-items: center; font-size: 14px; }
.summary-item-img { position: relative; width: 52px; height: 52px; border-radius: 10px; overflow: visible; }
.summary-item-img .pimg { border-radius: 10px; }
.summary-item-img .pimg-empty svg { width: 26px; height: 26px; }
.summary-item-qty { position: absolute; top: -6px; right: -6px; min-width: 20px; height: 20px; padding: 0 5px; border-radius: 10px; background: var(--ink); color: #fff; font-size: 11px; font-weight: 700; line-height: 20px; text-align: center; }
@media (max-width: 960px) { .cart { grid-template-columns: 1fr; } .summary { position: static; } }
.checkout-section { display: flex; flex-direction: column; gap: 18px; padding: 28px; border-radius: var(--radius-lg); background: var(--surface); }
.checkout-section h2 { display: flex; align-items: center; gap: 12px; font-size: 26px; }
.checkout-num { width: 32px; height: 32px; border-radius: 50%; background: var(--plum); color: #fff; font-family: var(--font-body); font-size: 15px; font-weight: 700; display: flex; align-items: center; justify-content: center; }
.checkout-sections { display: flex; flex-direction: column; gap: 20px; }
.bank-box { padding: 16px; border-radius: var(--radius-sm); background: var(--tint-2); border: 1px solid var(--line); font-size: 14px; line-height: 1.6; white-space: pre-line; }
@media (max-width: 560px) { .checkout-section { padding: 20px 16px; } }

/* =========================================================
   Order confirmation & tracking
   ========================================================= */
.confirm { max-width: 720px; margin: 0 auto; display: flex; flex-direction: column; gap: 24px; }
.confirm-hero { display: flex; flex-direction: column; align-items: center; text-align: center; gap: 14px; padding: 40px 24px; border-radius: var(--radius-lg); background: var(--surface); }
.confirm-icon { width: 72px; height: 72px; border-radius: 50%; background: var(--ok-bg); color: var(--ok); display: flex; align-items: center; justify-content: center; }
.confirm-hero h1 { font-size: clamp(34px, 5vw, 44px); }
.order-no { font-size: 15px; color: var(--muted); }
.order-no strong { display: block; margin-top: 4px; font-size: 28px; color: var(--plum); letter-spacing: .02em; font-variant-numeric: tabular-nums; }
.card { padding: 24px; border-radius: var(--radius-lg); background: var(--surface); }
.card h2 { font-size: 24px; margin-bottom: 16px; }
.card-actions { display: flex; gap: 12px; flex-wrap: wrap; justify-content: center; }
.timeline { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; }
.tl-step { position: relative; display: grid; grid-template-columns: 32px 1fr; gap: 14px; padding-bottom: 22px; }
.tl-step:last-child { padding-bottom: 0; }
.tl-step:not(:last-child)::before { content: ""; position: absolute; left: 15px; top: 30px; bottom: 0; width: 2px; background: var(--line); }
.tl-step.is-done:not(:last-child)::before { background: var(--plum); }
.tl-dot { width: 32px; height: 32px; border-radius: 50%; border: 2px solid var(--line-2); background: var(--surface); display: flex; align-items: center; justify-content: center; color: #fff; z-index: 1; }
.tl-step.is-done .tl-dot { background: var(--plum); border-color: var(--plum); }
.tl-step.is-current .tl-dot { background: var(--surface); border-color: var(--plum); box-shadow: 0 0 0 4px var(--tint); }
.tl-step.is-current .tl-dot::after { content: ""; width: 12px; height: 12px; border-radius: 50%; background: var(--plum); }
.tl-text { display: flex; flex-direction: column; padding-top: 4px; }
.tl-text strong { font-size: 16px; }
.tl-step:not(.is-done):not(.is-current) .tl-text strong { color: var(--muted); font-weight: 600; }
.tl-text span { font-size: 13px; color: var(--muted); }
.track-grid { display: grid; grid-template-columns: 360px minmax(0, 1fr); gap: 32px; align-items: start; }
@media (max-width: 860px) { .track-grid { grid-template-columns: 1fr; } }
.order-lines { display: flex; flex-direction: column; gap: 12px; }
.order-line { display: grid; grid-template-columns: 52px minmax(0, 1fr) auto; gap: 12px; align-items: center; font-size: 15px; }
.order-line-img { width: 52px; height: 52px; border-radius: 10px; overflow: hidden; }
.order-line-img .pimg-empty svg { width: 26px; height: 26px; }
.order-totals { display: flex; flex-direction: column; gap: 8px; margin-top: 16px; padding-top: 16px; border-top: 1px solid var(--line); }

/* =========================================================
   Account
   ========================================================= */
.account { display: grid; grid-template-columns: 240px minmax(0, 1fr); gap: 40px; align-items: start; }
.account-nav { display: flex; flex-direction: column; gap: 4px; position: sticky; top: 100px; }
.account-nav a, .account-nav button { display: flex; align-items: center; gap: 12px; min-height: 48px; padding: 0 14px; border: 0; border-radius: 12px; background: none; color: var(--ink); text-decoration: none; font-weight: 600; font-size: 15px; text-align: left; }
.account-nav a:hover, .account-nav button:hover { background: var(--tint); color: var(--ink); }
.account-nav a.active { background: var(--plum); color: #fff; }
@media (max-width: 860px) {
  .account { grid-template-columns: 1fr; gap: 20px; }
  .account-nav { position: static; flex-direction: row; overflow-x: auto; gap: 6px; margin: 0 calc(-1 * var(--gutter)); padding: 0 var(--gutter) 4px; }
  .account-nav a, .account-nav button { flex-shrink: 0; min-height: 44px; border: 1px solid var(--line-2); border-radius: 999px; white-space: nowrap; }
  .account-nav a.active { border-color: var(--plum); }
}
.order-card { display: flex; flex-direction: column; gap: 16px; padding: 20px 24px; border-radius: var(--radius-lg); background: var(--surface); }
.order-card-head { display: flex; justify-content: space-between; align-items: flex-start; gap: 12px; flex-wrap: wrap; }
.order-card-head strong { font-size: 17px; }
.order-card-thumbs { display: flex; gap: 8px; }
.order-card-thumbs .order-line-img { width: 56px; height: 56px; }
.order-card-foot { display: flex; justify-content: space-between; align-items: center; gap: 12px; flex-wrap: wrap; }
.stack { display: flex; flex-direction: column; gap: 16px; }
.tryon-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 16px; }
.tryon-card { display: flex; flex-direction: column; gap: 10px; padding: 8px 8px 14px; border-radius: 18px; background: var(--surface); }
.tryon-card img { aspect-ratio: 3 / 4; object-fit: cover; border-radius: 12px; }
.tryon-card-body { padding: 0 6px; display: flex; flex-direction: column; gap: 4px; font-size: 14px; }

/* =========================================================
   Info pages
   ========================================================= */
.prose { display: flex; flex-direction: column; gap: 16px; font-size: 17px; line-height: 1.7; color: var(--ink-2); }
.prose h2 { font-size: 28px; color: var(--ink); margin-top: 16px; }
.faq { display: flex; flex-direction: column; gap: 10px; }
.faq details { border-radius: var(--radius); background: var(--surface); }
.faq summary { display: flex; justify-content: space-between; align-items: center; gap: 12px; min-height: 60px; padding: 14px 20px; font-weight: 700; font-size: 17px; cursor: pointer; list-style: none; }
.faq summary::-webkit-details-marker { display: none; }
.faq summary svg { flex-shrink: 0; transition: transform .15s; }
.faq details[open] summary svg { transform: rotate(180deg); }
.faq details > div { padding: 0 20px 20px; color: var(--ink-2); line-height: 1.7; }
.contact-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 16px; }
.contact-card { display: flex; flex-direction: column; gap: 10px; padding: 24px; border-radius: var(--radius-lg); background: var(--surface); color: var(--ink); text-decoration: none; }
a.contact-card:hover { color: var(--ink); box-shadow: 0 0 0 1.5px var(--plum); }
.contact-card-icon { width: 48px; height: 48px; border-radius: 50%; background: var(--tint); color: var(--plum); display: flex; align-items: center; justify-content: center; }
.contact-card strong { font-size: 17px; }
.contact-card span { color: var(--muted); font-size: 15px; word-break: break-word; }
.not-found { display: flex; flex-direction: column; align-items: center; text-align: center; gap: 16px; padding: 96px var(--gutter); }
.not-found h1 { font-size: clamp(40px, 6vw, 64px); }
.not-found p { color: var(--muted); max-width: 46ch; }
.not-found-art { color: var(--gold-deep); }

/* =========================================================
   Auth pages
   ========================================================= */
.auth { min-height: 100vh; display: grid; grid-template-columns: minmax(0, 5fr) minmax(0, 6fr); background: var(--pearl); }
.auth-aside { display: flex; flex-direction: column; justify-content: space-between; padding: 48px 56px; background: var(--plum); color: var(--on-dark); }
.auth-logo { font-family: var(--font-display); font-size: 28px; font-weight: 600; color: #fff !important; text-decoration: none; }
.auth-aside-body { max-width: 420px; }
.auth-aside-body h2 { margin: 0 0 16px; font-size: 48px; line-height: 1.05; color: #fff; }
.auth-aside-body p { font-size: 17px; line-height: 1.6; }
.auth-main { padding: 48px 24px; display: flex; align-items: center; justify-content: center; }
.auth-card { width: 100%; max-width: 420px; }
.auth-card h1 { margin: 0 0 8px; font-size: 40px; }
.auth-sub { margin: 0 0 32px; color: var(--muted); line-height: 1.5; }
.auth-switch { margin: 20px 0 0; text-align: center; font-size: 15px; color: var(--muted); }
.auth-switch a { font-weight: 700; }
@media (max-width: 860px) {
  .auth { grid-template-columns: 1fr; }
  .auth-aside { padding: 16px 24px; }
  .auth-aside-body { display: none; }
  .auth-main { align-items: flex-start; padding-top: 40px; }
}

/* =========================================================
   Admin shell
   ========================================================= */
.admin-shell { min-height: 100vh; display: grid; grid-template-columns: 248px minmax(0, 1fr); background: linear-gradient(to right, var(--plum-deep) 248px, var(--pearl) 248px); }
.admin-side { position: sticky; top: 0; height: 100vh; display: flex; flex-direction: column; gap: 28px; padding: 24px 16px; background: var(--plum-deep); color: var(--on-dark); overflow-y: auto; }
.admin-logo { padding: 0 12px; font-family: var(--font-display); font-size: 24px; font-weight: 600; color: #fff !important; text-decoration: none; }
.admin-nav { display: flex; flex-direction: column; gap: 2px; flex: 1; }
.admin-nav a, .admin-side-link { display: flex; align-items: center; gap: 12px; min-height: 44px; padding: 0 12px; border: 0; border-radius: 10px; background: transparent; color: var(--on-dark); font-size: 15px; font-weight: 600; text-decoration: none; text-align: left; width: 100%; }
.admin-nav a:hover, .admin-side-link:hover { background: rgba(255, 255, 255, .08); color: #fff; }
.admin-nav a.active { background: var(--gold); color: var(--plum-deep); }
.admin-nav-count { margin-left: auto; min-width: 22px; height: 22px; padding: 0 6px; border-radius: 11px; background: var(--gold); color: var(--plum-deep); font-size: 12px; font-weight: 700; line-height: 22px; text-align: center; }
.admin-nav a.active .admin-nav-count { background: var(--plum-deep); color: var(--gold); }
.admin-side-foot { display: flex; flex-direction: column; gap: 2px; padding-top: 16px; border-top: 1px solid #4a2336; }
.admin-main { min-width: 0; display: flex; flex-direction: column; }
.admin-top { height: 64px; display: flex; align-items: center; justify-content: flex-end; gap: 12px; padding: 0 32px; background: var(--surface); border-bottom: 1px solid var(--line); }
.admin-menu { display: none; margin-right: auto; }
.admin-user { display: flex; align-items: center; gap: 8px; font-size: 14px; font-weight: 600; }
.admin-content { padding: 32px; }
.admin-scrim { display: none; }
@media (max-width: 900px) {
  .admin-shell { grid-template-columns: 1fr; background: var(--pearl); }
  .admin-side { position: fixed; z-index: 70; left: 0; width: 264px; transform: translateX(-100%); transition: transform .2s ease; visibility: hidden; }
  .admin-side.is-open { transform: translateX(0); visibility: visible; }
  .admin-menu { display: inline-flex; }
  .admin-top { padding: 0 12px 0 8px; position: sticky; top: 0; z-index: 30; }
  .admin-content { padding: 20px 16px 64px; }
  .admin-scrim { display: block; position: fixed; inset: 0; z-index: 65; padding: 0; border: 0; background: rgba(20, 4, 12, .45); }
}
.admin-page { display: flex; flex-direction: column; gap: 24px; max-width: 1240px; }
.admin-head { display: flex; align-items: flex-end; justify-content: space-between; gap: 16px; flex-wrap: wrap; }
.admin-head h1 { font-size: clamp(30px, 4vw, 40px); }
.admin-head p { margin-top: 4px; color: var(--muted); }
.admin-head-actions { display: flex; gap: 10px; flex-wrap: wrap; }
.back-link { display: inline-flex; align-items: center; gap: 6px; font-weight: 700; font-size: 14px; text-decoration: none; min-height: 32px; }
.panel { padding: 22px; border-radius: var(--radius); background: var(--surface); border: 1px solid var(--line); min-width: 0; }
.panel-head { display: flex; align-items: baseline; justify-content: space-between; gap: 12px; margin-bottom: 18px; flex-wrap: wrap; }
.panel-head h2 { font-size: 22px; }
.panel-meta { font-size: 14px; color: var(--muted); font-weight: 600; }
.panel-link { font-size: 14px; font-weight: 700; }
.panel-flush { padding: 0; overflow: hidden; }
.toolbar { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
.toolbar .search { flex: 1; min-width: 200px; max-width: 360px; }
.toolbar select { min-height: 44px; padding: 0 12px; border: 1px solid var(--line-2); border-radius: 999px; background: var(--surface); font-size: 14px; font-weight: 600; }
.tabs { display: flex; gap: 6px; overflow-x: auto; padding-bottom: 2px; }
.tab { flex-shrink: 0; display: inline-flex; align-items: center; gap: 8px; min-height: 40px; padding: 0 14px; border: 1px solid var(--line-2); border-radius: 999px; background: var(--surface); font-size: 14px; font-weight: 600; color: var(--ink); }
.tab:hover { border-color: var(--plum); }
.tab[aria-pressed="true"] { background: var(--plum); border-color: var(--plum); color: #fff; }
.tab-count { min-width: 20px; height: 20px; padding: 0 6px; border-radius: 10px; background: var(--tint); color: var(--plum); font-size: 12px; font-weight: 700; line-height: 20px; text-align: center; }
.tab[aria-pressed="true"] .tab-count { background: rgba(255, 255, 255, .2); color: #fff; }

/* Admin tables */
.table-scroll { overflow-x: auto; }
.table { width: 100%; border-collapse: collapse; font-size: 14px; }
.table th, .table td { padding: 12px 14px; border-bottom: 1px solid var(--line); text-align: left; vertical-align: middle; white-space: nowrap; }
.table th { font-size: 13px; font-weight: 600; color: var(--muted); background: var(--tint-2); }
.table tbody tr:last-child td { border-bottom: 0; }
.table tbody tr:hover td { background: #faf8fa; }
.table a { font-weight: 700; }
.table .num { text-align: right; font-variant-numeric: tabular-nums; }
.table .wrap-cell { white-space: normal; min-width: 180px; }
.table-thumb { width: 44px; height: 44px; border-radius: 8px; overflow: hidden; flex-shrink: 0; }
.table-thumb .pimg-empty svg { width: 24px; height: 24px; }
.cell-product { display: flex; align-items: center; gap: 12px; }
.cell-product strong { display: block; }
.cell-product .muted { font-size: 13px; }
.row-actions { display: flex; gap: 4px; justify-content: flex-end; }
.is-hidden-row td { color: var(--muted); }
.stock-num-low { color: var(--warn); font-weight: 700; }
.stock-num-out { color: var(--error); font-weight: 700; }

/* Admin forms */
.admin-form { display: grid; grid-template-columns: minmax(0, 1fr) 340px; gap: 24px; align-items: start; }
.admin-form-main, .admin-form-side { display: flex; flex-direction: column; gap: 20px; }
.admin-form-side { position: sticky; top: 88px; }
@media (max-width: 1100px) { .admin-form { grid-template-columns: 1fr; } .admin-form-side { position: static; } }
.save-bar { position: sticky; bottom: 0; z-index: 20; display: flex; justify-content: flex-end; gap: 10px; margin: 0 -32px -32px; padding: 14px 32px; background: var(--surface); border-top: 1px solid var(--line); }
@media (max-width: 900px) { .save-bar { margin: 0 -16px -64px; padding: 12px 16px; } }
.image-manager { display: grid; grid-template-columns: repeat(auto-fill, minmax(120px, 1fr)); gap: 12px; }
.im-tile { position: relative; aspect-ratio: 1; border-radius: 12px; overflow: hidden; background: var(--tint); }
.im-tile img { width: 100%; height: 100%; object-fit: cover; }
.im-tile-main { position: absolute; left: 6px; top: 6px; padding: 2px 8px; border-radius: 10px; background: var(--plum); color: #fff; font-size: 11px; font-weight: 700; }
.im-tile-new { position: absolute; left: 6px; top: 6px; padding: 2px 8px; border-radius: 10px; background: var(--gold); color: var(--plum-deep); font-size: 11px; font-weight: 700; }
.im-tile-actions { position: absolute; right: 4px; bottom: 4px; display: flex; gap: 4px; }
.im-tile-actions .icon-btn { width: 36px; height: 36px; background: var(--surface); box-shadow: 0 1px 4px rgba(0, 0, 0, .2); }
.im-add { display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 6px; aspect-ratio: 1; border: 2px dashed var(--line-2); border-radius: 12px; background: var(--surface); color: var(--plum); font-size: 13px; font-weight: 700; cursor: pointer; text-align: center; padding: 8px; }
.im-add:hover { border-color: var(--plum); background: var(--tint-2); }
.im-add:focus-within { outline: 2px solid var(--gold-deep); outline-offset: 2px; }
.im-add input { position: absolute; opacity: 0; width: 1px; height: 1px; }
.asset-row { display: flex; gap: 14px; align-items: center; }
.asset-preview { width: 88px; height: 88px; flex-shrink: 0; border-radius: 12px; background: repeating-conic-gradient(#eee 0% 25%, #fff 0% 50%) 50% / 16px 16px; overflow: hidden; display: flex; align-items: center; justify-content: center; color: var(--muted); }
.asset-preview img { width: 100%; height: 100%; object-fit: contain; }
.gallery-admin { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 16px; }
.model-admin { display: flex; flex-direction: column; gap: 10px; padding: 8px 8px 12px; border-radius: var(--radius); background: var(--surface); border: 1px solid var(--line); }
.model-admin img { aspect-ratio: 3 / 4; object-fit: cover; border-radius: 10px; }
.model-admin.is-off img { opacity: .45; }
.model-admin-body { display: flex; justify-content: space-between; align-items: center; gap: 8px; padding: 0 4px; }
.model-admin-body strong { font-size: 15px; }
.model-admin-actions { display: flex; gap: 6px; padding: 0 4px; }
.detail-grid { display: grid; grid-template-columns: minmax(0, 1fr) 360px; gap: 20px; align-items: start; }
.detail-side { display: flex; flex-direction: column; gap: 20px; }
@media (max-width: 1100px) { .detail-grid { grid-template-columns: 1fr; } }
.kv { display: grid; grid-template-columns: auto 1fr; gap: 8px 16px; font-size: 15px; }
.kv dt { color: var(--muted); }
.kv dd { margin: 0; font-weight: 600; min-width: 0; word-break: break-word; }
.contact-actions { display: flex; gap: 8px; flex-wrap: wrap; margin-top: 12px; }
.status-actions { display: flex; flex-direction: column; gap: 10px; }
.cat-row-img { width: 44px; height: 44px; border-radius: 50%; overflow: hidden; background: var(--tint); color: var(--gold-deep); display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.cat-row-img img { width: 100%; height: 100%; object-fit: cover; }

/* Dashboard */
.stats { display: grid; grid-template-columns: 1.4fr repeat(3, minmax(0, 1fr)); gap: 16px; }
.stat { display: flex; flex-direction: column; gap: 6px; padding: 22px; border-radius: var(--radius); background: var(--surface); border: 1px solid var(--line); color: var(--ink); text-decoration: none; }
.stat-label { font-size: 14px; font-weight: 600; color: var(--muted); }
.stat-value { font-size: 36px; font-weight: 700; line-height: 1.1; font-variant-numeric: tabular-nums; }
.stat-note { font-size: 13px; color: var(--muted); }
.stat-hero { background: var(--plum); border-color: var(--plum); color: #fff; }
.stat-hero .stat-label, .stat-hero .stat-note { color: var(--on-dark); }
a.stat:hover { border-color: var(--plum); color: var(--ink); }
.stat-link .stat-note { color: var(--plum); font-weight: 600; }
@media (max-width: 1100px) { .stats { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
@media (max-width: 520px) { .stats { grid-template-columns: 1fr; } .stat-value { font-size: 30px; } }
.dash-grid { display: grid; grid-template-columns: minmax(0, 2fr) minmax(0, 1fr); gap: 16px; }
.panel-wide { grid-column: 1 / -1; }
@media (max-width: 1000px) { .dash-grid { grid-template-columns: 1fr; } }
.stock-list { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; }
.stock-list li { display: flex; align-items: center; justify-content: space-between; gap: 12px; padding: 12px 0; border-bottom: 1px solid var(--line); }
.stock-list li:last-child { border-bottom: 0; }
.stock-name { display: flex; flex-direction: column; gap: 2px; font-weight: 600; min-width: 0; }
.stock-name .muted { font-size: 13px; font-weight: 400; }
a.stock-name { color: var(--ink); text-decoration: none; }
a.stock-name:hover { color: var(--plum); text-decoration: underline; }
.stock-count { flex-shrink: 0; display: inline-flex; align-items: center; gap: 4px; padding: 4px 10px; border-radius: 12px; background: var(--warn-bg); color: var(--warn); font-size: 13px; font-weight: 700; }
.stock-count.is-out { background: var(--error-bg); color: var(--error); }

/* Bar chart */
.bars { position: relative; display: grid; gap: 10px; padding: 0 0 0 44px; }
.bars-dense { gap: 3px; }
.bars-grid { position: absolute; left: 0; right: 0; top: 0; bottom: 28px; display: flex; flex-direction: column; justify-content: space-between; pointer-events: none; }
.bars-grid span { position: relative; font-size: 12px; color: var(--muted); line-height: 0; font-variant-numeric: tabular-nums; }
.bars-grid span::after { content: ""; position: absolute; left: 44px; right: 0; top: 0; border-top: 1px solid var(--line); }
.bar-col { position: relative; display: flex; flex-direction: column; gap: 8px; min-width: 0; outline: none; }
.bar-track { position: relative; flex: 1; display: flex; align-items: flex-end; justify-content: center; }
.bar { width: min(36px, 72%); min-height: 2px; border-radius: 4px 4px 0 0; background: var(--plum-soft); }
.bars-dense .bar { width: 100%; }
.bar.is-highlight { background: var(--plum); }
.bar-col:hover .bar, .bar-col:focus-visible .bar { background: var(--plum-2); }
.bar-col:focus-visible .bar-track { outline: 2px solid var(--gold-deep); outline-offset: 2px; border-radius: 4px; }
.bar-label { height: 20px; font-size: 12px; font-weight: 600; color: var(--muted); text-align: center; white-space: nowrap; overflow: visible; }
.bar-tip { position: absolute; z-index: 2; bottom: 50%; left: 50%; transform: translateX(-50%); display: none; flex-direction: column; gap: 2px; padding: 8px 12px; border-radius: 8px; background: var(--ink); color: #fff; font-size: 12px; white-space: nowrap; pointer-events: none; }
.bar-tip.tip-left { left: auto; right: 0; transform: none; }
.bar-tip.tip-right { left: 0; transform: none; }
.bar-tip strong { font-size: 14px; }
.bar-col:hover .bar-tip, .bar-col:focus-visible .bar-tip { display: flex; }
.hbars { display: flex; flex-direction: column; gap: 12px; }
.hbar { display: grid; grid-template-columns: 110px minmax(0, 1fr) 44px; gap: 12px; align-items: center; font-size: 14px; }
.hbar-track { height: 10px; border-radius: 5px; background: var(--tint-2); overflow: hidden; }
.hbar-fill { height: 100%; border-radius: 0 4px 4px 0; background: var(--plum-soft); min-width: 2px; }
.hbar-value { text-align: right; font-weight: 700; font-variant-numeric: tabular-nums; }
.rank-list { list-style: none; margin: 0; padding: 0; counter-reset: rank; display: flex; flex-direction: column; }
.rank-list li { counter-increment: rank; display: grid; grid-template-columns: 28px minmax(0, 1fr) auto; gap: 10px; align-items: center; padding: 10px 0; border-bottom: 1px solid var(--line); font-size: 14px; }
.rank-list li:last-child { border-bottom: 0; }
.rank-list li::before { content: counter(rank); width: 24px; height: 24px; border-radius: 50%; background: var(--tint); color: var(--plum); font-size: 12px; font-weight: 700; display: flex; align-items: center; justify-content: center; }
.rank-list strong { font-variant-numeric: tabular-nums; }
.report-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px; }
@media (max-width: 900px) { .report-grid { grid-template-columns: 1fr; } }

/* =========================================================
   Print (order packing slip)
   ========================================================= */
.print-only { display: none; }
@media print {
  body { background: #fff; }
  .admin-side, .admin-top, .no-print, .toasts { display: none !important; }
  .admin-shell { display: block; background: #fff; }
  .admin-content { padding: 0; }
  .print-only { display: block; }
  .panel { border: 1px solid #ccc; break-inside: avoid; }
  .detail-grid { grid-template-columns: 1fr; }
}
'@

Write-ProjectFile 'frontend\tsconfig.json' @'
{
  "compilerOptions": {
    "target": "ES2020", "lib": ["ES2020", "DOM", "DOM.Iterable"], "module": "ESNext",
    "moduleResolution": "bundler", "jsx": "react-jsx", "strict": true, "noEmit": true, "skipLibCheck": true
  },
  "include": ["src"]
}
'@

Write-ProjectFile 'frontend\vite.config.ts' @'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
export default defineConfig({
  plugins: [react()],
  server: { proxy: { "/api": "http://127.0.0.1:4000", "/uploads": "http://127.0.0.1:4000" } },
});
'@

# Tidy up loose files from earlier downloads
$loose = @('Account.tsx','AdminLayout.tsx','AdminLogin.tsx','AiModels.tsx','App.tsx','AuthContext.tsx','AuthShell.tsx','BarChart.tsx','BuildLook.tsx','Cart.tsx','CartContext.tsx','Categories.tsx','Checkout.tsx','Customers.tsx','Dashboard.tsx','Home.tsx','Icon.tsx','Info.tsx','JewelIcon.tsx','Layout.tsx','Login.tsx','Offers.tsx','OrderConfirmation.tsx','OrderDetail.tsx','OrderView.tsx','Orders.tsx','PasswordInput.tsx','ProductCard.tsx','ProductDetails.tsx','ProductForm.tsx','Products.tsx','Register.tsx','Reports.tsx','RequireAdmin.tsx','RequireAuth.tsx','Settings.tsx','SettingsContext.tsx','Shop.tsx','ToastContext.tsx','TrackOrder.tsx','TryOn.tsx','WishlistContext.tsx','client.ts','format.ts','main.tsx','styles.css','types.ts','ui.tsx','admin.routes.ts')
foreach ($n in $loose) { $p = Join-Path $here "frontend\$n"; if (Test-Path $p) { Remove-Item $p } }
$envFile = Join-Path $here 'backend\.env'
if (-not (Test-Path $envFile)) { Copy-Item (Join-Path $here 'backend\.env.example') $envFile; Write-Host 'Created backend\.env from .env.example - check DATABASE_URL.' }

Write-Host 'Done: 81 files written.'
Write-Host ''
Write-Host 'Next, in backend:  npm install ; npx prisma migrate dev --name full-site ; npm run seed ; npm run dev'
Write-Host 'Then in frontend: npm install ; npm run dev'
