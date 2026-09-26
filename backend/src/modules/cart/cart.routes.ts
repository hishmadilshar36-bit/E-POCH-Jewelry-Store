import { Router } from "express";
import { z } from "zod";
import { db } from "../../config/db";
import { ah, HttpError } from "../../middleware/error";
import { optionalAuth, requireAuth } from "../../middleware/auth";
import { resolveCart, cartView, mergeGuestCart } from "./cart.service";

const r = Router();
r.use(optionalAuth);

r.get("/", ah(async (req, res) => res.json(await cartView((await resolveCart(req)).id))));

// Single item or "Build Your Look" bundle: { items: [{productId, qty}] }
r.post("/items", ah(async (req, res) => {
  const b = z.object({ items: z.array(z.object({ productId: z.string(), qty: z.number().int().min(1).default(1) })).min(1) }).parse(req.body);
  const cart = await resolveCart(req);
  for (const it of b.items) {
    const p = await db.product.findUnique({ where: { id: it.productId } });
    if (!p || !p.isActive) throw new HttpError(404, "Product not found");
    if (p.stock < it.qty) throw new HttpError(409, `${p.name} is out of stock`);
    await db.cartItem.upsert({
      where: { cartId_productId: { cartId: cart.id, productId: it.productId } },
      update: { qty: { increment: it.qty } },
      create: { cartId: cart.id, productId: it.productId, qty: it.qty },
    });
  }
  res.json(await cartView(cart.id));
}));

r.patch("/items/:productId", ah(async (req, res) => {
  const { qty } = z.object({ qty: z.number().int().min(1) }).parse(req.body);
  const cart = await resolveCart(req);
  await db.cartItem.update({ where: { cartId_productId: { cartId: cart.id, productId: req.params.productId } }, data: { qty } });
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