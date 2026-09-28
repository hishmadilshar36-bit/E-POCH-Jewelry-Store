import type { DeliveryMethod, JewelleryType, OrderStatus, PaymentMethod, PaymentStatus } from "./types";

export const lkr = (n: number) => `LKR ${Math.round(n).toLocaleString("en-LK")}`;

export const shortDate = (iso: string) => new Date(iso).toLocaleDateString("en-GB", { day: "numeric", month: "short", year: "numeric" });
export const dateTime = (iso: string) =>
  new Date(iso).toLocaleString("en-GB", { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" });

export const statusLabel: Record<OrderStatus, string> = {
  PENDING: "Pending", CONFIRMED: "Confirmed", PROCESSING: "Processing", READY: "Ready",
  DISPATCHED: "Dispatched", DELIVERED: "Delivered", CANCELLED: "Cancelled",
};

export const customerStatus: Record<OrderStatus, string> = {
  PENDING: "Order received", CONFIRMED: "Order confirmed", PROCESSING: "Being prepared", READY: "Ready",
  DISPATCHED: "On the way", DELIVERED: "Delivered", CANCELLED: "Cancelled",
};

export const paymentLabel: Record<PaymentMethod, string> = { BANK_TRANSFER: "Bank transfer", COD: "Cash on delivery", ONLINE: "Online payment" };
export const paymentStatusLabel: Record<PaymentStatus, string> = { UNPAID: "Not paid", PAID: "Paid", REFUNDED: "Refunded" };
export const deliveryLabel: Record<DeliveryMethod, string> = { DELIVERY: "Delivery", PICKUP: "Store pickup" };

export const typeLabel: Record<JewelleryType, string> = {
  EARRINGS: "Earrings", NECKLACE: "Necklace", CHAIN: "Chain", LONG_CHAIN: "Long chain", BANGLE: "Bangle",
  BRACELET: "Bracelet", RING: "Ring", ANKLET: "Anklet", HAIR: "Hair accessory", OTHER: "Other",
};
export const jewelleryTypes = Object.keys(typeLabel) as JewelleryType[];

export const phoneLink = (n: string) => `tel:${n.replace(/\s/g, "")}`;
export const whatsappLink = (n: string, text = "") =>
  `https://wa.me/94${n.replace(/\D/g, "").replace(/^(94|0)/, "")}${text ? `?text=${encodeURIComponent(text)}` : ""}`;
