import { Router } from "express";
import { z } from "zod";
import { db } from "../../config/db";
import { ah, HttpError } from "../../middleware/error";
import { requireAdmin } from "../../middleware/auth";
import { changeStatus } from "../orders/orders.service";

const r = Router();
r.use(requireAdmin);

const orderStatuses = ["PENDING", "CONFIRMED", "PROCESSING", "READY", "DISPATCHED", "DELIVERED", "CANCELLED"] as const;

const startOfDay = (d = new Date()) => new Date(d.getFullYear(), d.getMonth(), d.getDate());

const dayKey = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;

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

r.get("/orders", ah(async (req, res) => {
  const q = z.object({ status: z.enum(orderStatuses).optional(), q: z.string().optional(), page: z.coerce.number().default(1) }).parse(req.query);
  const where = {
    ...(q.status && { status: q.status }),
    ...(q.q && { OR: [{ orderNo: { contains: q.q } }, { fullName: { contains: q.q, mode: "insensitive" as const } }, { mobile: { contains: q.q } }] }),
  };
  const [items, total] = await Promise.all([
    db.order.findMany({ where, orderBy: { createdAt: "desc" }, skip: (q.page - 1) * 20, take: 20 }),
    db.order.count({ where }),
  ]);
  res.json({ items, total });
}));

r.get("/orders/:id", ah(async (req, res) => {
  const o = await db.order.findUnique({ where: { id: req.params.id }, include: { items: true, history: { orderBy: { createdAt: "asc" } } } });
  if (!o) throw new HttpError(404, "Order not found");
  res.json(o);
}));

r.patch("/orders/:id/status", ah(async (req, res) => {
  const { status } = z.object({ status: z.enum(orderStatuses) }).parse(req.body);
  res.json(await changeStatus(req.params.id, status));
}));

r.patch("/orders/:id/payment", ah(async (req, res) => {
  const { paymentStatus } = z.object({ paymentStatus: z.enum(["UNPAID", "PAID", "REFUNDED"]) }).parse(req.body);
  res.json(await db.order.update({ where: { id: req.params.id }, data: { paymentStatus } }));
}));

r.get("/customers", ah(async (_req, res) => {
  res.json(await db.user.findMany({ where: { role: "CUSTOMER" }, select: { id: true, name: true, email: true, phone: true, createdAt: true, _count: { select: { orders: true } } }, orderBy: { createdAt: "desc" } }));
}));

// ---------- Reports ----------
r.get("/reports/sales", ah(async (req, res) => {
  const { range } = z.object({ range: z.enum(["daily", "weekly", "monthly"]).default("daily") }).parse(req.query);
  const unit = range === "daily" ? "day" : range === "weekly" ? "week" : "month";
  type SalesRow = { period: Date; orders: bigint; sales: bigint };
  const rows = (await db.$queryRawUnsafe(
    `SELECT date_trunc('${unit}', "createdAt") AS period, COUNT(*) AS orders, SUM(total) AS sales
     FROM "Order" WHERE status <> 'CANCELLED' GROUP BY 1 ORDER BY 1 DESC LIMIT 30`
  )) as SalesRow[];
  res.json(rows.map((row) => ({ period: row.period, orders: Number(row.orders), sales: Number(row.sales) })));
}));

r.get("/reports/orders", ah(async (_req, res) => {
  res.json(await db.order.groupBy({ by: ["status"], _count: true }));
}));

r.get("/reports/products", ah(async (_req, res) => {
  const top = await db.orderItem.groupBy({ by: ["productId", "name"], _sum: { qty: true }, orderBy: { _sum: { qty: "desc" } }, take: 10 });
  const outOfStock = await db.product.findMany({ where: { stock: 0, isActive: true }, select: { id: true, name: true, code: true } });
  const newest = await db.product.findMany({ orderBy: { createdAt: "desc" }, take: 10, select: { id: true, name: true, code: true, createdAt: true } });
  const tryOnConversions = await db.tryOnItem.groupBy({ by: ["productId"], _count: true, orderBy: { _count: { productId: "desc" } }, take: 10 });
  res.json({ top, outOfStock, newest, tryOnConversions });
}));

export default r;