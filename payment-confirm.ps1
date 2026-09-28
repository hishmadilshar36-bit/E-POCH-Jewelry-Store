# E-POCH Jewelry Store - orders are confirmed when the payment is received.
# Save in C:\E-POCH-Jewelry-Store-main, then run:
#   powershell -ExecutionPolicy Bypass -File .\payment-confirm.ps1

$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)
if (-not (Test-Path (Join-Path $here 'frontend'))) { Write-Host 'Put this script in the folder that contains backend and frontend, then run it again.'; exit 1 }
function Write-ProjectFile($rel, $content) {
  $path = Join-Path $here $rel
  $dir = Split-Path $path -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
  [System.IO.File]::WriteAllText($path, (($content -replace "`r`n", "`n") + "`n"), $utf8)
}

Write-ProjectFile 'backend\src\modules\orders\orders.service.ts' @'
import { Order, OrderStatus, PaymentStatus, Prisma } from "@prisma/client";
import { db } from "../../config/db";
import { HttpError } from "../../middleware/error";
import { getActiveOffers, unitPrice } from "../../services/pricing";
import { deliveryFeeFor, getSettings } from "../../services/settings";
import { notifyPaymentConfirmed, notifyStatusChanged } from "../../services/notify";

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

// Bank transfer and online orders are confirmed only after the payment is received.
// Cash on delivery is paid at the door, so those orders are confirmed by the shop.
export const needsPaymentFirst = (o: Pick<Order, "paymentMethod" | "paymentStatus">) =>
  o.paymentMethod !== "COD" && o.paymentStatus !== "PAID";

export const allowedNext = (o: Pick<Order, "status" | "paymentMethod" | "paymentStatus">) =>
  nextStatuses[o.status].filter((s) => !(s === "CONFIRMED" && needsPaymentFirst(o)));

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
  if (to === "CONFIRMED" && needsPaymentFirst(o)) throw new HttpError(409, "Mark the payment as paid first. The order is confirmed when the payment is received.");

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

// Marking a pending order as paid confirms it and tells the customer.
export async function setPayment(orderId: string, paymentStatus: PaymentStatus) {
  const o = await db.order.findUnique({ where: { id: orderId } });
  if (!o) throw new HttpError(404, "Order not found");
  const confirm = paymentStatus === "PAID" && o.status === "PENDING";
  const updated = await db.$transaction(async (tx) => {
    if (confirm) await tx.orderStatusLog.create({ data: { orderId, status: "CONFIRMED" } });
    return tx.order.update({ where: { id: orderId }, data: { paymentStatus, ...(confirm ? { status: "CONFIRMED" as const } : {}) } });
  });
  if (confirm) notifyPaymentConfirmed(updated).catch(console.error);
  return { ...updated, confirmed: confirm };
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
  await send(order.mobile, `${s.shopName}: order ${order.orderNo} received.\n${lines}\nTotal ${lkr(order.total)}.${order.paymentMethod === "COD" ? "" : "\nYour order is confirmed once we receive your payment."}\nTrack it with your order number and mobile number.`);
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

export async function notifyPaymentConfirmed(order: Order) {
  const s = await getSettings();
  await send(order.mobile, `${s.shopName}: we received your payment of ${lkr(order.total)}. Your order ${order.orderNo} is confirmed.`);
}
'@

Write-ProjectFile 'backend\src\modules\admin\admin.routes.ts' @'
import { Router } from "express";
import { z } from "zod";
import { Prisma } from "@prisma/client";
import { db } from "../../config/db";
import { ah, HttpError } from "../../middleware/error";
import { requireAdmin } from "../../middleware/auth";
import { upload, fileUrl } from "../../middleware/upload";
import { allowedNext, changeStatus, setPayment } from "../orders/orders.service";

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
  res.json({ ...o, nextStatuses: allowedNext(o) });
}));

r.patch("/orders/:id/status", ah(async (req, res) => {
  const { status } = z.object({ status: z.enum(orderStatuses) }).parse(req.body);
  res.json(await changeStatus(req.params.id, status));
}));

r.patch("/orders/:id/payment", ah(async (req, res) => {
  const { paymentStatus } = z.object({ paymentStatus: z.enum(["UNPAID", "PAID", "REFUNDED"]) }).parse(req.body);
  res.json(await setPayment(req.params.id, paymentStatus));
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
  nextStatuses?: OrderStatus[]; user?: { id: string; email: string } | null; confirmed?: boolean;
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
  PENDING: "Order received", CONFIRMED: "Order confirmed", PROCESSING: "Being prepared", READY: "Ready",
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

Write-ProjectFile 'frontend\src\components\OrderView.tsx' @'
import { Link } from "react-router-dom";
import type { Order, OrderStatus } from "../api/types";
import { customerStatus, dateTime, deliveryLabel, lkr, paymentLabel, paymentStatusLabel } from "../api/format";
import { useSettings } from "../context/SettingsContext";
import Icon from "./Icon";
import { ProductImage } from "./ui";

// Bank transfer and online orders are confirmed once the payment is received.
export const awaitingPayment = (o: Order) => o.status === "PENDING" && o.paymentMethod !== "COD" && o.paymentStatus !== "PAID";
export const isConfirmed = (o: Order) => o.status !== "PENDING" && o.status !== "CANCELLED";

export function OrderNotice({ order }: { order: Order }) {
  const s = useSettings();
  if (order.status === "CANCELLED") return null;
  if (isConfirmed(order)) {
    return (
      <div className="notice notice-ok" role="status">
        <Icon name="check" size={22} />
        <div><strong>Your order is confirmed</strong><p>{order.paymentStatus === "PAID" ? `Payment of ${lkr(order.total)} received. ` : ""}We're getting your pieces ready.</p></div>
      </div>
    );
  }
  if (awaitingPayment(order)) {
    return (
      <div className="notice notice-warn" role="status">
        <Icon name="clock" size={22} />
        <div>
          <strong>Waiting for your payment</strong>
          <p>Transfer <strong>{lkr(order.total)}</strong> with <strong>{order.orderNo}</strong> as the reference and send us the slip. Your order is confirmed as soon as we receive it.</p>
          {order.paymentMethod === "BANK_TRANSFER" && (s.bankDetails ? <div className="bank-box">{s.bankDetails}</div> : <p className="muted">We'll send you our bank details on WhatsApp.</p>)}
        </div>
      </div>
    );
  }
  return (
    <div className="notice notice-info" role="status">
      <Icon name="phone" size={22} />
      <div><strong>We'll call you to confirm</strong><p>We'll contact you on {order.mobile} to confirm your order. You pay when it arrives.</p></div>
    </div>
  );
}

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
        <div className="summary-row muted"><span>Payment</span><span>{paymentLabel[order.paymentMethod]}, {paymentStatusLabel[order.paymentStatus].toLowerCase()}</span></div>
      </div>
    </>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\OrderConfirmation.tsx' @'
import { useEffect, useRef, useState } from "react";
import { Link, useLocation, useParams } from "react-router-dom";
import { api } from "../api/client";
import type { Order } from "../api/types";
import { lkr, whatsappLink } from "../api/format";
import { useSettings } from "../context/SettingsContext";
import { useAuth } from "../context/AuthContext";
import { useToast } from "../context/ToastContext";
import Icon from "../components/Icon";
import { OrderLines, OrderNotice, awaitingPayment, isConfirmed } from "../components/OrderView";

const POLL_MS = 15000;

export default function OrderConfirmation() {
  const { orderNo } = useParams();
  const placed = useLocation().state as Order | undefined;
  const s = useSettings();
  const { user } = useAuth();
  const { show } = useToast();
  const [order, setOrder] = useState<Order | undefined>(placed);
  const wasConfirmed = useRef(placed ? isConfirmed(placed) : false);

  // Keep checking while the order waits for payment or a call, so the page updates once it is confirmed.
  useEffect(() => {
    if (!orderNo || !placed?.mobile) return;
    let stop = false;
    const check = async () => {
      if (document.hidden) return;
      try {
        const fresh = await api.trackOrder(orderNo, placed.mobile);
        if (stop) return;
        setOrder(fresh);
        if (!wasConfirmed.current && isConfirmed(fresh)) {
          wasConfirmed.current = true;
          show("Your order is confirmed");
        }
      } catch { /* try again on the next tick */ }
    };
    check();
    const t = window.setInterval(check, POLL_MS);
    return () => { stop = true; window.clearInterval(t); };
  }, [orderNo, placed?.mobile, show]);

  const contact = s.whatsapp || s.phone;
  const msg = `Hi, about my order ${orderNo}${order ? ` (${lkr(order.total)})` : ""}.`;
  const confirmed = order ? isConfirmed(order) : false;
  const cancelled = order?.status === "CANCELLED";
  const waiting = order ? awaitingPayment(order) : false;

  const title = cancelled ? "Your order was cancelled" : confirmed ? "Your order is confirmed" : waiting ? "Order received, waiting for payment" : "Thank you for your order";
  const sub = cancelled
    ? "Contact us if you have any questions about this order."
    : confirmed
      ? `${order?.paymentStatus === "PAID" ? "We received your payment. " : ""}We're getting your pieces ready.`
      : waiting
        ? "Your order is confirmed as soon as we receive your payment."
        : `We'll contact you${order ? ` on ${order.mobile}` : ""} to confirm it. Keep your order number to track it.`;

  return (
    <div className="page">
      <div className="confirm">
        <section className="confirm-hero" aria-live="polite">
          <span className={`confirm-icon ${confirmed ? "" : cancelled ? "is-cancelled" : "is-waiting"}`}>
            <Icon name={confirmed ? "check" : cancelled ? "close" : "clock"} size={36} />
          </span>
          <h1>{title}</h1>
          <p className="order-no">Your order number<strong>{orderNo}</strong></p>
          <p className="muted">{sub}</p>
          <div className="card-actions" style={{ marginTop: 8 }}>
            <Link to={`/track?orderNo=${orderNo}${order ? `&mobile=${order.mobile}` : ""}`} className="btn btn-primary">Track order</Link>
            {contact && <a href={whatsappLink(contact, msg)} target="_blank" rel="noreferrer" className="btn btn-secondary"><Icon name="chat" size={18} />{waiting ? "Send payment slip" : "WhatsApp us"}</a>}
          </div>
        </section>

        {order && !cancelled && !confirmed && <OrderNotice order={order} />}

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

Write-ProjectFile 'frontend\src\pages\TrackOrder.tsx' @'
import { FormEvent, useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { api } from "../api/client";
import type { Order } from "../api/types";
import { customerStatus, shortDate, whatsappLink } from "../api/format";
import { useSettings } from "../context/SettingsContext";
import Icon from "../components/Icon";
import { OrderLines, OrderNotice, OrderTimeline } from "../components/OrderView";

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
              <OrderNotice order={order} />
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
import { OrderLines, OrderNotice, OrderTimeline } from "../components/OrderView";

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
          {o.status === "PENDING" && <OrderNotice order={o} />}
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
    setBusy(true);
    try {
      const r = await api.admin.setPayment(o.id, ps);
      show(r.confirmed ? "Payment received. Order confirmed and the customer was told." : `Payment marked ${paymentStatusLabel[ps].toLowerCase()}`);
      load();
    }
    catch (e) { show((e as Error).message, { kind: "error" }); }
    finally { setBusy(false); }
  };

  const waitingPay = o.status === "PENDING" && o.paymentMethod !== "COD" && o.paymentStatus !== "PAID";
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

      <div className="print-only"><strong>{s.shopName}</strong>{s.phone && <><br />{s.phone}</>}{s.address && <><br />{s.address}</>}</div>

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
          {(actions.length > 0 || canCancel || waitingPay) && (
            <section className="panel no-print">
              <h2 style={{ fontSize: 22, marginBottom: 14 }}>Next step</h2>
              {waitingPay && <p className="muted" style={{ marginBottom: 12 }}>Waiting for payment. Check the slip or your account, then confirm. The customer sees the order as confirmed.</p>}
              <div className="status-actions">
                {waitingPay && <button className="btn btn-primary btn-block" disabled={busy} onClick={() => pay("PAID")}><Icon name="check" size={18} />Payment received, confirm order</button>}
                {actions.map((st, i) => (
                  <button key={st} className={`btn ${i === 0 && !waitingPay ? "btn-primary" : "btn-secondary"} btn-block`} disabled={busy} onClick={() => move(st)}>{labelFor(st)}</button>
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
              {o.paymentStatus !== "PAID" && !waitingPay && <button className="btn btn-secondary btn-sm" disabled={busy} onClick={() => pay("PAID")}><Icon name="check" size={16} />Mark as paid</button>}
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

Write-ProjectFile 'frontend\src\styles.css' @'
/* =========================================================
   Design tokens
   One accent (emerald), one cool-green neutral family, light + dark.
   Radius system: buttons, chips and search are pills; images and cards 16px;
   panels and large containers 20px; inputs and thumbnails 12px.
   ========================================================= */
:root {
  color-scheme: light dark;
  --bg: #f4f5f3;
  --surface: #ffffff;
  --surface-2: #e9ecea;
  --tint: #e4eae7;
  --tint-2: #eff2f0;
  --ink: #151a18;
  --ink-2: #3c4542;
  --muted: #5a6360;
  --line: #dce1de;
  --line-2: #c3cbc7;
  --accent: #0e5a45;
  --accent-2: #0a4636;
  --accent-soft: #dcebe4;
  --accent-muted: #5e8f7f;
  --on-accent: #ffffff;
  --error: #b3261e;
  --error-bg: #fbe9e7;
  --ok: #1b5e3a;
  --ok-bg: #e0f0e6;
  --warn: #7a4d00;
  --warn-bg: #faefd6;
  --info: #1f4470;
  --info-bg: #e3ecf7;
  --side-bg: #13201c;
  --side-ink: #d3dfda;
  --side-line: #26352f;
  --scrim: rgba(10, 22, 18, 0.48);
  --shadow: 0 18px 44px rgba(14, 44, 34, 0.14);
  --shadow-sm: 0 2px 8px rgba(14, 44, 34, 0.12);

  --r-pill: 999px;
  --r-lg: 20px;
  --r: 16px;
  --r-sm: 12px;

  --font: "Geist", ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif;
  --page: 1280px;
  --gutter: 24px;
  --header-h: 72px;
  --ease: cubic-bezier(0.2, 0.7, 0.2, 1);

  /* z-index scale */
  --z-sticky: 30;
  --z-drawer: 60;
  --z-toast: 90;

  font-family: var(--font);
  color: var(--ink);
  background: var(--bg);
  -webkit-font-smoothing: antialiased;
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg: #0e1211;
    --surface: #151a18;
    --surface-2: #1b211f;
    --tint: #1f2624;
    --tint-2: #1a201e;
    --ink: #e9eeeb;
    --ink-2: #c3ccc8;
    --muted: #9aa5a1;
    --line: #29312e;
    --line-2: #3a4440;
    --accent: #4fbf97;
    --accent-2: #6fd0ad;
    --accent-soft: #173a2f;
    --accent-muted: #3e7f6a;
    --on-accent: #06130e;
    --error: #f2b8b5;
    --error-bg: #3a1715;
    --ok: #9fd8b5;
    --ok-bg: #16301f;
    --warn: #f0cd86;
    --warn-bg: #33270e;
    --info: #a9c7ee;
    --info-bg: #16243a;
    --side-bg: #0a0e0d;
    --side-ink: #c9d4d0;
    --side-line: #202824;
    --scrim: rgba(0, 0, 0, 0.6);
    --shadow: 0 18px 44px rgba(0, 0, 0, 0.5);
    --shadow-sm: 0 2px 8px rgba(0, 0, 0, 0.45);
  }
}
@media (max-width: 640px) { :root { --gutter: 16px; --header-h: 64px; } }

/* =========================================================
   Base
   ========================================================= */
* { box-sizing: border-box; }
html { scroll-behavior: smooth; }
body { margin: 0; background: var(--bg); color: var(--ink); font-size: 16px; line-height: 1.55; }
img { max-width: 100%; display: block; }
a { color: var(--accent); text-underline-offset: 3px; transition: color 0.2s var(--ease); }
a:hover { color: var(--accent-2); }
h1, h2, h3 { margin: 0; font-weight: 600; letter-spacing: -0.025em; line-height: 1.08; text-wrap: balance; }
p { margin: 0; text-wrap: pretty; }
button, input, select, textarea { font: inherit; color: inherit; }
button { cursor: pointer; }
button:disabled { cursor: not-allowed; }
:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
::selection { background: var(--accent-soft); color: var(--ink); }
.muted { color: var(--muted); }
.sr-only { position: absolute !important; width: 1px; height: 1px; padding: 0; margin: -1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; border: 0; }
.skip-link { position: absolute; left: 8px; top: -60px; z-index: var(--z-toast); padding: 10px 16px; background: var(--accent); color: var(--on-accent); border-radius: var(--r-sm); }
.skip-link:focus { top: 8px; color: var(--on-accent); }
.page { width: 100%; max-width: var(--page); margin: 0 auto; padding: 36px var(--gutter) 96px; }
.page-narrow { max-width: 820px; }
.page-head { display: flex; flex-direction: column; gap: 8px; margin-bottom: 32px; }
.page-head h1 { font-size: clamp(32px, 4.6vw, 48px); }
.page-head p { color: var(--muted); max-width: 60ch; }
.section-head { display: flex; align-items: baseline; justify-content: space-between; gap: 16px; margin-bottom: 24px; }
.section-head h2 { font-size: clamp(26px, 3.4vw, 36px); }
.section-head a { font-weight: 600; font-size: 15px; white-space: nowrap; }
.num { font-variant-numeric: tabular-nums; }

/* Motion: one reveal on scroll, only when the visitor hasn't asked for reduced motion */
@media (prefers-reduced-motion: no-preference) {
  .reveal { opacity: 0; transform: translateY(18px); transition: opacity 0.6s var(--ease), transform 0.6s var(--ease); transition-delay: calc(var(--i, 0) * 70ms); }
  .reveal.is-in { opacity: 1; transform: none; }
}
@media (prefers-reduced-motion: reduce) {
  html { scroll-behavior: auto; }
  *, *::before, *::after { transition: none !important; animation: none !important; }
}

/* =========================================================
   Buttons
   ========================================================= */
.btn { display: inline-flex; align-items: center; justify-content: center; gap: 8px; min-height: 48px; padding: 0 24px; border-radius: var(--r-pill); border: 1.5px solid transparent; font-size: 15px; font-weight: 600; line-height: 1.2; text-decoration: none; text-align: center; background: none; white-space: nowrap; transition: background-color 0.2s var(--ease), border-color 0.2s var(--ease), color 0.2s var(--ease), transform 0.12s var(--ease); }
.btn:active:not(:disabled) { transform: translateY(1px) scale(0.98); }
.btn:disabled { opacity: 0.45; }
.btn-primary { background: var(--accent); color: var(--on-accent); border-color: var(--accent); }
.btn-primary:hover:not(:disabled) { background: var(--accent-2); border-color: var(--accent-2); color: var(--on-accent); }
.btn-secondary { background: transparent; color: var(--ink); border-color: var(--line-2); }
.btn-secondary:hover:not(:disabled) { border-color: var(--ink); color: var(--ink); }
.btn-quiet { color: var(--ink); border-color: var(--line); background: var(--surface); }
.btn-quiet:hover:not(:disabled) { border-color: var(--ink-2); color: var(--ink); }
.btn-danger { background: var(--error); color: var(--surface); border-color: var(--error); }
.btn-danger:hover:not(:disabled) { filter: brightness(0.92); }
.btn-sm { min-height: 44px; padding: 0 16px; font-size: 14px; }
.btn-lg { min-height: 54px; padding: 0 30px; font-size: 16px; }
.btn-block { width: 100%; }
.btn-icon-text { padding: 0 14px; }
.btn-link { padding: 0; border: 0; background: none; color: var(--accent); font-weight: 600; text-decoration: underline; text-underline-offset: 3px; min-height: 44px; }
.icon-btn { width: 44px; height: 44px; padding: 0; flex-shrink: 0; display: inline-flex; align-items: center; justify-content: center; border: 0; border-radius: var(--r-pill); background: transparent; color: var(--ink); text-decoration: none; position: relative; transition: background-color 0.2s var(--ease), transform 0.12s var(--ease); }
.icon-btn:hover { background: var(--tint); color: var(--ink); }
.icon-btn:active { transform: scale(0.94); }
.icon-btn-sm { width: 36px; height: 36px; }

/* =========================================================
   Forms
   ========================================================= */
.form { display: flex; flex-direction: column; gap: 18px; }
.form-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 18px; }
.form-grid .span-2 { grid-column: 1 / -1; }
@media (max-width: 640px) { .form-grid { grid-template-columns: 1fr; } }
.field { display: flex; flex-direction: column; gap: 6px; min-width: 0; }
.field-label { font-size: 14px; font-weight: 600; }
.field-hint, .optional { font-size: 13px; color: var(--muted); font-weight: 400; }
.input, .field input:not([type="checkbox"]):not([type="radio"]):not([type="file"]), .field select, .field textarea {
  width: 100%; min-height: 48px; padding: 10px 14px; border: 1px solid var(--line-2); border-radius: var(--r-sm); background: var(--surface); color: var(--ink); font-size: 16px; transition: border-color 0.2s var(--ease); }
.field input::placeholder, .field textarea::placeholder, .search input::placeholder { color: var(--muted); opacity: 1; }
.field textarea { min-height: 96px; resize: vertical; }
.field input:disabled { background: var(--tint-2); color: var(--muted); }
.input:focus, .field input:focus, .field select:focus, .field textarea:focus { border-color: var(--accent); outline: 2px solid var(--accent); outline-offset: 0; }
.field input[aria-invalid="true"], .field textarea[aria-invalid="true"] { border-color: var(--error); }
.input-wrap { position: relative; display: block; }
.input-wrap input { padding-right: 52px !important; }
.input-icon { position: absolute; right: 2px; top: 2px; width: 44px; height: 44px; padding: 0; display: flex; align-items: center; justify-content: center; border: 0; border-radius: 10px; background: transparent; color: var(--muted); }
.input-icon:hover { color: var(--accent); }
.form-error { padding: 12px 14px; border-radius: var(--r-sm); background: var(--error-bg); color: var(--error); font-size: 14px; font-weight: 600; }
.form-ok { padding: 12px 14px; border-radius: var(--r-sm); background: var(--ok-bg); color: var(--ok); font-size: 14px; font-weight: 600; }
.fieldset { border: 0; padding: 0; margin: 0; display: flex; flex-direction: column; gap: 12px; }
.fieldset legend { padding: 0; margin-bottom: 12px; font-size: 14px; font-weight: 600; }

.choices { display: grid; gap: 12px; }
.choices-2 { grid-template-columns: repeat(2, minmax(0, 1fr)); }
@media (max-width: 560px) { .choices-2 { grid-template-columns: 1fr; } }
.choice { position: relative; display: flex; gap: 14px; align-items: flex-start; padding: 16px; border: 1.5px solid var(--line); border-radius: var(--r); background: var(--surface); cursor: pointer; transition: border-color 0.2s var(--ease), background-color 0.2s var(--ease); }
.choice:hover { border-color: var(--line-2); }
.choice input { position: absolute; opacity: 0; pointer-events: none; }
.choice-dot { flex-shrink: 0; width: 22px; height: 22px; margin-top: 1px; border: 2px solid var(--line-2); border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.choice-dot::after { content: ""; width: 10px; height: 10px; border-radius: 50%; background: transparent; }
.choice:has(input:checked) { border-color: var(--accent); background: var(--accent-soft); }
.choice:has(input:checked) .choice-dot { border-color: var(--accent); }
.choice:has(input:checked) .choice-dot::after { background: var(--accent); }
.choice:has(input:focus-visible) { outline: 2px solid var(--accent); outline-offset: 2px; }
.choice-body { display: flex; flex-direction: column; gap: 2px; min-width: 0; }
.choice-title { display: flex; align-items: center; gap: 8px; font-weight: 600; }
.choice-note { font-size: 14px; color: var(--muted); }

.switch { display: flex; align-items: flex-start; gap: 12px; cursor: pointer; min-height: 44px; padding: 4px 0; }
.switch input { position: absolute; opacity: 0; width: 1px; height: 1px; }
.switch-track { flex-shrink: 0; position: relative; width: 44px; height: 26px; margin-top: 1px; border-radius: 13px; background: var(--line-2); transition: background-color 0.2s var(--ease); }
.switch-thumb { position: absolute; top: 3px; left: 3px; width: 20px; height: 20px; border-radius: 50%; background: var(--surface); box-shadow: var(--shadow-sm); transition: transform 0.2s var(--ease); }
.switch input:checked + .switch-track { background: var(--accent); }
.switch input:checked + .switch-track .switch-thumb { transform: translateX(18px); }
.switch input:focus-visible + .switch-track { outline: 2px solid var(--accent); outline-offset: 2px; }
.switch-text { display: flex; flex-direction: column; gap: 2px; }
.switch-label { font-weight: 600; }

.qty { display: inline-flex; align-items: center; border: 1px solid var(--line-2); border-radius: var(--r-pill); background: var(--surface); }
.qty-btn { width: 44px; height: 44px; display: flex; align-items: center; justify-content: center; border: 0; border-radius: var(--r-pill); background: none; color: var(--ink); transition: background-color 0.2s var(--ease); }
.qty-btn:hover:not(:disabled) { background: var(--tint); }
.qty-btn:disabled { color: var(--line-2); }
.qty-value { min-width: 32px; text-align: center; font-weight: 600; font-variant-numeric: tabular-nums; }

/* =========================================================
   Header, drawer, footer
   ========================================================= */
.site { min-height: 100dvh; display: flex; flex-direction: column; }
.site-main { flex: 1; }
.site-header { position: sticky; top: 0; z-index: var(--z-sticky); background: color-mix(in srgb, var(--bg) 88%, transparent); backdrop-filter: saturate(1.4) blur(12px); -webkit-backdrop-filter: saturate(1.4) blur(12px); border-bottom: 1px solid var(--line); }
.header-row { max-width: 1440px; margin: 0 auto; height: var(--header-h); padding: 0 var(--gutter); display: flex; align-items: center; gap: 28px; }
.brand { font-size: 22px; font-weight: 700; letter-spacing: -0.03em; color: var(--ink); text-decoration: none; white-space: nowrap; }
.brand:hover { color: var(--accent); }
.main-nav { display: flex; gap: 22px; flex: 1; min-width: 0; }
.main-nav a { color: var(--ink-2); text-decoration: none; font-size: 15px; font-weight: 500; white-space: nowrap; padding: 8px 0; border-bottom: 2px solid transparent; transition: color 0.2s var(--ease), border-color 0.2s var(--ease); }
.main-nav a:hover { color: var(--ink); }
.main-nav a.active { color: var(--ink); font-weight: 600; border-bottom-color: var(--accent); }
.search { display: flex; align-items: center; gap: 8px; height: 44px; padding: 0 16px; border: 1px solid var(--line-2); border-radius: var(--r-pill); background: var(--surface); color: var(--muted); transition: border-color 0.2s var(--ease); }
.search:focus-within { border-color: var(--accent); outline: 2px solid var(--accent); outline-offset: -1px; }
.search input { border: 0; outline: none; background: transparent; width: 100%; min-width: 0; font-size: 15px; color: var(--ink); }
.header-search { width: 240px; flex-shrink: 0; }
.header-icons { display: flex; align-items: center; gap: 2px; }
.count-badge { position: absolute; top: 3px; right: 1px; min-width: 18px; height: 18px; padding: 0 5px; border-radius: 9px; background: var(--accent); color: var(--on-accent); font-size: 11px; font-weight: 700; line-height: 18px; text-align: center; }
.header-signin { width: auto; gap: 8px; padding: 0 14px 0 10px; font-weight: 600; font-size: 15px; white-space: nowrap; color: var(--ink); }
@media (max-width: 560px) { .header-signin { width: 44px; padding: 0; } .header-signin-label { display: none; } }
.header-menu { display: none; margin-left: -10px; }
@media (max-width: 1240px) { .main-nav a:nth-child(n+6) { display: none; } }
@media (max-width: 1060px) {
  .main-nav, .header-search { display: none; }
  .header-menu { display: inline-flex; }
  .header-row { gap: 8px; }
  .brand { flex: 1; font-size: 20px; }
}
.drawer-scrim { position: fixed; inset: 0; z-index: var(--z-drawer); border: 0; padding: 0; background: var(--scrim); }
.drawer { position: fixed; z-index: calc(var(--z-drawer) + 1); top: 0; left: 0; bottom: 0; width: min(340px, 88vw); display: flex; flex-direction: column; gap: 20px; padding: 16px 20px 24px; background: var(--surface); transform: translateX(-100%); transition: transform 0.25s var(--ease); overflow-y: auto; visibility: hidden; }
.drawer.is-open { transform: translateX(0); visibility: visible; }
.drawer-head { display: flex; align-items: center; justify-content: space-between; }
.drawer-nav { display: flex; flex-direction: column; }
.drawer-nav a { padding: 14px 4px; color: var(--ink); text-decoration: none; font-size: 18px; font-weight: 500; }
.drawer-nav a.active { color: var(--accent); font-weight: 600; }
.drawer-foot { margin-top: auto; padding-top: 16px; border-top: 1px solid var(--line); display: flex; flex-direction: column; gap: 8px; align-items: flex-start; }
.drawer-foot a:not(.btn) { font-weight: 600; padding: 10px 0; color: var(--ink); }

.site-footer { background: var(--surface-2); color: var(--ink-2); margin-top: 24px; }
.footer-inner { max-width: var(--page); margin: 0 auto; padding: 64px var(--gutter) 40px; display: grid; grid-template-columns: minmax(0, 2fr) repeat(2, minmax(0, 1fr)); gap: 48px; }
.footer-brand { display: flex; flex-direction: column; gap: 10px; max-width: 360px; }
.footer-brand p { line-height: 1.6; }
.footer-col { display: flex; flex-direction: column; gap: 10px; font-size: 15px; }
.footer-col h2 { font-size: 15px; font-weight: 600; letter-spacing: 0; color: var(--ink); margin-bottom: 4px; }
.footer-col a { color: var(--ink-2); text-decoration: none; }
.footer-col a:hover { color: var(--accent); text-decoration: underline; }
.footer-base { max-width: var(--page); margin: 0 auto; padding: 20px var(--gutter) 32px; border-top: 1px solid var(--line); display: flex; justify-content: space-between; gap: 16px; flex-wrap: wrap; font-size: 14px; color: var(--muted); }
.footer-legal { display: flex; gap: 20px; }
.footer-legal a { color: var(--muted); }
@media (max-width: 760px) { .footer-inner { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 32px; } .footer-brand { grid-column: 1 / -1; } }

/* =========================================================
   Shared bits
   ========================================================= */
.price { display: inline-flex; flex-wrap: wrap; align-items: baseline; gap: 2px 10px; }
.price-now { font-weight: 600; color: var(--ink); font-variant-numeric: tabular-nums; }
.price-was { color: var(--muted); font-size: 14px; }
.price-off { font-size: 13px; font-weight: 600; color: var(--accent); }
.price-md .price-now { font-size: 17px; }
.price-lg .price-now { font-size: 30px; letter-spacing: -0.02em; }
.price-lg .price-was { font-size: 17px; }
.pill { display: inline-block; padding: 4px 10px; border-radius: var(--r-pill); font-size: 12px; font-weight: 600; white-space: nowrap; letter-spacing: 0; vertical-align: middle; }
.pill-pending, .pill-unpaid { background: var(--warn-bg); color: var(--warn); }
.pill-confirmed, .pill-processing, .pill-ready, .pill-dispatched { background: var(--info-bg); color: var(--info); }
.pill-delivered, .pill-paid, .pill-on { background: var(--ok-bg); color: var(--ok); }
.pill-cancelled, .pill-off, .pill-refunded { background: var(--tint); color: var(--muted); }
.crumbs ol { list-style: none; margin: 0 0 20px; padding: 0; display: flex; flex-wrap: wrap; gap: 6px; font-size: 14px; color: var(--muted); }
.crumbs li:not(:last-child)::after { content: "/"; margin-left: 6px; color: var(--line-2); }
.crumbs a { color: var(--muted); }
.crumbs a:hover { color: var(--accent); }
.pager { display: flex; justify-content: center; align-items: center; gap: 6px; margin-top: 48px; flex-wrap: wrap; }
.pager-group { display: inline-flex; align-items: center; gap: 6px; }
.pager-btn { min-width: 44px; height: 44px; padding: 0 10px; display: inline-flex; align-items: center; justify-content: center; border: 1px solid var(--line-2); border-radius: var(--r-pill); background: var(--surface); color: var(--ink); font-weight: 600; transition: border-color 0.2s var(--ease); }
.pager-btn:hover:not(:disabled) { border-color: var(--ink); }
.pager-btn.is-current { background: var(--accent); border-color: var(--accent); color: var(--on-accent); }
.pager-btn:disabled { opacity: 0.4; }
.pager-gap { color: var(--muted); }
.page-loading { display: flex; align-items: center; justify-content: center; gap: 12px; padding: 80px 16px; color: var(--muted); }
.spinner { width: 22px; height: 22px; border: 3px solid var(--tint); border-top-color: var(--accent); border-radius: 50%; animation: spin 0.8s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
.empty-state { display: flex; flex-direction: column; align-items: center; text-align: center; gap: 12px; padding: 64px 16px; }
.empty-state h2 { font-size: 26px; }
.empty-state p { color: var(--muted); max-width: 46ch; }
.empty-state .btn { margin-top: 8px; }
.empty-icon { width: 64px; height: 64px; border-radius: var(--r); background: var(--accent-soft); color: var(--accent); display: flex; align-items: center; justify-content: center; }
.empty-icon-error { background: var(--error-bg); color: var(--error); }
.empty-note { padding: 24px 0; color: var(--muted); text-align: center; }

.pimg { width: 100%; height: 100%; object-fit: cover; background: var(--tint); }
.pimg-empty { display: flex; align-items: center; justify-content: center; color: var(--muted); }

.toasts { position: fixed; z-index: var(--z-toast); left: 50%; bottom: 24px; transform: translateX(-50%); width: min(520px, calc(100vw - 32px)); display: flex; flex-direction: column; gap: 8px; pointer-events: none; }
.toast { pointer-events: auto; display: flex; align-items: center; gap: 12px; padding: 8px 8px 8px 16px; border-radius: var(--r); background: var(--ink); color: var(--bg); box-shadow: var(--shadow); font-size: 15px; animation: toast-in 0.2s var(--ease); }
.toast-error { background: var(--error); color: var(--bg); }
.toast-text { flex: 1; }
.toast-link { color: var(--bg) !important; font-weight: 700; white-space: nowrap; text-decoration: underline; }
.toast .icon-btn { color: var(--bg); }
.toast .icon-btn:hover { background: color-mix(in srgb, var(--bg) 16%, transparent); color: var(--bg); }
@keyframes toast-in { from { opacity: 0; transform: translateY(8px); } }

.modal { width: min(520px, calc(100vw - 32px)); max-height: calc(100dvh - 32px); padding: 0; border: 0; border-radius: var(--r-lg); background: var(--surface); color: var(--ink); box-shadow: var(--shadow); }
.modal-wide { width: min(760px, calc(100vw - 32px)); }
.modal::backdrop { background: var(--scrim); }
.modal-inner { display: flex; flex-direction: column; max-height: calc(100dvh - 32px); }
.modal-head { display: flex; align-items: center; justify-content: space-between; gap: 12px; padding: 20px 20px 12px 24px; }
.modal-head h2 { font-size: 24px; }
.modal-body { padding: 4px 24px 24px; overflow-y: auto; }
.modal-text { color: var(--ink-2); line-height: 1.6; }
.modal-foot { display: flex; justify-content: flex-end; gap: 10px; padding: 16px 24px 20px; border-top: 1px solid var(--line); flex-wrap: wrap; }

/* =========================================================
   Product card (no box: photo, then text)
   ========================================================= */
.pgrid { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 40px 24px; }
@media (max-width: 1100px) { .pgrid { grid-template-columns: repeat(3, minmax(0, 1fr)); } }
@media (max-width: 760px) { .pgrid { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 28px 12px; } }
.pcard { display: flex; flex-direction: column; gap: 12px; min-width: 0; flex: 1; }
.pgrid > .reveal, .rail > .reveal { display: flex; flex-direction: column; }
.pcard-media { position: relative; aspect-ratio: 4 / 5; border-radius: var(--r); overflow: hidden; background: var(--tint); }
.pcard-link { display: block; width: 100%; height: 100%; }
.pcard-media .pimg { transition: transform 0.5s var(--ease); }
.pcard:hover .pcard-media img.pimg { transform: scale(1.04); }
.pcard.is-soldout .pcard-media .pimg { opacity: 0.5; }
.pcard-wish { position: absolute; top: 10px; right: 10px; width: 44px; height: 44px; border: 0; border-radius: 50%; background: color-mix(in srgb, var(--surface) 92%, transparent); color: var(--ink); display: flex; align-items: center; justify-content: center; box-shadow: var(--shadow-sm); transition: transform 0.12s var(--ease), color 0.2s var(--ease); }
.pcard-wish:hover { color: var(--accent); }
.pcard-wish:active { transform: scale(0.92); }
.pcard-wish.is-on { color: var(--accent); }
.pcard-body { display: flex; flex-direction: column; gap: 4px; }
.pcard-meta { display: flex; gap: 10px; font-size: 13px; color: var(--muted); }
.pcard-new { color: var(--accent); font-weight: 600; }
.pcard-name { font-size: 16px; font-weight: 500; letter-spacing: -0.01em; line-height: 1.3; }
.pcard-name a { color: var(--ink); text-decoration: none; }
.pcard-name a:hover { color: var(--accent); text-decoration: underline; }
.pcard-actions { display: flex; gap: 8px; margin-top: auto; }
.pcard-add { flex: 1; min-width: 0; }
.pcard-try { width: 44px; padding: 0; flex-shrink: 0; }
@media (max-width: 760px) {
  .pcard-name { font-size: 14px; }
  .pcard .btn-sm { padding: 0 10px; font-size: 13px; }
  .price-md .price-now { font-size: 15px; }
}
.skeleton { background: linear-gradient(90deg, var(--tint) 0%, var(--tint-2) 50%, var(--tint) 100%); background-size: 200% 100%; animation: shimmer 1.2s infinite; border-radius: var(--r); }
.skeleton-card { aspect-ratio: 4 / 6.2; }
@keyframes shimmer { to { background-position: -200% 0; } }

/* Horizontal rail (categories, offers) */
.rail { display: grid; grid-auto-flow: column; grid-auto-columns: minmax(180px, calc((100% - 5 * 20px) / 6)); gap: 20px; overflow-x: auto; scroll-snap-type: x mandatory; padding-bottom: 8px; scrollbar-width: thin; }
.rail > * { scroll-snap-align: start; }
.rail-products { grid-auto-columns: minmax(220px, calc((100% - 3 * 24px) / 4)); gap: 24px; }
@media (max-width: 760px) {
  .rail { grid-auto-columns: 42%; gap: 12px; margin: 0 calc(-1 * var(--gutter)); padding: 0 var(--gutter) 8px; scroll-padding-inline: var(--gutter); }
  .rail-products { grid-auto-columns: 62%; }
}

/* =========================================================
   Home
   ========================================================= */
.hero { max-width: var(--page); margin: 0 auto; padding: 40px var(--gutter) 24px; display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 56px; align-items: center; min-height: min(calc(100dvh - var(--header-h)), 780px); }
.hero-copy { display: flex; flex-direction: column; gap: 22px; align-items: flex-start; }
.hero h1 { font-size: clamp(40px, 4.8vw, 66px); letter-spacing: -0.04em; line-height: 1.04; max-width: 14ch; }
.hero p { font-size: 19px; line-height: 1.55; color: var(--ink-2); max-width: 34ch; }
.hero-actions { display: flex; gap: 12px; flex-wrap: wrap; margin-top: 6px; }
.hero-media { position: relative; aspect-ratio: 4 / 5; max-height: calc(100dvh - var(--header-h) - 64px); justify-self: end; width: 100%; border-radius: var(--r-lg); overflow: hidden; background: var(--tint); }
.hero-media img { width: 100%; height: 100%; object-fit: cover; }
.hero-media-empty { display: flex; align-items: center; justify-content: center; color: var(--muted); }
@media (max-width: 900px) {
  .hero { grid-template-columns: 1fr; gap: 28px; min-height: 0; padding-top: 24px; }
  .hero-media { justify-self: stretch; aspect-ratio: 4 / 4.2; max-height: none; }
  .hero h1 { max-width: 14ch; }
}
@media (max-width: 560px) { .hero-actions .btn { flex: 1 1 100%; } }
.home-section { max-width: var(--page); margin: 0 auto; padding: 88px var(--gutter) 0; }
@media (max-width: 640px) { .home-section { padding-top: 64px; } }

.cat-card { display: flex; flex-direction: column; gap: 10px; text-decoration: none; color: var(--ink); }
.cat-card-img { aspect-ratio: 3 / 4; border-radius: var(--r); overflow: hidden; background: var(--tint); display: flex; align-items: center; justify-content: center; }
.cat-card-img img { width: 100%; height: 100%; object-fit: cover; transition: transform 0.5s var(--ease); }
.cat-card:hover .cat-card-img img { transform: scale(1.05); }
.cat-card-letter { font-size: 56px; font-weight: 600; letter-spacing: -0.04em; color: var(--accent); }
.cat-card-name { font-size: 15px; font-weight: 500; }
.cat-card:hover .cat-card-name { color: var(--accent); }

.look-bento { display: grid; grid-template-columns: repeat(12, minmax(0, 1fr)); grid-template-rows: auto auto; gap: 16px; }
.look-copy { grid-column: span 5; display: flex; flex-direction: column; gap: 16px; align-items: flex-start; justify-content: center; padding: 40px; border-radius: var(--r-lg); background: var(--accent-soft); }
.look-copy h2 { font-size: clamp(30px, 3.6vw, 44px); }
.look-copy p { font-size: 17px; color: var(--ink-2); max-width: 36ch; }
.look-photo { grid-column: span 7; grid-row: span 2; border-radius: var(--r-lg); overflow: hidden; background: var(--tint); min-height: 420px; }
.look-photo img { width: 100%; height: 100%; object-fit: cover; }
.look-pieces { grid-column: span 5; display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 12px; }
.look-piece { display: flex; flex-direction: column; gap: 8px; text-decoration: none; color: var(--ink); }
.look-piece-img { aspect-ratio: 1; border-radius: var(--r); overflow: hidden; background: var(--tint); }
.look-piece-img img { width: 100%; height: 100%; object-fit: cover; transition: transform 0.5s var(--ease); }
.look-piece:hover .look-piece-img img { transform: scale(1.05); }
.look-piece span { font-size: 14px; font-weight: 500; line-height: 1.3; }
@media (max-width: 900px) {
  .look-bento { grid-template-columns: 1fr; }
  .look-copy, .look-photo, .look-pieces { grid-column: auto; grid-row: auto; }
  .look-copy { padding: 28px 24px; }
  .look-photo { min-height: 0; aspect-ratio: 4 / 3; }
}

.services { max-width: var(--page); margin: 0 auto; padding: 88px var(--gutter) 88px; display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); }
.service { display: flex; gap: 12px; align-items: flex-start; padding: 4px 24px; border-left: 1px solid var(--line); }
.service:first-child { padding-left: 0; border-left: 0; }
.service svg { flex-shrink: 0; color: var(--accent); margin-top: 2px; }
.service strong { display: block; font-size: 15px; font-weight: 600; }
.service span { font-size: 14px; color: var(--muted); line-height: 1.5; }
@media (max-width: 900px) {
  .services { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 24px 0; padding: 64px var(--gutter); }
  .service:nth-child(3) { padding-left: 0; border-left: 0; }
}
@media (max-width: 480px) { .services { grid-template-columns: 1fr; } .service { padding-left: 0; border-left: 0; } }

/* =========================================================
   Shop
   ========================================================= */
.shop { display: grid; grid-template-columns: 240px minmax(0, 1fr); gap: 48px; align-items: start; }
.shop-head { display: flex; flex-direction: column; gap: 6px; margin-bottom: 28px; }
.shop-head h1 { font-size: clamp(32px, 4.6vw, 48px); }
.shop-toolbar { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-bottom: 24px; flex-wrap: wrap; }
.shop-count { color: var(--muted); font-size: 15px; }
.shop-toolbar-right { display: flex; gap: 10px; align-items: center; }
.sort select { min-height: 44px; padding: 0 36px 0 16px; border: 1px solid var(--line-2); border-radius: var(--r-pill); background: var(--surface); color: var(--ink); font-size: 14px; font-weight: 500; }
.filters-toggle { display: none; }
.filters { position: sticky; top: calc(var(--header-h) + 24px); display: flex; flex-direction: column; gap: 28px; }
.filters-head { display: none; }
.filter-group { display: flex; flex-direction: column; gap: 10px; }
.filter-group h2 { font-size: 14px; font-weight: 600; letter-spacing: 0; }
.filter-list { display: flex; flex-direction: column; gap: 2px; }
.filter-link { display: flex; justify-content: space-between; gap: 8px; padding: 8px 12px; border-radius: var(--r-sm); color: var(--ink-2); text-decoration: none; font-size: 15px; transition: background-color 0.2s var(--ease); }
.filter-link:hover { background: var(--tint); color: var(--ink); }
.filter-link.is-on { background: var(--accent-soft); color: var(--accent); font-weight: 600; }
.filter-link .muted { font-size: 13px; font-variant-numeric: tabular-nums; }
.price-inputs { display: grid; grid-template-columns: 1fr auto 1fr; align-items: center; gap: 8px; }
.price-inputs input { width: 100%; min-height: 44px; padding: 0 10px; border: 1px solid var(--line-2); border-radius: var(--r-sm); background: var(--surface); color: var(--ink); font-size: 15px; }
.chips { display: flex; flex-wrap: wrap; gap: 8px; }
.chip { min-height: 36px; padding: 0 14px; border: 1px solid var(--line-2); border-radius: var(--r-pill); background: var(--surface); color: var(--ink); font-size: 14px; font-weight: 500; display: inline-flex; align-items: center; gap: 6px; transition: border-color 0.2s var(--ease), background-color 0.2s var(--ease); }
.chip:hover { border-color: var(--ink-2); }
.chip[aria-pressed="true"] { background: var(--accent); border-color: var(--accent); color: var(--on-accent); }
.check { display: flex; align-items: center; gap: 10px; min-height: 44px; cursor: pointer; font-size: 15px; }
.check input { width: 20px; height: 20px; accent-color: var(--accent); }
.active-filters { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; margin-bottom: 24px; }
@media (max-width: 900px) {
  .shop { grid-template-columns: 1fr; }
  .filters-toggle { display: inline-flex; }
  .filters { position: fixed; z-index: calc(var(--z-drawer) + 1); inset: auto 0 0 0; top: auto; max-height: 85dvh; overflow-y: auto; padding: 20px var(--gutter) 24px; background: var(--surface); border-radius: var(--r-lg) var(--r-lg) 0 0; box-shadow: var(--shadow); transform: translateY(100%); transition: transform 0.25s var(--ease); visibility: hidden; }
  .filters.is-open { transform: translateY(0); visibility: visible; }
  .filters-head { display: flex; align-items: center; justify-content: space-between; }
  .filters-head h2 { font-size: 24px; }
}

/* =========================================================
   Product details
   ========================================================= */
.pdp { display: grid; grid-template-columns: minmax(0, 1.1fr) minmax(0, 1fr); gap: 64px; align-items: start; }
.gallery { display: flex; flex-direction: column; gap: 12px; position: sticky; top: calc(var(--header-h) + 24px); }
.gallery-main { position: relative; aspect-ratio: 1; border-radius: var(--r-lg); overflow: hidden; background: var(--tint); }
.gallery-nav { position: absolute; top: 50%; transform: translateY(-50%); background: var(--surface) !important; box-shadow: var(--shadow-sm); }
.gallery-prev { left: 12px; }
.gallery-next { right: 12px; }
.thumbs { display: flex; gap: 10px; overflow-x: auto; padding: 2px; }
.thumb { width: 76px; height: 76px; flex-shrink: 0; padding: 0; border: 2px solid transparent; border-radius: var(--r-sm); overflow: hidden; background: var(--tint); transition: border-color 0.2s var(--ease); }
.thumb[aria-current="true"] { border-color: var(--accent); }
.pdp-info { display: flex; flex-direction: column; gap: 20px; }
.pdp-info h1 { font-size: clamp(30px, 4vw, 46px); letter-spacing: -0.035em; }
.pdp-meta { display: flex; flex-wrap: wrap; gap: 8px 16px; align-items: center; font-size: 14px; color: var(--muted); }
.stock { display: inline-flex; align-items: center; gap: 6px; font-weight: 600; font-size: 14px; }
.stock-in { color: var(--ok); }
.stock-low { color: var(--warn); }
.stock-out { color: var(--error); }
.pdp-offer { font-weight: 600; font-size: 15px; color: var(--accent); }
.pdp-desc { color: var(--ink-2); line-height: 1.7; white-space: pre-line; max-width: 60ch; }
.pdp-buy { display: flex; flex-direction: column; gap: 14px; padding: 20px 0; border-top: 1px solid var(--line); border-bottom: 1px solid var(--line); }
.pdp-buy-row { display: flex; gap: 12px; align-items: center; flex-wrap: wrap; }
.pdp-buy-row .btn-primary { flex: 1; min-width: 180px; }
.try-cta { display: flex; gap: 16px; align-items: center; padding: 16px 18px; border-radius: var(--r); background: var(--accent-soft); color: var(--ink); text-decoration: none; transition: background-color 0.2s var(--ease); }
.try-cta:hover { background: color-mix(in srgb, var(--accent-soft) 80%, var(--accent)); color: var(--ink); }
.try-cta-icon { width: 44px; height: 44px; flex-shrink: 0; border-radius: var(--r-sm); background: var(--accent); color: var(--on-accent); display: flex; align-items: center; justify-content: center; }
.try-cta strong { display: block; font-size: 16px; font-weight: 600; }
.try-cta span { font-size: 14px; color: var(--ink-2); }
.try-cta .try-cta-icon { color: var(--on-accent); }
.try-cta > svg:last-child { margin-left: auto; flex-shrink: 0; }
.pdp-actions { display: flex; gap: 8px; flex-wrap: wrap; }
.pdp-details { display: grid; grid-template-columns: auto 1fr; gap: 8px 24px; font-size: 15px; }
.pdp-details dt { color: var(--muted); }
.pdp-details dd { margin: 0; font-weight: 500; }
.related { margin-top: 96px; }
@media (max-width: 900px) { .pdp { grid-template-columns: 1fr; gap: 28px; } .gallery { position: static; } }

/* =========================================================
   Try-on
   ========================================================= */
.tryon { display: grid; grid-template-columns: minmax(0, 1fr) 320px; gap: 40px; align-items: start; }
.stepper { display: flex; gap: 8px; list-style: none; margin: 0 0 28px; padding: 0; flex-wrap: wrap; }
.stepper li { display: flex; align-items: center; gap: 8px; font-size: 14px; font-weight: 500; color: var(--muted); }
.stepper li:not(:last-child)::after { content: ""; width: 28px; height: 1px; background: var(--line-2); margin-left: 4px; }
.step-dot { width: 28px; height: 28px; border-radius: 50%; border: 1.5px solid var(--line-2); display: flex; align-items: center; justify-content: center; font-size: 13px; font-variant-numeric: tabular-nums; }
.stepper li.is-current { color: var(--ink); font-weight: 600; }
.stepper li.is-current .step-dot { background: var(--accent); border-color: var(--accent); color: var(--on-accent); }
.stepper li.is-done .step-dot { background: var(--accent-soft); border-color: var(--accent-soft); color: var(--accent); }
.method-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px; }
.method { display: flex; flex-direction: column; align-items: flex-start; gap: 12px; padding: 28px; border: 1.5px solid var(--line); border-radius: var(--r-lg); background: var(--surface); color: var(--ink); text-align: left; transition: border-color 0.2s var(--ease), transform 0.12s var(--ease); }
.method:hover { border-color: var(--accent); }
.method:active { transform: scale(0.99); }
.method-icon { width: 52px; height: 52px; border-radius: var(--r-sm); background: var(--accent-soft); color: var(--accent); display: flex; align-items: center; justify-content: center; }
.method strong { font-size: 20px; font-weight: 600; letter-spacing: -0.02em; }
.method span { color: var(--muted); font-size: 15px; line-height: 1.5; }
@media (max-width: 640px) { .method-grid { grid-template-columns: 1fr; } .method { padding: 20px; } }
.model-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 14px; }
.model-card { position: relative; padding: 0; border: 3px solid transparent; border-radius: var(--r); overflow: hidden; background: var(--tint); aspect-ratio: 3 / 4; transition: border-color 0.2s var(--ease); }
.model-card img { width: 100%; height: 100%; object-fit: cover; }
.model-card[aria-pressed="true"] { border-color: var(--accent); }
.model-card-check { position: absolute; top: 8px; right: 8px; width: 28px; height: 28px; border-radius: 50%; background: var(--accent); color: var(--on-accent); display: none; align-items: center; justify-content: center; }
.model-card[aria-pressed="true"] .model-card-check { display: flex; }
.model-card-name { display: block; padding-top: 6px; font-size: 13px; font-weight: 500; color: var(--ink-2); text-align: left; }
.model-pick { display: flex; flex-direction: column; }
.dropzone { display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 10px; min-height: 260px; padding: 24px; border: 2px dashed var(--line-2); border-radius: var(--r-lg); background: var(--surface); text-align: center; cursor: pointer; transition: border-color 0.2s var(--ease), background-color 0.2s var(--ease); }
.dropzone:hover, .dropzone.is-over { border-color: var(--accent); background: var(--accent-soft); }
.dropzone:focus-within { outline: 2px solid var(--accent); outline-offset: 2px; }
.dropzone strong { font-size: 17px; }
.dropzone span { color: var(--muted); font-size: 14px; }
.dropzone-icon { width: 52px; height: 52px; border-radius: var(--r-sm); background: var(--accent-soft); color: var(--accent); display: flex; align-items: center; justify-content: center; }
.photo-preview { display: grid; grid-template-columns: 200px 1fr; gap: 20px; align-items: start; }
.photo-preview img { width: 200px; aspect-ratio: 3 / 4; object-fit: cover; border-radius: var(--r); }
.tips { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 10px; }
.tips li { display: flex; gap: 10px; align-items: center; font-size: 15px; }
.tips svg { color: var(--ok); flex-shrink: 0; }
@media (max-width: 560px) { .photo-preview { grid-template-columns: 1fr; } .photo-preview img { width: 100%; max-width: 260px; } }
.tryon-actions { display: flex; gap: 12px; margin-top: 28px; flex-wrap: wrap; }
.tryon-side { position: sticky; top: calc(var(--header-h) + 24px); display: flex; flex-direction: column; gap: 14px; padding: 20px; border-radius: var(--r-lg); background: var(--surface); }
.tryon-side h2 { font-size: 15px; font-weight: 600; letter-spacing: 0; }
.mini-item { display: flex; gap: 12px; align-items: center; }
.mini-item-img { width: 56px; height: 56px; flex-shrink: 0; border-radius: var(--r-sm); overflow: hidden; }
.mini-item-name { font-weight: 500; font-size: 14px; line-height: 1.3; color: var(--ink); }
.mini-item .price-now { font-size: 14px; }
.generating { display: flex; flex-direction: column; align-items: center; gap: 20px; padding: 64px 16px; text-align: center; }
.generating-art { position: relative; width: 112px; height: 112px; border-radius: 50%; background: var(--accent-soft); color: var(--accent); display: flex; align-items: center; justify-content: center; }
.generating-art::after { content: ""; position: absolute; inset: -6px; border-radius: 50%; border: 3px solid transparent; border-top-color: var(--accent); animation: spin 1.2s linear infinite; }
.generating h2 { font-size: 28px; }
.generating p { color: var(--muted); }
.result { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 32px; align-items: start; }
.result-img { border-radius: var(--r-lg); overflow: hidden; background: var(--tint); aspect-ratio: 3 / 4; }
.result-img img { width: 100%; height: 100%; object-fit: cover; }
.result-info { display: flex; flex-direction: column; gap: 18px; }
.result-info h2 { font-size: 34px; }
.result-note { font-size: 13px; color: var(--muted); }
@media (max-width: 900px) { .tryon { grid-template-columns: 1fr; } .tryon-side { position: static; order: -1; } .result { grid-template-columns: 1fr; } }

/* =========================================================
   Create your look
   ========================================================= */
.look { display: grid; grid-template-columns: minmax(0, 1fr) 320px; gap: 40px; align-items: start; }
.look-options { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 24px 16px; }
.look-option { position: relative; display: flex; flex-direction: column; gap: 10px; padding: 0; border: 0; background: none; color: var(--ink); text-align: left; }
.look-option-img { aspect-ratio: 1; border-radius: var(--r); overflow: hidden; outline: 3px solid transparent; outline-offset: -3px; transition: outline-color 0.2s var(--ease); }
.look-option:hover .look-option-img { outline-color: var(--line-2); }
.look-option[aria-pressed="true"] .look-option-img { outline-color: var(--accent); }
.look-option-name { font-weight: 500; font-size: 14px; line-height: 1.3; }
.look-option .price-now { font-size: 15px; }
.look-option-check { position: absolute; top: 10px; right: 10px; width: 30px; height: 30px; border-radius: 50%; background: var(--accent); color: var(--on-accent); display: none; align-items: center; justify-content: center; }
.look-option[aria-pressed="true"] .look-option-check { display: flex; }
.look-tray { position: sticky; top: calc(var(--header-h) + 24px); display: flex; flex-direction: column; gap: 14px; padding: 20px; border-radius: var(--r-lg); background: var(--surface); }
.look-tray h2 { font-size: 22px; }
.tray-slot { display: flex; gap: 12px; align-items: center; min-height: 56px; }
.tray-slot-img { width: 56px; height: 56px; flex-shrink: 0; border-radius: var(--r-sm); overflow: hidden; background: var(--tint); color: var(--muted); display: flex; align-items: center; justify-content: center; }
.tray-slot-empty .tray-slot-img { border: 1.5px dashed var(--line-2); background: transparent; }
.tray-slot-text { display: flex; flex-direction: column; min-width: 0; font-size: 14px; }
.tray-slot-text strong { font-weight: 500; line-height: 1.3; }
.tray-total { display: flex; justify-content: space-between; padding-top: 14px; border-top: 1px solid var(--line); font-weight: 600; font-size: 17px; }
.look-nav { display: flex; gap: 12px; margin-top: 32px; justify-content: space-between; flex-wrap: wrap; }
@media (max-width: 900px) { .look { grid-template-columns: 1fr; } .look-tray { position: static; } }

/* =========================================================
   Cart & checkout
   ========================================================= */
.cart { display: grid; grid-template-columns: minmax(0, 1fr) 380px; gap: 40px; align-items: start; }
.cart-lines { display: flex; flex-direction: column; background: var(--surface); border-radius: var(--r-lg); padding: 8px 24px; }
.cart-line { display: grid; grid-template-columns: 96px minmax(0, 1fr) auto; gap: 20px; padding: 20px 0; align-items: center; }
.cart-line + .cart-line { border-top: 1px solid var(--line); }
.cart-line-img { width: 96px; height: 96px; border-radius: var(--r-sm); overflow: hidden; }
.cart-line-info { display: flex; flex-direction: column; gap: 6px; min-width: 0; }
.cart-line-name { font-weight: 500; color: var(--ink); text-decoration: none; }
.cart-line-name:hover { text-decoration: underline; color: var(--accent); }
.cart-line-controls { display: flex; gap: 12px; align-items: center; margin-top: 4px; flex-wrap: wrap; }
.cart-line-total { font-weight: 600; font-size: 17px; text-align: right; font-variant-numeric: tabular-nums; }
.cart-line-warn { font-size: 13px; color: var(--error); font-weight: 600; }
@media (max-width: 560px) {
  .cart-lines { padding: 4px 16px; }
  .cart-line { grid-template-columns: 72px minmax(0, 1fr); gap: 14px; }
  .cart-line-img { width: 72px; height: 72px; }
  .cart-line-total { grid-column: 2; text-align: left; }
}
.summary { position: sticky; top: calc(var(--header-h) + 24px); display: flex; flex-direction: column; gap: 14px; padding: 24px; border-radius: var(--r-lg); background: var(--surface); }
.summary h2 { font-size: 24px; }
.summary-row { display: flex; justify-content: space-between; gap: 12px; font-size: 15px; }
.summary-row span:last-child { font-variant-numeric: tabular-nums; }
.summary-total { padding-top: 14px; border-top: 1px solid var(--line); font-size: 19px; font-weight: 600; }
.summary-note { font-size: 13px; color: var(--muted); }
.free-bar { display: flex; flex-direction: column; gap: 6px; font-size: 13px; color: var(--ink-2); }
.free-bar-track { height: 4px; border-radius: 2px; background: var(--tint); overflow: hidden; }
.free-bar-fill { display: block; height: 100%; border-radius: 2px; background: var(--accent); }
.summary-items { display: flex; flex-direction: column; gap: 12px; max-height: 320px; overflow-y: auto; padding: 8px 8px 4px 0; margin-top: -8px; }
.summary-item { display: grid; grid-template-columns: 52px minmax(0, 1fr) auto; gap: 12px; align-items: center; font-size: 14px; }
.summary-item-img { position: relative; width: 52px; height: 52px; }
.summary-item-img .pimg { border-radius: 10px; }
.summary-item-qty { position: absolute; top: -6px; right: -6px; min-width: 20px; height: 20px; padding: 0 5px; border-radius: 10px; background: var(--ink); color: var(--bg); font-size: 11px; font-weight: 700; line-height: 20px; text-align: center; }
@media (max-width: 960px) { .cart { grid-template-columns: 1fr; } .summary { position: static; } }
.checkout-section { display: flex; flex-direction: column; gap: 18px; padding: 28px; border-radius: var(--r-lg); background: var(--surface); }
.checkout-section h2 { display: flex; align-items: center; gap: 12px; font-size: 22px; }
.checkout-num { width: 30px; height: 30px; border-radius: 50%; background: var(--accent-soft); color: var(--accent); font-size: 14px; font-weight: 700; display: flex; align-items: center; justify-content: center; letter-spacing: 0; }
.checkout-sections { display: flex; flex-direction: column; gap: 20px; }
.bank-box { padding: 16px; border-radius: var(--r-sm); background: var(--tint-2); border: 1px solid var(--line); font-size: 14px; line-height: 1.6; white-space: pre-line; }
@media (max-width: 560px) { .checkout-section { padding: 20px 16px; } }

/* =========================================================
   Order confirmation & tracking
   ========================================================= */
.confirm { max-width: 720px; margin: 0 auto; display: flex; flex-direction: column; gap: 24px; }
.confirm-hero { display: flex; flex-direction: column; align-items: center; text-align: center; gap: 14px; padding: 40px 24px; border-radius: var(--r-lg); background: var(--surface); }
.confirm-icon { width: 68px; height: 68px; border-radius: 50%; background: var(--ok-bg); color: var(--ok); display: flex; align-items: center; justify-content: center; }
.confirm-hero h1 { font-size: clamp(30px, 4.6vw, 42px); }
.order-no { font-size: 15px; color: var(--muted); }
.order-no strong { display: block; margin-top: 4px; font-size: 28px; font-weight: 600; color: var(--ink); letter-spacing: 0.01em; font-variant-numeric: tabular-nums; }
.card { padding: 24px; border-radius: var(--r-lg); background: var(--surface); }
.card h2 { font-size: 22px; margin-bottom: 16px; }
.card-actions { display: flex; gap: 12px; flex-wrap: wrap; justify-content: center; }
.timeline { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; }
.tl-step { position: relative; display: grid; grid-template-columns: 32px 1fr; gap: 14px; padding-bottom: 22px; }
.tl-step:last-child { padding-bottom: 0; }
.tl-step:not(:last-child)::before { content: ""; position: absolute; left: 15px; top: 30px; bottom: 0; width: 2px; background: var(--line); }
.tl-step.is-done:not(:last-child)::before { background: var(--accent); }
.tl-dot { width: 32px; height: 32px; border-radius: 50%; border: 2px solid var(--line-2); background: var(--surface); display: flex; align-items: center; justify-content: center; color: var(--on-accent); z-index: 1; }
.tl-step.is-done .tl-dot { background: var(--accent); border-color: var(--accent); }
.tl-step.is-current .tl-dot { border-color: var(--accent); box-shadow: 0 0 0 4px var(--accent-soft); }
.tl-step.is-current .tl-dot::after { content: ""; width: 12px; height: 12px; border-radius: 50%; background: var(--accent); }
.tl-text { display: flex; flex-direction: column; padding-top: 4px; }
.tl-text strong { font-size: 16px; font-weight: 600; }
.tl-step:not(.is-done):not(.is-current) .tl-text strong { color: var(--muted); font-weight: 500; }
.tl-text span { font-size: 13px; color: var(--muted); }
.track-grid { display: grid; grid-template-columns: 360px minmax(0, 1fr); gap: 32px; align-items: start; }
@media (max-width: 860px) { .track-grid { grid-template-columns: 1fr; } }
.order-lines { display: flex; flex-direction: column; gap: 12px; }
.order-line { display: grid; grid-template-columns: 52px minmax(0, 1fr) auto; gap: 12px; align-items: center; font-size: 15px; }
.order-line-img { width: 52px; height: 52px; border-radius: 10px; overflow: hidden; }
.order-totals { display: flex; flex-direction: column; gap: 8px; margin-top: 16px; padding-top: 16px; border-top: 1px solid var(--line); }

/* =========================================================
   Account
   ========================================================= */
.account { display: grid; grid-template-columns: 240px minmax(0, 1fr); gap: 40px; align-items: start; }
.account-nav { display: flex; flex-direction: column; gap: 4px; position: sticky; top: calc(var(--header-h) + 24px); }
.account-nav a, .account-nav button { display: flex; align-items: center; gap: 12px; min-height: 48px; padding: 0 14px; border: 0; border-radius: var(--r-sm); background: none; color: var(--ink-2); text-decoration: none; font-weight: 500; font-size: 15px; text-align: left; transition: background-color 0.2s var(--ease); }
.account-nav a:hover, .account-nav button:hover { background: var(--tint); color: var(--ink); }
.account-nav a.active { background: var(--accent-soft); color: var(--accent); font-weight: 600; }
@media (max-width: 860px) {
  .account { grid-template-columns: 1fr; gap: 20px; }
  .account-nav { position: static; flex-direction: row; overflow-x: auto; gap: 6px; margin: 0 calc(-1 * var(--gutter)); padding: 0 var(--gutter) 4px; }
  .account-nav a, .account-nav button { flex-shrink: 0; min-height: 44px; border: 1px solid var(--line-2); border-radius: var(--r-pill); white-space: nowrap; }
  .account-nav a.active { border-color: var(--accent); }
}
.order-card { display: flex; flex-direction: column; gap: 16px; padding: 20px 24px; border-radius: var(--r-lg); background: var(--surface); }
.order-card-head { display: flex; justify-content: space-between; align-items: flex-start; gap: 12px; flex-wrap: wrap; }
.order-card-head strong { font-size: 17px; font-weight: 600; }
.order-card-thumbs { display: flex; gap: 8px; }
.order-card-thumbs .order-line-img { width: 56px; height: 56px; }
.order-card-foot { display: flex; justify-content: space-between; align-items: center; gap: 12px; flex-wrap: wrap; }
.order-card-detail { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 32px; }
@media (max-width: 640px) { .order-card-detail { grid-template-columns: 1fr; } }
.stack { display: flex; flex-direction: column; gap: 16px; }
.tryon-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 24px 16px; }
.tryon-card { display: flex; flex-direction: column; gap: 10px; }
.tryon-card img { aspect-ratio: 3 / 4; object-fit: cover; border-radius: var(--r); }
.tryon-card-body { display: flex; flex-direction: column; gap: 4px; font-size: 14px; }

/* =========================================================
   Info pages
   ========================================================= */
.prose { display: flex; flex-direction: column; gap: 16px; font-size: 17px; line-height: 1.7; color: var(--ink-2); max-width: 65ch; }
.prose h2 { font-size: 26px; color: var(--ink); margin-top: 20px; }
.faq-list { display: grid; gap: 40px; margin: 0; }
.faq-item { display: grid; grid-template-columns: minmax(0, 5fr) minmax(0, 7fr); gap: 32px; scroll-margin-top: calc(var(--header-h) + 24px); }
.faq-item dt { font-size: 19px; font-weight: 600; letter-spacing: -0.015em; line-height: 1.35; }
.faq-item dd { margin: 0; color: var(--ink-2); line-height: 1.7; max-width: 60ch; }
.faq-item:target dt { color: var(--accent); }
@media (max-width: 720px) { .faq-item { grid-template-columns: 1fr; gap: 8px; } }
.contact-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 16px; }
.contact-card { display: flex; flex-direction: column; gap: 8px; padding: 24px; border-radius: var(--r-lg); background: var(--surface); color: var(--ink); text-decoration: none; transition: box-shadow 0.2s var(--ease); }
a.contact-card:hover { color: var(--ink); box-shadow: 0 0 0 1.5px var(--accent); }
.contact-card-icon { color: var(--accent); margin-bottom: 4px; }
.contact-card strong { font-size: 17px; font-weight: 600; }
.contact-card span { color: var(--muted); font-size: 15px; word-break: break-word; }
.not-found { display: flex; flex-direction: column; align-items: center; text-align: center; gap: 16px; padding: 96px var(--gutter); }
.not-found h1 { font-size: clamp(40px, 6vw, 64px); }
.not-found p { color: var(--muted); max-width: 46ch; }
.not-found-art { color: var(--accent); }

/* =========================================================
   Auth pages
   ========================================================= */
.auth { min-height: 100dvh; display: grid; grid-template-columns: minmax(0, 5fr) minmax(0, 6fr); background: var(--bg); }
.auth-aside { position: relative; display: flex; flex-direction: column; justify-content: space-between; gap: 32px; padding: 32px; margin: 16px 0 16px 16px; border-radius: var(--r-lg); background: var(--surface-2); overflow: hidden; }
.auth-photo { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; }
.auth-aside.has-photo::after { content: ""; position: absolute; inset: 0; background: linear-gradient(180deg, rgba(8, 16, 13, 0.35) 0%, rgba(8, 16, 13, 0) 30%, rgba(8, 16, 13, 0) 45%, rgba(8, 16, 13, 0.78) 100%); }
.auth-aside > :not(.auth-photo) { position: relative; z-index: 1; }
.auth-logo { font-size: 22px; font-weight: 700; letter-spacing: -0.03em; color: var(--ink) !important; text-decoration: none; }
.auth-aside-body { max-width: 420px; color: var(--ink-2); }
.auth-aside-body h2 { margin: 0 0 12px; font-size: 40px; letter-spacing: -0.035em; color: var(--ink); }
.auth-aside-body p { font-size: 17px; line-height: 1.6; }
.auth-aside.has-photo .auth-logo, .auth-aside.has-photo .auth-aside-body h2 { color: #f4f7f5 !important; }
.auth-aside.has-photo .auth-aside-body { color: #dfe7e3; }
.auth-main { padding: 48px 24px; display: flex; align-items: center; justify-content: center; }
.auth-card { width: 100%; max-width: 420px; }
.auth-card h1 { margin: 0 0 8px; font-size: 38px; letter-spacing: -0.035em; }
.auth-sub { margin: 0 0 32px; color: var(--muted); line-height: 1.5; }
.auth-switch { margin: 20px 0 0; text-align: center; font-size: 15px; color: var(--muted); }
.auth-switch a { font-weight: 600; }
@media (max-width: 860px) {
  .auth { grid-template-columns: 1fr; }
  .auth-aside { margin: 0; border-radius: 0; padding: 16px 24px; background: transparent; border-bottom: 1px solid var(--line); }
  .auth-aside.has-photo::after, .auth-photo, .auth-aside-body { display: none; }
  .auth-aside.has-photo .auth-logo { color: var(--ink) !important; }
  .auth-main { align-items: flex-start; padding-top: 40px; }
}

/* =========================================================
   Admin shell (shares tokens; layout unchanged)
   ========================================================= */
.admin-shell { min-height: 100dvh; display: grid; grid-template-columns: 248px minmax(0, 1fr); background: linear-gradient(to right, var(--side-bg) 248px, var(--bg) 248px); }
.admin-side { position: sticky; top: 0; height: 100dvh; display: flex; flex-direction: column; gap: 28px; padding: 24px 16px; background: var(--side-bg); color: var(--side-ink); overflow-y: auto; }
.admin-logo { padding: 0 12px; font-size: 20px; font-weight: 700; letter-spacing: -0.03em; color: #f1f5f3 !important; text-decoration: none; }
.admin-nav { display: flex; flex-direction: column; gap: 2px; flex: 1; }
.admin-nav a, .admin-side-link { display: flex; align-items: center; gap: 12px; min-height: 44px; padding: 0 12px; border: 0; border-radius: 10px; background: transparent; color: var(--side-ink); font-size: 15px; font-weight: 500; text-decoration: none; text-align: left; width: 100%; transition: background-color 0.2s var(--ease); }
.admin-nav a:hover, .admin-side-link:hover { background: rgba(255, 255, 255, 0.07); color: #f1f5f3; }
.admin-nav a.active { background: #dcebe4; color: #0a3a2c; font-weight: 600; }
.admin-nav-count { margin-left: auto; min-width: 22px; height: 22px; padding: 0 6px; border-radius: 11px; background: #4fbf97; color: #06130e; font-size: 12px; font-weight: 700; line-height: 22px; text-align: center; }
.admin-side-foot { display: flex; flex-direction: column; gap: 2px; padding-top: 16px; border-top: 1px solid var(--side-line); }
.admin-main { min-width: 0; display: flex; flex-direction: column; }
.admin-top { height: 64px; display: flex; align-items: center; justify-content: flex-end; gap: 12px; padding: 0 32px; background: var(--surface); border-bottom: 1px solid var(--line); }
.admin-menu { display: none; margin-right: auto; }
.admin-user { display: flex; align-items: center; gap: 8px; font-size: 14px; font-weight: 600; }
.admin-content { padding: 32px; }
.admin-scrim { display: none; }
@media (max-width: 900px) {
  .admin-shell { grid-template-columns: 1fr; background: var(--bg); }
  .admin-side { position: fixed; z-index: calc(var(--z-drawer) + 1); left: 0; width: 264px; transform: translateX(-100%); transition: transform 0.25s var(--ease); visibility: hidden; }
  .admin-side.is-open { transform: translateX(0); visibility: visible; }
  .admin-menu { display: inline-flex; }
  .admin-top { padding: 0 12px 0 8px; position: sticky; top: 0; z-index: var(--z-sticky); }
  .admin-content { padding: 20px 16px 64px; }
  .admin-scrim { display: block; position: fixed; inset: 0; z-index: var(--z-drawer); padding: 0; border: 0; background: var(--scrim); }
}
.admin-page { display: flex; flex-direction: column; gap: 24px; max-width: 1240px; }
.admin-head { display: flex; align-items: flex-end; justify-content: space-between; gap: 16px; flex-wrap: wrap; }
.admin-head h1 { font-size: clamp(28px, 3.6vw, 36px); letter-spacing: -0.03em; }
.admin-head p { margin-top: 4px; color: var(--muted); }
.admin-head-actions { display: flex; gap: 10px; flex-wrap: wrap; }
.back-link { display: inline-flex; align-items: center; gap: 6px; font-weight: 600; font-size: 14px; text-decoration: none; min-height: 32px; }
.panel { padding: 22px; border-radius: var(--r); background: var(--surface); border: 1px solid var(--line); min-width: 0; }
.panel-head { display: flex; align-items: baseline; justify-content: space-between; gap: 12px; margin-bottom: 18px; flex-wrap: wrap; }
.panel-head h2 { font-size: 20px; }
.panel-meta { font-size: 14px; color: var(--muted); font-weight: 500; }
.panel-link { font-size: 14px; font-weight: 600; }
.panel-flush { padding: 0; overflow: hidden; }
.toolbar { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
.toolbar .search { flex: 1; min-width: 200px; max-width: 360px; }
.toolbar select { min-height: 44px; padding: 0 12px; border: 1px solid var(--line-2); border-radius: var(--r-pill); background: var(--surface); color: var(--ink); font-size: 14px; font-weight: 500; }
.tabs { display: flex; gap: 6px; overflow-x: auto; padding-bottom: 2px; }
.tab { flex-shrink: 0; display: inline-flex; align-items: center; gap: 8px; min-height: 40px; padding: 0 14px; border: 1px solid var(--line-2); border-radius: var(--r-pill); background: var(--surface); font-size: 14px; font-weight: 500; color: var(--ink); transition: border-color 0.2s var(--ease); }
.tab:hover { border-color: var(--ink-2); }
.tab[aria-pressed="true"] { background: var(--accent); border-color: var(--accent); color: var(--on-accent); }
.tab-count { min-width: 20px; height: 20px; padding: 0 6px; border-radius: 10px; background: var(--tint); color: var(--ink-2); font-size: 12px; font-weight: 700; line-height: 20px; text-align: center; }
.tab[aria-pressed="true"] .tab-count { background: color-mix(in srgb, var(--on-accent) 20%, transparent); color: var(--on-accent); }

.table-scroll { overflow-x: auto; }
.table { width: 100%; border-collapse: collapse; font-size: 14px; }
.table th, .table td { padding: 12px 14px; border-bottom: 1px solid var(--line); text-align: left; vertical-align: middle; white-space: nowrap; }
.table th { font-size: 13px; font-weight: 600; color: var(--muted); background: var(--tint-2); }
.table tbody tr:last-child td { border-bottom: 0; }
.table tbody tr { transition: background-color 0.15s var(--ease); }
.table tbody tr:hover td { background: var(--tint-2); }
.table a { font-weight: 600; }
.table .num { text-align: right; font-variant-numeric: tabular-nums; }
.table-thumb { width: 44px; height: 44px; border-radius: 8px; overflow: hidden; flex-shrink: 0; }
.cell-product { display: flex; align-items: center; gap: 12px; }
.cell-product strong { display: block; }
.row-actions { display: flex; gap: 4px; justify-content: flex-end; }
.is-hidden-row td { color: var(--muted); }
.stock-num-low { color: var(--warn); font-weight: 700; }
.stock-num-out { color: var(--error); font-weight: 700; }

.admin-form { display: grid; grid-template-columns: minmax(0, 1fr) 340px; gap: 24px; align-items: start; }
.admin-form-main, .admin-form-side { display: flex; flex-direction: column; gap: 20px; }
.admin-form-side { position: sticky; top: 88px; }
@media (max-width: 1100px) { .admin-form { grid-template-columns: 1fr; } .admin-form-side { position: static; } }
.save-bar { position: sticky; bottom: 0; z-index: 20; display: flex; justify-content: flex-end; gap: 10px; margin: 0 -32px -32px; padding: 14px 32px; background: var(--surface); border-top: 1px solid var(--line); }
@media (max-width: 900px) { .save-bar { margin: 0 -16px -64px; padding: 12px 16px; } }
.image-manager { display: grid; grid-template-columns: repeat(auto-fill, minmax(120px, 1fr)); gap: 12px; }
.im-tile { position: relative; aspect-ratio: 1; border-radius: var(--r-sm); overflow: hidden; background: var(--tint); }
.im-tile img { width: 100%; height: 100%; object-fit: cover; }
.im-tile-main, .im-tile-new { position: absolute; left: 6px; top: 6px; padding: 2px 8px; border-radius: 10px; font-size: 11px; font-weight: 700; }
.im-tile-main { background: var(--accent); color: var(--on-accent); }
.im-tile-new { background: var(--surface); color: var(--ink); }
.im-tile-actions { position: absolute; right: 4px; bottom: 4px; display: flex; gap: 4px; }
.im-tile-actions .icon-btn { width: 36px; height: 36px; background: var(--surface); box-shadow: var(--shadow-sm); }
.im-add { position: relative; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 6px; aspect-ratio: 1; border: 2px dashed var(--line-2); border-radius: var(--r-sm); background: var(--surface); color: var(--accent); font-size: 13px; font-weight: 600; cursor: pointer; text-align: center; padding: 8px; }
.im-add:hover { border-color: var(--accent); background: var(--accent-soft); }
.im-add:focus-within { outline: 2px solid var(--accent); outline-offset: 2px; }
.im-add input { position: absolute; opacity: 0; width: 1px; height: 1px; }
.asset-row { display: flex; gap: 14px; align-items: center; }
.asset-preview { width: 88px; height: 88px; flex-shrink: 0; border-radius: var(--r-sm); background: repeating-conic-gradient(var(--tint) 0% 25%, var(--surface) 0% 50%) 50% / 16px 16px; overflow: hidden; display: flex; align-items: center; justify-content: center; color: var(--muted); }
.asset-preview img { width: 100%; height: 100%; object-fit: contain; }
.gallery-admin { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 16px; }
.model-admin { display: flex; flex-direction: column; gap: 10px; padding: 8px 8px 12px; border-radius: var(--r); background: var(--surface); border: 1px solid var(--line); }
.model-admin img { aspect-ratio: 3 / 4; object-fit: cover; border-radius: 10px; }
.model-admin.is-off img { opacity: 0.45; }
.model-admin-body { display: flex; justify-content: space-between; align-items: center; gap: 8px; padding: 0 4px; }
.model-admin-body strong { font-size: 15px; }
.model-admin-actions { display: flex; gap: 6px; padding: 0 4px; }
.detail-grid { display: grid; grid-template-columns: minmax(0, 1fr) 360px; gap: 20px; align-items: start; }
.detail-side { display: flex; flex-direction: column; gap: 20px; }
@media (max-width: 1100px) { .detail-grid { grid-template-columns: 1fr; } }
.kv { display: grid; grid-template-columns: auto 1fr; gap: 8px 16px; font-size: 15px; }
.kv dt { color: var(--muted); }
.kv dd { margin: 0; font-weight: 500; min-width: 0; word-break: break-word; }
.contact-actions { display: flex; gap: 8px; flex-wrap: wrap; margin-top: 12px; }
.status-actions { display: flex; flex-direction: column; gap: 10px; }
.cat-row-img { width: 44px; height: 44px; border-radius: var(--r-sm); overflow: hidden; background: var(--accent-soft); color: var(--accent); display: flex; align-items: center; justify-content: center; flex-shrink: 0; font-weight: 700; }
.cat-row-img img { width: 100%; height: 100%; object-fit: cover; }

.stats { display: grid; grid-template-columns: 1.4fr repeat(3, minmax(0, 1fr)); gap: 16px; }
.stat { display: flex; flex-direction: column; gap: 6px; padding: 22px; border-radius: var(--r); background: var(--surface); border: 1px solid var(--line); color: var(--ink); text-decoration: none; transition: border-color 0.2s var(--ease); }
.stat-label { font-size: 14px; font-weight: 500; color: var(--muted); }
.stat-value { font-size: 34px; font-weight: 600; letter-spacing: -0.03em; line-height: 1.1; font-variant-numeric: tabular-nums; }
.stat-note { font-size: 13px; color: var(--muted); }
.stat-hero { background: var(--accent); border-color: var(--accent); color: var(--on-accent); }
.stat-hero .stat-label, .stat-hero .stat-note { color: color-mix(in srgb, var(--on-accent) 80%, transparent); }
a.stat:hover { border-color: var(--accent); color: var(--ink); }
.stat-link .stat-note { color: var(--accent); font-weight: 600; }
@media (max-width: 1100px) { .stats { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
@media (max-width: 520px) { .stats { grid-template-columns: 1fr; } .stat-value { font-size: 30px; } }
.dash-grid { display: grid; grid-template-columns: minmax(0, 2fr) minmax(0, 1fr); gap: 16px; }
.panel-wide { grid-column: 1 / -1; }
@media (max-width: 1000px) { .dash-grid { grid-template-columns: 1fr; } }
.stock-list { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; }
.stock-list li { display: flex; align-items: center; justify-content: space-between; gap: 12px; padding: 12px 0; }
.stock-list li + li { border-top: 1px solid var(--line); }
.stock-name { display: flex; flex-direction: column; gap: 2px; font-weight: 500; min-width: 0; }
.stock-name .muted { font-size: 13px; font-weight: 400; }
a.stock-name { color: var(--ink); text-decoration: none; }
a.stock-name:hover { color: var(--accent); text-decoration: underline; }
.stock-count { flex-shrink: 0; display: inline-flex; align-items: center; gap: 4px; padding: 4px 10px; border-radius: var(--r-pill); background: var(--warn-bg); color: var(--warn); font-size: 13px; font-weight: 600; }
.stock-count.is-out { background: var(--error-bg); color: var(--error); }

.bars { position: relative; display: grid; gap: 10px; padding: 0 0 0 44px; }
.bars-dense { gap: 3px; }
.bars-grid { position: absolute; left: 0; right: 0; top: 0; bottom: 28px; display: flex; flex-direction: column; justify-content: space-between; pointer-events: none; }
.bars-grid span { position: relative; font-size: 12px; color: var(--muted); line-height: 0; font-variant-numeric: tabular-nums; }
.bars-grid span::after { content: ""; position: absolute; left: 44px; right: 0; top: 0; border-top: 1px solid var(--line); }
.bar-col { position: relative; display: flex; flex-direction: column; gap: 8px; min-width: 0; outline: none; }
.bar-track { position: relative; flex: 1; display: flex; align-items: flex-end; justify-content: center; }
.bar { width: min(36px, 72%); min-height: 2px; border-radius: 4px 4px 0 0; background: var(--accent-muted); transition: background-color 0.15s var(--ease); }
.bars-dense .bar { width: 100%; }
.bar.is-highlight { background: var(--accent); }
.bar-col:hover .bar, .bar-col:focus-visible .bar { background: var(--accent-2); }
.bar-col:focus-visible .bar-track { outline: 2px solid var(--accent); outline-offset: 2px; border-radius: 4px; }
.bar-label { height: 20px; font-size: 12px; font-weight: 500; color: var(--muted); text-align: center; white-space: nowrap; overflow: visible; }
.bar-tip { position: absolute; z-index: 2; bottom: 50%; left: 50%; transform: translateX(-50%); display: none; flex-direction: column; gap: 2px; padding: 8px 12px; border-radius: 8px; background: var(--ink); color: var(--bg); font-size: 12px; white-space: nowrap; pointer-events: none; }
.bar-tip.tip-left { left: auto; right: 0; transform: none; }
.bar-tip.tip-right { left: 0; transform: none; }
.bar-tip strong { font-size: 14px; }
.bar-col:hover .bar-tip, .bar-col:focus-visible .bar-tip { display: flex; }
.hbars { display: flex; flex-direction: column; gap: 12px; }
.hbar { display: grid; grid-template-columns: 110px minmax(0, 1fr) 44px; gap: 12px; align-items: center; font-size: 14px; color: var(--ink); text-decoration: none; }
.hbar:hover { color: var(--accent); }
.hbar-track { height: 10px; }
.hbar-fill { display: block; height: 100%; border-radius: 0 4px 4px 0; background: var(--accent-muted); min-width: 2px; }
.hbar-value { text-align: right; font-weight: 600; font-variant-numeric: tabular-nums; }
.rank-list { list-style: none; margin: 0; padding: 0; counter-reset: rank; display: flex; flex-direction: column; }
.rank-list li { counter-increment: rank; display: grid; grid-template-columns: 28px minmax(0, 1fr) auto; gap: 10px; align-items: center; padding: 10px 0; font-size: 14px; }
.rank-list li + li { border-top: 1px solid var(--line); }
.rank-list li::before { content: counter(rank); width: 24px; height: 24px; border-radius: 50%; background: var(--accent-soft); color: var(--accent); font-size: 12px; font-weight: 700; display: flex; align-items: center; justify-content: center; }
.rank-list strong { font-variant-numeric: tabular-nums; }
.report-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px; }
@media (max-width: 900px) { .report-grid { grid-template-columns: 1fr; } }

/* Print (order packing slip) */
.print-only { display: none; }
@media print {
  :root { color-scheme: light; }
  body { background: #fff; color: #111; }
  .admin-side, .admin-top, .no-print, .toasts, .save-bar { display: none !important; }
  .admin-shell { display: block; background: #fff; }
  .admin-content { padding: 0; }
  .print-only { display: block; }
  .panel { border: 1px solid #ccc; break-inside: avoid; }
  .detail-grid { grid-template-columns: 1fr; }
}

/* Order notices: waiting for payment, confirmed, we'll call */
.notice { display: flex; gap: 14px; align-items: flex-start; padding: 16px 18px; border-radius: var(--r); border: 1px solid transparent; margin-bottom: 20px; }
.notice > svg { flex-shrink: 0; margin-top: 2px; }
.notice > div { display: flex; flex-direction: column; gap: 6px; min-width: 0; }
.notice strong:first-child { font-size: 16px; font-weight: 600; }
.notice p { font-size: 14px; line-height: 1.55; }
.notice .bank-box { margin-top: 6px; }
.notice-ok { background: var(--ok-bg); color: var(--ok); }
.notice-ok p { color: var(--ink); }
.notice-warn { background: var(--warn-bg); border-color: color-mix(in srgb, var(--warn) 25%, transparent); }
.notice-warn > svg, .notice-warn strong:first-child { color: var(--warn); }
.notice-info { background: var(--surface-2); }
.notice-info > svg { color: var(--accent); }
.confirm .notice { margin-bottom: 0; }
.order-card .notice { margin: 4px 0 0; }
.confirm-icon.is-waiting { background: var(--warn-bg); color: var(--warn); }
.confirm-icon.is-cancelled { background: var(--surface-2); color: var(--muted); }
'@

Write-Host 'Done. 11 files updated.'
Write-Host 'Restart the backend and frontend (Ctrl+C, then npm run dev in each).'
