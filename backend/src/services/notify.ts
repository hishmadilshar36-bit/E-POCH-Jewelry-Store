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
