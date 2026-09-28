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
