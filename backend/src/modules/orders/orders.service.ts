import { Prisma } from "@prisma/client";
import { db } from "../../config/db";
import { env } from "../../config/env";
import { HttpError } from "../../middleware/error";

type OrderStatus = "PENDING" | "CONFIRMED" | "PROCESSING" | "READY" | "DISPATCHED" | "DELIVERED" | "CANCELLED";

export type CheckoutInput = {
  fullName: string; mobile: string; whatsapp?: string; email?: string;
  address?: string; city?: string; postalCode?: string; note?: string;
  deliveryMethod: "DELIVERY" | "PICKUP"; paymentMethod: "BANK_TRANSFER" | "COD" | "ONLINE";
};

// Allowed transitions: PENDING → CONFIRMED → PROCESSING → READY → DISPATCHED → DELIVERED (CANCELLED from any early stage)
const flow: Record<OrderStatus, OrderStatus[]> = {
  PENDING: ["CONFIRMED", "CANCELLED"],
  CONFIRMED: ["PROCESSING", "CANCELLED"],
  PROCESSING: ["READY", "CANCELLED"],
  READY: ["DISPATCHED", "DELIVERED"], // DELIVERED directly for store pickup
  DISPATCHED: ["DELIVERED"],
  DELIVERED: [],
  CANCELLED: [],
};

async function nextOrderNo(tx: Prisma.TransactionClient) {
  const n = (await tx.order.count()) + 1;
  return `ORD-${String(n).padStart(6, "0")}`;
}

export async function placeOrder(cartId: string, userId: string | undefined, input: CheckoutInput) {
  if (input.deliveryMethod === "DELIVERY" && (!input.address || !input.city)) throw new HttpError(400, "Address and city are required for delivery");

  return db.$transaction(async (tx: { cartItem: { findMany: (arg0: { where: { cartId: string; }; include: { product: boolean; }; }) => any; deleteMany: (arg0: { where: { cartId: string; }; }) => any; }; product: { updateMany: (arg0: { where: { id: any; stock: { gte: any; }; }; data: { stock: { decrement: any; }; }; }) => any; }; order: { create: (arg0: { data: { userId: string | undefined; orderNo: string; subtotal: any; deliveryFee: number; total: any; items: { create: any; }; history: { create: { status: string; }; }; fullName: string; mobile: string; whatsapp?: string; email?: string; address?: string; city?: string; postalCode?: string; note?: string; deliveryMethod: "DELIVERY" | "PICKUP"; paymentMethod: "BANK_TRANSFER" | "COD" | "ONLINE"; }; include: { items: boolean; }; }) => any; }; }) => {
    const items = await tx.cartItem.findMany({ where: { cartId }, include: { product: true } });
    if (!items.length) throw new HttpError(400, "Cart is empty");

    for (const i of items) {
      const updated = await tx.product.updateMany({ where: { id: i.productId, stock: { gte: i.qty } }, data: { stock: { decrement: i.qty } } });
      if (!updated.count) throw new HttpError(409, `${i.product.name} is out of stock`);
    }

    const subtotal = items.reduce((s: number, i: { product: { price: number; }; qty: number; }) => s + i.product.price * i.qty, 0);
    const deliveryFee = input.deliveryMethod === "DELIVERY" ? env.deliveryFee : 0;

    const order = await tx.order.create({
      data: {
        ...input, userId, orderNo: await nextOrderNo(tx), subtotal, deliveryFee, total: subtotal + deliveryFee,
        items: { create: items.map((i: { productId: any; product: { name: any; price: any; }; qty: any; }) => ({ productId: i.productId, name: i.product.name, price: i.product.price, qty: i.qty })) },
        history: { create: { status: "PENDING" } },
      },
      include: { items: true },
    });
    await tx.cartItem.deleteMany({ where: { cartId } });
    return order;
  });
}

export async function changeStatus(orderId: string, to: OrderStatus) {
  const o = await db.order.findUnique({ where: { id: orderId }, include: { items: true } });
  if (!o) throw new HttpError(404, "Order not found");
  const currentStatus = o.status as OrderStatus;
  if (!flow[currentStatus].includes(to)) throw new HttpError(409, `Cannot move ${currentStatus} → ${to}`);

  return db.$transaction(async (tx: { product: { update: (arg0: { where: { id: any; }; data: { stock: { increment: any; }; }; }) => any; }; orderStatusLog: { create: (arg0: { data: { orderId: string; status: OrderStatus; }; }) => any; }; order: { update: (arg0: { where: { id: string; }; data: { status: OrderStatus; }; }) => any; }; }) => {
    if (to === "CANCELLED") {
      for (const i of o.items) await tx.product.update({ where: { id: i.productId }, data: { stock: { increment: i.qty } } });
    }
    await tx.orderStatusLog.create({ data: { orderId, status: to } });
    return tx.order.update({ where: { id: orderId }, data: { status: to } });
  });
}