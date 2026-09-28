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
