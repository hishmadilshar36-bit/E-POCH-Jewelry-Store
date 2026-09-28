export type JewelleryType = "EARRINGS" | "NECKLACE" | "CHAIN" | "LONG_CHAIN" | "BANGLE" | "BRACELET" | "RING" | "ANKLET" | "HAIR" | "OTHER";
export type OrderStatus = "PENDING" | "CONFIRMED" | "PROCESSING" | "READY" | "DISPATCHED" | "DELIVERED" | "CANCELLED";
export type PaymentMethod = "BANK_TRANSFER" | "COD" | "ONLINE";
export type PaymentStatus = "UNPAID" | "PAID" | "REFUNDED";
export type DeliveryMethod = "DELIVERY" | "PICKUP";
export type Role = "CUSTOMER" | "ADMIN";

export type Paged<T> = { items: T[]; total: number; page: number; pages: number };

export type Category = { id: string; name: string; slug: string; imageUrl?: string | null; sort: number; _count?: { products: number } };
export type ProductImage = { id: string; url: string; sort?: number };

export type Pricing = { salePrice: number | null; offerPercent: number | null; offerTitle: string | null };
export type Product = Pricing & {
  id: string; code: string; name: string; slug: string; description?: string | null;
  price: number; stock: number; isActive: boolean; isNewArrival: boolean;
  style?: string | null; colour?: string | null;
  jewelleryType: JewelleryType; tryOnEnabled: boolean; tryOnAssetUrl?: string | null;
  categoryId: string; category?: Category; images: ProductImage[]; createdAt: string;
};
export type ProductFilters = { styles: string[]; colours: string[]; minPrice: number; maxPrice: number };

export type CartItem = { id: string; productId: string; qty: number; unitPrice: number; lineTotal: number; inStock: boolean; product: Product };
export type Cart = { id: string; items: CartItem[]; subtotal: number; deliveryFee: number; total: number; freeDeliveryOver: number | null };

export type OrderItem = { id: string; productId: string; name: string; price: number; qty: number; product?: { slug: string; code?: string; images: ProductImage[] } };
export type StatusLog = { id: string; status: OrderStatus; createdAt: string };
export type Order = {
  id: string; orderNo: string; fullName: string; mobile: string; whatsapp?: string | null; email?: string | null;
  address?: string | null; city?: string | null; postalCode?: string | null; note?: string | null;
  deliveryMethod: DeliveryMethod; paymentMethod: PaymentMethod; paymentStatus: PaymentStatus;
  subtotal: number; deliveryFee: number; total: number; status: OrderStatus; createdAt: string;
  items: OrderItem[]; history?: StatusLog[]; _count?: { items: number };
  nextStatuses?: OrderStatus[]; user?: { id: string; email: string } | null;
};
export type OrdersPage = Paged<Order> & { byStatus: Partial<Record<OrderStatus, number>> };

export type AiModel = { id: string; name: string; imageUrl: string; isActive: boolean; _count?: { tryOns: number } };
export type TryOnJob = { id: string; status: "PENDING" | "PROCESSING" | "DONE" | "FAILED"; resultUrl?: string | null; error?: string | null };
export type SavedTryOn = { id: string; resultUrl: string; createdAt: string; items: { product: { id: string; name: string; slug: string; price: number; isActive: boolean } }[] };

export type User = { id: string; name: string; email?: string; phone?: string | null; role: Role };
export type AuthResponse = { token: string; user: User };

export type Settings = {
  shopName: string; tagline: string; phone: string; whatsapp: string; email: string; address: string;
  deliveryFee: number; freeDeliveryOver: number | null; bankDetails: string;
  codEnabled: boolean; bankEnabled: boolean; onlineEnabled: boolean; pickupEnabled: boolean;
};

export type Offer = {
  id: string; title: string; percentOff: number; startsAt: string; endsAt: string; isActive: boolean;
  productId: string | null; categoryId: string | null;
  product?: { id: string; name: string; code: string } | null; category?: { id: string; name: string } | null;
};

export type Customer = { id: string; name: string; email: string; phone?: string | null; createdAt: string; _count: { orders: number }; totalSpent: number };
export type CustomerDetail = { id: string; name: string; email: string; phone?: string | null; createdAt: string; orders: Pick<Order, "id" | "orderNo" | "total" | "status" | "createdAt">[] };

export type DashboardData = {
  todayOrders: number; pending: number; processing: number; completed: number; todaySales: number;
  last7Days: { date: string; sales: number; orders: number }[];
  recentOrders: { id: string; orderNo: string; fullName: string; total: number; status: OrderStatus; createdAt: string }[];
  lowStock: { id: string; name: string; code: string; stock: number }[];
};
export type SalesRow = { period: string; orders: number; sales: number };
export type ProductReport = {
  top: { productId: string; name: string; qty: number }[];
  outOfStock: { id: string; name: string; code: string }[];
  newest: { id: string; name: string; code: string; createdAt: string }[];
  mostTried: { id?: string; name?: string; code?: string; tries: number }[];
};
