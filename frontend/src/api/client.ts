import type {
  AiModel, AuthResponse, Cart, Category, Customer, CustomerDetail, DashboardData, Offer, Order, OrderStatus,
  OrdersPage, Paged, PaymentStatus, Product, ProductFilters, ProductReport, SalesRow, SavedTryOn, Settings, TryOnJob, User,
} from "./types";

const cartKey = () => {
  let k = localStorage.getItem("cartKey");
  if (!k) {
    k = typeof crypto !== "undefined" && "randomUUID" in crypto ? crypto.randomUUID() : `${Date.now()}-${Math.random().toString(36).slice(2)}`;
    localStorage.setItem("cartKey", k);
  }
  return k;
};

export const auth = {
  get token() { return localStorage.getItem("token"); },
  set(token: string | null) { token ? localStorage.setItem("token", token) : localStorage.removeItem("token"); },
};

export class ApiError extends Error {
  constructor(public status: number, message: string, public field?: string) { super(message); }
}

async function req<T>(path: string, init: RequestInit = {}): Promise<T> {
  const headers: Record<string, string> = { "x-cart-key": cartKey() };
  if (auth.token) headers.Authorization = `Bearer ${auth.token}`;
  if (init.body && !(init.body instanceof FormData)) headers["Content-Type"] = "application/json";

  let res: Response;
  try {
    res = await fetch(`/api${path}`, { ...init, headers: { ...headers, ...(init.headers as Record<string, string>) } });
  } catch {
    throw new ApiError(0, "Can't reach the shop right now. Check your connection and try again.");
  }
  if (res.status === 204) return undefined as T;
  const data = await res.json().catch(() => ({}));
  if (res.status === 401 && auth.token && !path.startsWith("/auth/login")) auth.set(null);
  if (!res.ok) throw new ApiError(res.status, data.error ?? "Something went wrong. Try again.", data.field);
  return data as T;
}

const json = (method: string, body?: unknown): RequestInit => ({ method, body: body === undefined ? undefined : JSON.stringify(body) });
const qs = (o: Record<string, unknown>) =>
  new URLSearchParams(Object.entries(o).filter(([, v]) => v !== undefined && v !== null && v !== "").map(([k, v]) => [k, String(v)])).toString();

export const api = {
  // Account
  login: (email: string, password: string) => req<AuthResponse>("/auth/login", json("POST", { email, password })),
  register: (b: { name: string; email: string; password: string; phone?: string }) => req<AuthResponse>("/auth/register", json("POST", b)),
  me: () => req<User>("/auth/me"),
  updateMe: (b: { name?: string; phone?: string }) => req<User>("/auth/me", json("PATCH", b)),
  changePassword: (current: string, next: string) => req<void>("/auth/password", json("POST", { current, next })),
  mergeCart: () => req<Cart>("/cart/merge", json("POST", { guestKey: cartKey() })),

  // Shop
  settings: () => req<Settings>("/settings"),
  categories: () => req<Category[]>("/categories"),
  products: (f: Record<string, unknown> = {}) => req<Paged<Product>>(`/products?${qs(f)}`),
  productFilters: () => req<ProductFilters>("/products/filters"),
  product: (slug: string) => req<Product>(`/products/${encodeURIComponent(slug)}`),
  related: (slug: string) => req<Product[]>(`/products/${encodeURIComponent(slug)}/related`),

  // Cart & orders
  cart: () => req<Cart>("/cart"),
  addToCart: (items: { productId: string; qty: number }[]) => req<Cart>("/cart/items", json("POST", { items })),
  setQty: (productId: string, qty: number) => req<Cart>(`/cart/items/${productId}`, json("PATCH", { qty })),
  removeItem: (productId: string) => req<Cart>(`/cart/items/${productId}`, json("DELETE")),
  placeOrder: (b: Record<string, unknown>) => req<Order>("/orders", json("POST", b)),
  myOrders: () => req<Order[]>("/orders/mine"),
  trackOrder: (orderNo: string, mobile: string) => req<Order>(`/orders/track?${qs({ orderNo, mobile })}`),

  // Wishlist
  wishlist: () => req<Product[]>("/wishlist"),
  wishlistIds: () => req<string[]>("/wishlist/ids"),
  addWish: (productId: string) => req<void>(`/wishlist/${productId}`, json("POST")),
  removeWish: (productId: string) => req<void>(`/wishlist/${productId}`, json("DELETE")),

  // Try-on
  aiModels: () => req<AiModel[]>("/tryon/models"),
  startTryOn: (fd: FormData) => req<TryOnJob>("/tryon", { method: "POST", body: fd }),
  tryOnStatus: (id: string) => req<TryOnJob>(`/tryon/${id}`),
  myTryOns: () => req<SavedTryOn[]>("/tryon/mine"),

  admin: {
    dashboard: () => req<DashboardData>("/admin/dashboard"),

    products: (f: Record<string, unknown> = {}) => req<Paged<Product>>(`/admin/products?${qs(f)}`),
    product: (id: string) => req<Product>(`/admin/products/${id}`),
    saveProduct: (fd: FormData, id?: string) => req<Product>(id ? `/products/${id}` : "/products", { method: id ? "PUT" : "POST", body: fd }),
    hideProduct: (id: string) => req<void>(`/products/${id}`, json("DELETE")),
    deleteImage: (productId: string, imageId: string) => req<void>(`/products/${productId}/images/${imageId}`, json("DELETE")),
    orderImages: (productId: string, order: string[]) => req<void>(`/products/${productId}/images/order`, json("PUT", { order })),
    removeTryOnAsset: (productId: string) => req<void>(`/products/${productId}/try-on-asset`, json("DELETE")),

    saveCategory: (fd: FormData, id?: string) => req<Category>(id ? `/categories/${id}` : "/categories", { method: id ? "PUT" : "POST", body: fd }),
    deleteCategory: (id: string) => req<void>(`/categories/${id}`, json("DELETE")),

    orders: (f: Record<string, unknown> = {}) => req<OrdersPage>(`/admin/orders?${qs(f)}`),
    order: (id: string) => req<Order>(`/admin/orders/${id}`),
    setStatus: (id: string, status: OrderStatus) => req<Order>(`/admin/orders/${id}/status`, json("PATCH", { status })),
    setPayment: (id: string, paymentStatus: PaymentStatus) => req<Order>(`/admin/orders/${id}/payment`, json("PATCH", { paymentStatus })),

    customers: (f: Record<string, unknown> = {}) => req<Paged<Customer>>(`/admin/customers?${qs(f)}`),
    customer: (id: string) => req<CustomerDetail>(`/admin/customers/${id}`),

    aiModels: () => req<AiModel[]>("/admin/ai-models"),
    addAiModel: (fd: FormData) => req<AiModel>("/admin/ai-models", { method: "POST", body: fd }),
    updateAiModel: (id: string, b: { name?: string; isActive?: boolean }) => req<AiModel>(`/admin/ai-models/${id}`, json("PATCH", b)),
    deleteAiModel: (id: string) => req<{ hidden?: boolean } | undefined>(`/admin/ai-models/${id}`, json("DELETE")),

    offers: () => req<Offer[]>("/admin/offers"),
    saveOffer: (b: Record<string, unknown>, id?: string) => req<Offer>(id ? `/admin/offers/${id}` : "/admin/offers", json(id ? "PUT" : "POST", b)),
    deleteOffer: (id: string) => req<void>(`/admin/offers/${id}`, json("DELETE")),

    salesReport: (range: "daily" | "weekly" | "monthly") => req<SalesRow[]>(`/admin/reports/sales?range=${range}`),
    ordersReport: () => req<{ status: OrderStatus; count: number }[]>("/admin/reports/orders"),
    productsReport: () => req<ProductReport>("/admin/reports/products"),

    saveSettings: (b: Partial<Settings>) => req<Settings>("/settings", json("PUT", b)),
  },
};
