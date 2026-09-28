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
