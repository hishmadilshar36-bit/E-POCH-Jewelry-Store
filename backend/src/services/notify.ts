type OrderItem = {
  name: string;
  qty: number;
};

type Order = {
  orderNo: string;
  mobile: string;
  total: number;
  items: OrderItem[];
};

// Plug in SMS (e.g. Notify.lk / Dialog), WhatsApp Cloud API, or email here.
export async function notifyOrderPlaced(order: Order & { items: OrderItem[] }) {
  const lines = order.items.map((i) => `${i.name} × ${i.qty}`).join("\n");
  const msg = `Order ${order.orderNo} placed.\n${lines}\nTotal: LKR ${order.total.toLocaleString()}`;
  console.log("[notify customer]", order.mobile, msg);
  console.log("[notify shop]", msg);
}

export const whatsappLink = (phone: string, text: string) =>
  `https://wa.me/94${phone.replace(/^0/, "")}?text=${encodeURIComponent(text)}`;