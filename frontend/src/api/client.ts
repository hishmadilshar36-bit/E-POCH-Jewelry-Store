import type { AiModel, AuthResponse, Cart, Category, DashboardData, Order, Paged, Product, TryOnJob, User } from "./types";

const cartKey = () => {
  let k = localStorage.getItem("cartKey");
  if (!k) { k = crypto.randomUUID(); localStorage.setItem("cartKey", k); }
  return k;
};
export const auth = {
  get token() { return localStorage.getItem("token"); },
  set(token: string | null) { token ? localStorage.setItem("token", token) : localStorage.removeItem("token"); },
};

async function req<T>(path: string, init: RequestInit = {}): Promise<T> {
  const headers: Record<string, string> = { "x-cart-key": cartKey() };
  if (auth.token) headers.Authorization = `Bearer ${auth.token}`;
  if (init.body && !(init.body instanceof FormData)) headers["Content-Type"] = "application/json";
  const res = await fetch(`/api${path}`, { ...init, headers: { ...headers, ...(init.headers as object) } });
  if (res.status === 204) return undefined as T;
  const data = await res.json().catch(() => ({}));
  if (res.status === 401 && auth.token && !path.startsWith("/auth/login")) auth.set(null);
  if (!res.ok) throw new Error(data.error ?? "Something went wrong. Try again.");
  return data;
}
const json = (method: string, body?: unknown): RequestInit => ({ method, body: body ? JSON.stringify(body) : undefined });
const qs = (o: Record<string, unknown>) => new URLSearchParams(Object.entries(o).filter(([, v]) => v !== undefined && v !== "") as [string, string][]).toString();

export const api = {
  login: (email: string, password: string) => req<AuthResponse>("/auth/login", json("POST", { email, password })),
  register: (b: { name: string; email: string; password: string; phone?: string }) => req<AuthResponse>("/auth/register", json("POST", b)),
  me: () => req<User>("/auth/me"),
  mergeCart: () => req<Cart>("/cart/merge", json("POST", { guestKey: cartKey() })),

  categories: () => req<Category[]>("/categories"),
  products: (f: Record<string, unknown> = {}) => req<Paged<Product>>(`/products?${qs(f)}`),
  product: (slug: string) => req<Product>(`/products/${slug}`),

  cart: () => req<Cart>("/cart"),
  addToCart: (items: { productId: string; qty: number }[]) => req<Cart>("/cart/items", json("POST", { items })),
  setQty: (productId: string, qty: number) => req<Cart>(`/cart/items/${productId}`, json("PATCH", { qty })),
  removeItem: (productId: string) => req<Cart>(`/cart/items/${productId}`, json("DELETE")),

  placeOrder: (b: Record<string, unknown>) => req<Order>("/orders", json("POST", b)),
  trackOrder: (orderNo: string, mobile: string) => req<Order>(`/orders/track?${qs({ orderNo, mobile })}`),

  aiModels: () => req<AiModel[]>("/tryon/models"),
  startTryOn: (fd: FormData) => req<TryOnJob>("/tryon", { method: "POST", body: fd }),
  tryOnStatus: (id: string) => req<TryOnJob>(`/tryon/${id}`),

  admin: {
    dashboard: () => req<DashboardData>("/admin/dashboard"),
    orders: (f: Record<string, unknown> = {}) => req<Paged<Order>>(`/admin/orders?${qs(f)}`),
    order: (id: string) => req<Order>(`/admin/orders/${id}`),
    setStatus: (id: string, status: string) => req<Order>(`/admin/orders/${id}/status`, json("PATCH", { status })),
    saveProduct: (fd: FormData, id?: string) => req<Product>(id ? `/products/${id}` : "/products", { method: id ? "PUT" : "POST", body: fd }),
    deleteProduct: (id: string) => req<void>(`/products/${id}`, json("DELETE")),
  },
};
