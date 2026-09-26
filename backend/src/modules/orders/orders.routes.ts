import { Router } from "express";
import { z } from "zod";
import { db } from "../../config/db";
import { ah, HttpError } from "../../middleware/error";
import { optionalAuth, requireAuth } from "../../middleware/auth";
import { resolveCart } from "../cart/cart.service";
import { placeOrder } from "./orders.service";

const r = Router();

const checkout = z.object({
  fullName: z.string().min(2), mobile: z.string().regex(/^0\d{9}$/, "Use format 07XXXXXXXX"),
  whatsapp: z.string().optional(), email: z.string().email().optional().or(z.literal("")),
  address: z.string().optional(), city: z.string().optional(), postalCode: z.string().optional(), note: z.string().optional(),
  deliveryMethod: z.enum(["DELIVERY", "PICKUP"]), paymentMethod: z.enum(["BANK_TRANSFER", "COD", "ONLINE"]),
});

r.post("/", optionalAuth, ah(async (req, res) => {
  const input = checkout.parse(req.body);
  const cart = await resolveCart(req);
  const order = await placeOrder(cart.id, req.user?.id, { ...input, email: input.email || undefined });
  res.status(201).json(order);
}));

r.get("/mine", requireAuth, ah(async (req, res) => {
  res.json(await db.order.findMany({ where: { userId: req.user!.id }, orderBy: { createdAt: "desc" }, include: { items: true } }));
}));

// Public tracking: order number + mobile
r.get("/track", ah(async (req, res) => {
  const { orderNo, mobile } = z.object({ orderNo: z.string(), mobile: z.string() }).parse(req.query);
  const o = await db.order.findFirst({ where: { orderNo, mobile }, include: { items: true, history: { orderBy: { createdAt: "asc" } } } });
  if (!o) throw new HttpError(404, "No order found with those details");
  res.json(o);
}));

export default r;