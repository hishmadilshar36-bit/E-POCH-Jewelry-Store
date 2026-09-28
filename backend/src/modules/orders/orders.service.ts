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
