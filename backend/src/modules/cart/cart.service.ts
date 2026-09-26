import { Request } from "express";
import { db } from "../../config/db";
import { HttpError } from "../../middleware/error";

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
  const items = await db.cartItem.findMany({
    where: { cartId },
    include: { product: { include: { images: { take: 1, orderBy: { sort: "asc" } } } } },
  });
  const subtotal = items.reduce((s: number, i: { product: { price: number; }; qty: number; }) => s + i.product.price * i.qty, 0);
  return { id: cartId, items, subtotal };
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