export type JewelleryType = "EARRINGS" | "NECKLACE" | "CHAIN" | "LONG_CHAIN" | "BANGLE" | "BRACELET" | "RING" | "ANKLET" | "HAIR" | "OTHER";
export type OrderStatus = "PENDING" | "CONFIRMED" | "PROCESSING" | "READY" | "DISPATCHED" | "DELIVERED" | "CANCELLED";

export type Category = { id: string; name: string; slug: string; imageUrl?: string };
export type ProductImage = { id: string; url: string };
export type Product = {
  id: string; code: string; name: string; slug: string; description?: string; price: number; stock: number;
  jewelleryType: JewelleryType; tryOnEnabled: boolean; images: ProductImage[]; category?: Category;
};
export type CartItem = { id: string; productId: string; qty: number; product: Product };
export type Cart = { id: string; items: CartItem[]; subtotal: number };
export type OrderItem = { id: string; name: string; price: number; qty: number };
export type Order = {
  id: string; orderNo: string; fullName: string; mobile: string; city?: string; total: number; subtotal: number;
  deliveryFee: number; status: OrderStatus; paymentMethod: string; paymentStatus: string; deliveryMethod: string;
  items: OrderItem[]; createdAt: string;
};
export type AiModel = { id: string; name: string; imageUrl: string };
export type TryOnJob = { id: string; status: "PENDING" | "PROCESSING" | "DONE" | "FAILED"; resultUrl?: string; error?: string };
export type Paged<T> = { items: T[]; total: number; page?: number; pages?: number };

export type Role = "CUSTOMER" | "ADMIN";
export type User = { id: string; name: string; email?: string; phone?: string; role: Role };
export type AuthResponse = { token: string; user: User };

export type DashboardData = {
  todayOrders: number; pending: number; processing: number; completed: number; todaySales: number;
  last7Days: { date: string; sales: number; orders: number }[];
  recentOrders: { id: string; orderNo: string; fullName: string; total: number; status: OrderStatus; createdAt: string }[];
  lowStock: { id: string; name: string; code: string; stock: number }[];
};
