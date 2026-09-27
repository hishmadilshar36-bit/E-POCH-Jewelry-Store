# E-POCH Jewelry Store - writes every frontend file into the right folder.
# Run from C:\E-POCH-Jewelry-Store-main\frontend :
#   powershell -ExecutionPolicy Bypass -File .\setup-frontend.ps1

$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Write-ProjectFile($rel, $content) {
  $path = Join-Path $here $rel
  $dir = Split-Path $path -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
  [System.IO.File]::WriteAllText($path, (($content -replace "`r`n", "`n") + "`n"), $utf8)
  Write-Host "wrote $rel"
}

Write-ProjectFile 'index.html' @'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" /><meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Jewellery Store</title>
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bodoni+Moda:opsz,wght@6..96,500;6..96,600&family=Manrope:wght@400;500;600;700&display=swap" />
  </head>
  <body><div id="root"></div><script type="module" src="/src/main.tsx"></script></body>
</html>
'@

Write-ProjectFile 'package.json' @'
{
  "name": "jewellery-frontend",
  "private": true,
  "type": "module",
  "scripts": { "dev": "vite", "build": "tsc -b && vite build", "preview": "vite preview" },
  "dependencies": { "react": "^18.3.1", "react-dom": "^18.3.1", "react-router-dom": "^6.26.2" },
  "devDependencies": {
    "@types/react": "^18.3.10", "@types/react-dom": "^18.3.0",
    "@vitejs/plugin-react": "^4.3.2", "typescript": "^5.6.2", "vite": "^5.4.8"
  }
}
'@

Write-ProjectFile 'src\App.tsx' @'
import { Routes, Route } from "react-router-dom";
import Layout from "./components/Layout";
import RequireAdmin from "./components/RequireAdmin";
import Home from "./pages/Home";
import Shop from "./pages/Shop";
import ProductDetails from "./pages/ProductDetails";
import TryOn from "./pages/TryOn";
import BuildLook from "./pages/BuildLook";
import CartPage from "./pages/Cart";
import Checkout from "./pages/Checkout";
import OrderConfirmation from "./pages/OrderConfirmation";
import TrackOrder from "./pages/TrackOrder";
import Login from "./pages/Login";
import Register from "./pages/Register";
import AdminLogin from "./pages/admin/AdminLogin";
import AdminLayout from "./pages/admin/AdminLayout";
import Dashboard from "./pages/admin/Dashboard";
import AdminProducts from "./pages/admin/Products";
import AdminOrders from "./pages/admin/Orders";
import AdminOrderDetail from "./pages/admin/OrderDetail";

export default function App() {
  return (
    <Routes>
      <Route element={<Layout />}>
        <Route path="/" element={<Home />} />
        <Route path="/shop" element={<Shop />} />
        <Route path="/shop/:category" element={<Shop />} />
        <Route path="/product/:slug" element={<ProductDetails />} />
        <Route path="/try-on" element={<TryOn />} />
        <Route path="/build-look" element={<BuildLook />} />
        <Route path="/cart" element={<CartPage />} />
        <Route path="/checkout" element={<Checkout />} />
        <Route path="/order/:orderNo" element={<OrderConfirmation />} />
        <Route path="/track" element={<TrackOrder />} />
      </Route>

      <Route path="/login" element={<Login />} />
      <Route path="/register" element={<Register />} />
      <Route path="/admin/login" element={<AdminLogin />} />
      <Route element={<RequireAdmin />}>
        <Route path="/admin" element={<AdminLayout />}>
          <Route index element={<Dashboard />} />
          <Route path="products" element={<AdminProducts />} />
          <Route path="orders" element={<AdminOrders />} />
          <Route path="orders/:id" element={<AdminOrderDetail />} />
        </Route>
      </Route>
    </Routes>
  );
}
'@

Write-ProjectFile 'src\api\client.ts' @'
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
'@

Write-ProjectFile 'src\api\types.ts' @'
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
'@

Write-ProjectFile 'src\components\AuthShell.tsx' @'
import { ReactNode } from "react";
import { Link } from "react-router-dom";

type Props = { title: string; subtitle: string; aside: ReactNode; children: ReactNode };

export default function AuthShell({ title, subtitle, aside, children }: Props) {
  return (
    <div className="auth">
      <aside className="auth-aside">
        <Link to="/" className="auth-logo">[Shop name]</Link>
        <div className="auth-aside-body">{aside}</div>
      </aside>
      <main className="auth-main">
        <div className="auth-card">
          <h1>{title}</h1>
          <p className="auth-sub">{subtitle}</p>
          {children}
        </div>
      </main>
    </div>
  );
}
'@

Write-ProjectFile 'src\components\Icon.tsx' @'
const paths = {
  dashboard: "M4 4h7v7H4zM13 4h7v4h-7zM13 10h7v10h-7zM4 13h7v7H4z",
  products: "M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z",
  orders: "M5 8h14l-1 12H6zM9 8a3 3 0 0 1 6 0",
  categories: "M4 5h6v6H4zM14 5h6v6h-6zM4 15h6v4H4zM14 15h6v4h-6z",
  customers: "M9 8a3 3 0 1 0 0 .01M3 20c.6-3.5 3-5.5 6-5.5s5.4 2 6 5.5M16 5.5a3 3 0 0 1 0 5.8M18 14.8c1.7.7 2.8 2.4 3 5.2",
  reports: "M4 20V10M10 20V4M16 20v-7M22 20H2",
  logout: "M15 4h4v16h-4M10 8l-4 4 4 4M6 12h11",
  store: "M4 10l8-6 8 6v10H4zM10 20v-6h4v6",
  eye: "M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7S2 12 2 12zM12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6",
  eyeOff: "M3 3l18 18M10.6 5.1A10 10 0 0 1 12 5c6.4 0 10 7 10 7a17 17 0 0 1-3.2 4.1M6.6 6.6C3.7 8.3 2 12 2 12s3.6 7 10 7a9.7 9.7 0 0 0 5.4-1.6M9.9 9.9a3 3 0 0 0 4.2 4.2",
  alert: "M12 3l10 18H2zM12 10v4M12 17.5v.01",
  menu: "M4 7h16M4 12h16M4 17h16",
  user: "M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM4 21c1-4 4-6 8-6s7 2 8 6",
} as const;

export type IconName = keyof typeof paths;

export default function Icon({ name, size = 20 }: { name: IconName; size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8}
      strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d={paths[name]} />
    </svg>
  );
}
'@

Write-ProjectFile 'src\components\Layout.tsx' @'
import { Link, NavLink, Outlet } from "react-router-dom";
import { useCart } from "../context/CartContext";
import { useAuth } from "../context/AuthContext";

export default function Layout() {
  const { count } = useCart();
  const { user, logout } = useAuth();
  return (
    <>
      <header className="nav">
        <Link to="/" className="logo">[Shop name]</Link>
        <nav>
          <NavLink to="/" end>Home</NavLink>
          <NavLink to="/shop">Shop</NavLink>
          <NavLink to="/shop?newArrivals=1">New arrivals</NavLink>
          <NavLink to="/build-look">Create your look</NavLink>
          <NavLink to="/track">Track order</NavLink>
        </nav>
        <div className="nav-actions">
          {user ? (
            <>
              {user.role === "ADMIN" && <Link to="/admin">Admin</Link>}
              <span className="muted">Hi, {user.name.split(" ")[0]}</span>
              <button className="btn-link" onClick={logout}>Sign out</button>
            </>
          ) : (
            <Link to="/login">Sign in</Link>
          )}
          <Link to="/cart" className="cart-link">Cart ({count})</Link>
        </div>
      </header>
      <main><Outlet /></main>
    </>
  );
}
'@

Write-ProjectFile 'src\components\PasswordInput.tsx' @'
import { useState } from "react";
import Icon from "./Icon";

type Props = { name: string; label: string; autoComplete: string; minLength?: number; hint?: string };

export default function PasswordInput({ name, label, autoComplete, minLength, hint }: Props) {
  const [show, setShow] = useState(false);
  return (
    <label className="field">
      <span className="field-label">{label}</span>
      <span className="input-wrap">
        <input name={name} type={show ? "text" : "password"} required minLength={minLength} autoComplete={autoComplete} />
        <button type="button" className="input-icon" aria-label={show ? "Hide password" : "Show password"} onClick={() => setShow(!show)}>
          <Icon name={show ? "eyeOff" : "eye"} size={18} />
        </button>
      </span>
      {hint && <span className="field-hint">{hint}</span>}
    </label>
  );
}
'@

Write-ProjectFile 'src\components\ProductCard.tsx' @'
import { Link, useNavigate } from "react-router-dom";
import type { Product } from "../api/types";
import { useCart } from "../context/CartContext";

export const lkr = (n: number) => `LKR ${n.toLocaleString("en-LK")}`;

export default function ProductCard({ p }: { p: Product }) {
  const { add } = useCart();
  const nav = useNavigate();
  return (
    <article className="card">
      <Link to={`/product/${p.slug}`}><img src={p.images[0]?.url} alt={p.name} /></Link>
      <h3>{p.name}</h3>
      <p>{lkr(p.price)}</p>
      <div className="row">
        <button disabled={!p.stock} onClick={() => add([{ productId: p.id, qty: 1 }])}>{p.stock ? "Add to cart" : "Sold out"}</button>
        {p.tryOnEnabled && <button onClick={() => nav(`/try-on?products=${p.id}`)}>Try with AI</button>}
      </div>
    </article>
  );
}
'@

Write-ProjectFile 'src\components\RequireAdmin.tsx' @'
import { Navigate, Outlet } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

export default function RequireAdmin() {
  const { user, loading } = useAuth();
  if (loading) return <p className="page-loading" role="status">Loading…</p>;
  if (!user) return <Navigate to="/admin/login" replace />;
  if (user.role !== "ADMIN") return <Navigate to="/" replace />;
  return <Outlet />;
}
'@

Write-ProjectFile 'src\context\AuthContext.tsx' @'
import { createContext, useContext, useEffect, useState, ReactNode } from "react";
import { api, auth } from "../api/client";
import type { User } from "../api/types";
import { useCart } from "./CartContext";

type RegisterInput = { name: string; email: string; password: string; phone?: string };
type Ctx = {
  user: User | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<User>;
  register: (b: RegisterInput) => Promise<User>;
  logout: () => void;
};

const AuthContext = createContext<Ctx>(null!);

export function AuthProvider({ children }: { children: ReactNode }) {
  const { refresh } = useCart();
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(!!auth.token);

  useEffect(() => {
    if (!auth.token) return;
    api.me()
      .then(setUser)
      .catch(() => auth.set(null))
      .finally(() => setLoading(false));
  }, []);

  const signIn = async (token: string, u: User) => {
    auth.set(token);
    setUser(u);
    if (u.role === "CUSTOMER") {
      await api.mergeCart().catch(() => undefined);
      await refresh().catch(() => undefined);
    }
    return u;
  };

  const value: Ctx = {
    user,
    loading,
    login: async (email, password) => {
      const r = await api.login(email, password);
      return signIn(r.token, r.user);
    },
    register: async (b) => {
      const r = await api.register(b);
      return signIn(r.token, r.user);
    },
    logout: () => {
      auth.set(null);
      setUser(null);
      refresh().catch(() => undefined);
    },
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export const useAuth = () => useContext(AuthContext);
'@

Write-ProjectFile 'src\context\CartContext.tsx' @'
import { createContext, useContext, useEffect, useState, ReactNode } from "react";
import { api } from "../api/client";
import type { Cart } from "../api/types";

type Ctx = {
  cart: Cart | null; count: number;
  add: (items: { productId: string; qty: number }[]) => Promise<void>;
  setQty: (productId: string, qty: number) => Promise<void>;
  remove: (productId: string) => Promise<void>;
  refresh: () => Promise<void>;
};
const CartContext = createContext<Ctx>(null!);

export function CartProvider({ children }: { children: ReactNode }) {
  const [cart, setCart] = useState<Cart | null>(null);
  const refresh = async () => setCart(await api.cart());
  useEffect(() => { refresh().catch(console.error); }, []);

  const value: Ctx = {
    cart,
    count: cart?.items.reduce((s, i) => s + i.qty, 0) ?? 0,
    add: async (items) => setCart(await api.addToCart(items)),
    setQty: async (id, qty) => setCart(await api.setQty(id, qty)),
    remove: async (id) => setCart(await api.removeItem(id)),
    refresh,
  };
  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}
export const useCart = () => useContext(CartContext);
'@

Write-ProjectFile 'src\main.tsx' @'
import React from "react";
import ReactDOM from "react-dom/client";
import { BrowserRouter } from "react-router-dom";
import App from "./App";
import { CartProvider } from "./context/CartContext";
import { AuthProvider } from "./context/AuthContext";
import "./styles.css";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <BrowserRouter>
      <CartProvider>
        <AuthProvider>
          <App />
        </AuthProvider>
      </CartProvider>
    </BrowserRouter>
  </React.StrictMode>
);
'@

Write-ProjectFile 'src\pages\BuildLook.tsx' @'
import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "../api/client";
import type { Product } from "../api/types";
import { lkr } from "../components/ProductCard";
import { useCart } from "../context/CartContext";

const steps = [
  { title: "Choose earrings", category: "earrings" },
  { title: "Choose a necklace", category: "necklaces" },
  { title: "Choose bangles", category: "bangles" },
];

export default function BuildLook() {
  const nav = useNavigate();
  const { add } = useCart();
  const [step, setStep] = useState(0);
  const [options, setOptions] = useState<Product[]>([]);
  const [picked, setPicked] = useState<Record<number, Product | undefined>>({});

  useEffect(() => {
    if (step < steps.length) api.products({ category: steps[step].category, inStock: 1 }).then((r) => setOptions(r.items.filter((p) => p.tryOnEnabled)));
  }, [step]);

  const chosen = Object.values(picked).filter(Boolean) as Product[];
  const total = chosen.reduce((s, p) => s + p.price, 0);

  if (step >= steps.length) return (
    <section>
      <h1>Your look</h1>
      <ul>{chosen.map((p) => <li key={p.id}>{p.name} — {lkr(p.price)}</li>)}</ul>
      <p>Total: {lkr(total)}</p>
      <div className="row">
        <button className="ghost" onClick={() => setStep(0)}>Change items</button>
        <button disabled={!chosen.length} onClick={() => nav(`/try-on?products=${chosen.map((p) => p.id).join(",")}`)}>Preview with AI</button>
        <button disabled={!chosen.length} onClick={async () => { await add(chosen.map((p) => ({ productId: p.id, qty: 1 }))); nav("/cart"); }}>Add all to cart</button>
      </div>
    </section>
  );

  return (
    <section>
      <p>Step {step + 1} of {steps.length}</p>
      <h1>{steps[step].title}</h1>
      <div className="grid">
        {options.map((p) => (
          <button key={p.id} className={`ghost ${picked[step]?.id === p.id ? "selected" : ""}`}
            onClick={() => setPicked({ ...picked, [step]: picked[step]?.id === p.id ? undefined : p })}>
            <img src={p.images[0]?.url} alt="" width="100%" />
            {p.name}<br />{lkr(p.price)}
          </button>
        ))}
      </div>
      <div className="row">
        {step > 0 && <button className="ghost" onClick={() => setStep(step - 1)}>Back</button>}
        <button onClick={() => setStep(step + 1)}>{picked[step] ? "Next" : "Skip"}</button>
      </div>
    </section>
  );
}
'@

Write-ProjectFile 'src\pages\Cart.tsx' @'
import { Link } from "react-router-dom";
import { useCart } from "../context/CartContext";
import { lkr } from "../components/ProductCard";

export const DELIVERY_FEE = 450;

export default function CartPage() {
  const { cart, setQty, remove } = useCart();
  if (!cart?.items.length) return <p>Your cart is empty. <Link to="/shop">Browse jewellery</Link></p>;
  return (
    <section>
      <h1>My cart</h1>
      <table>
        <tbody>
          {cart.items.map((i) => (
            <tr key={i.id}>
              <td><img src={i.product.images[0]?.url} width={64} alt="" /></td>
              <td>{i.product.name}</td>
              <td>{lkr(i.product.price)}</td>
              <td>
                <input type="number" min={1} max={i.product.stock} value={i.qty} style={{ width: 70 }}
                  onChange={(e) => setQty(i.productId, Math.max(1, +e.target.value))} />
              </td>
              <td>{lkr(i.product.price * i.qty)}</td>
              <td><button className="ghost" onClick={() => remove(i.productId)}>Remove</button></td>
            </tr>
          ))}
        </tbody>
      </table>
      <p>Subtotal: {lkr(cart.subtotal)}</p>
      <p>Delivery: {lkr(DELIVERY_FEE)} (free for store pickup)</p>
      <h2>Total: {lkr(cart.subtotal + DELIVERY_FEE)}</h2>
      <Link to="/checkout"><button>Checkout</button></Link>
    </section>
  );
}
'@

Write-ProjectFile 'src\pages\Checkout.tsx' @'
import { FormEvent, useState } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "../api/client";
import { useCart } from "../context/CartContext";
import { lkr } from "../components/ProductCard";
import { DELIVERY_FEE } from "./Cart";

export default function Checkout() {
  const nav = useNavigate();
  const { cart, refresh } = useCart();
  const [delivery, setDelivery] = useState<"DELIVERY" | "PICKUP">("DELIVERY");
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  const submit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setBusy(true); setErr("");
    const body = Object.fromEntries(new FormData(e.currentTarget));
    try {
      const order = await api.placeOrder(body);
      await refresh();
      nav(`/order/${order.orderNo}`, { state: order });
    } catch (e) { setErr((e as Error).message); } finally { setBusy(false); }
  };

  const fee = delivery === "DELIVERY" ? DELIVERY_FEE : 0;
  return (
    <form onSubmit={submit}>
      <h1>Checkout</h1>
      <h2>Your details</h2>
      <label>Full name *<input name="fullName" required /></label>
      <label>Mobile number *<input name="mobile" required pattern="0\d{9}" placeholder="07XXXXXXXX" /></label>
      <label>WhatsApp number<input name="whatsapp" /></label>
      <label>Email<input name="email" type="email" /></label>

      <h2>Delivery</h2>
      <label className="row"><input type="radio" name="deliveryMethod" value="DELIVERY" checked={delivery === "DELIVERY"} onChange={() => setDelivery("DELIVERY")} /> Delivery</label>
      <label className="row"><input type="radio" name="deliveryMethod" value="PICKUP" checked={delivery === "PICKUP"} onChange={() => setDelivery("PICKUP")} /> Store pickup</label>
      {delivery === "DELIVERY" && (
        <>
          <label>Address *<textarea name="address" required /></label>
          <label>City *<input name="city" required /></label>
          <label>Postal code<input name="postalCode" /></label>
        </>
      )}
      <label>Order note<textarea name="note" /></label>

      <h2>Payment</h2>
      <label className="row"><input type="radio" name="paymentMethod" value="BANK_TRANSFER" defaultChecked /> Bank transfer</label>
      <label className="row"><input type="radio" name="paymentMethod" value="COD" /> Cash on delivery</label>
      <label className="row"><input type="radio" name="paymentMethod" value="ONLINE" /> Online payment</label>

      <h2>Total: {lkr((cart?.subtotal ?? 0) + fee)}</h2>
      {err && <p className="error">{err}</p>}
      <button disabled={busy || !cart?.items.length}>{busy ? "Placing order…" : "Place order"}</button>
    </form>
  );
}
'@

Write-ProjectFile 'src\pages\Home.tsx' @'
import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../api/client";
import type { Category, Product } from "../api/types";
import ProductCard from "../components/ProductCard";

export default function Home() {
  const [cats, setCats] = useState<Category[]>([]);
  const [fresh, setFresh] = useState<Product[]>([]);
  useEffect(() => {
    api.categories().then(setCats);
    api.products({ newArrivals: 1, limit: 8 }).then((r) => setFresh(r.items));
  }, []);
  return (
    <>
      <section className="hero">
        <h1>Discover your perfect jewellery</h1>
        <p>Earrings, bangles, chains, necklaces, rings and more — see them on before you buy.</p>
        <Link to="/shop"><button>Shop now</button></Link>
      </section>
      <h2>Categories</h2>
      <div className="grid">
        {cats.map((c) => <Link key={c.id} to={`/shop/${c.slug}`} className="card">{c.name}</Link>)}
      </div>
      <h2>New arrivals</h2>
      <div className="grid">{fresh.map((p) => <ProductCard key={p.id} p={p} />)}</div>
    </>
  );
}
'@

Write-ProjectFile 'src\pages\Login.tsx' @'
import { FormEvent, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import AuthShell from "../components/AuthShell";
import PasswordInput from "../components/PasswordInput";

export default function Login() {
  const { login } = useAuth();
  const nav = useNavigate();
  const from = (useLocation().state as { from?: string } | null)?.from ?? "/";
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  const submit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    setBusy(true); setErr("");
    try {
      const u = await login(String(f.get("email")), String(f.get("password")));
      nav(u.role === "ADMIN" ? "/admin" : from, { replace: true });
    } catch (e) {
      setErr((e as Error).message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <AuthShell
      title="Sign in"
      subtitle="Welcome back. Sign in to see your orders and saved try-ons."
      aside={<><h2>See it on before you buy</h2><p>Try any piece on a model or your own photo, then order in a few taps.</p></>}
    >
      <form onSubmit={submit} className="form" noValidate={false}>
        <label className="field">
          <span className="field-label">Email</span>
          <input name="email" type="email" required autoComplete="email" />
        </label>
        <PasswordInput name="password" label="Password" autoComplete="current-password" />
        {err && <p className="form-error" role="alert">{err}</p>}
        <button className="btn btn-primary btn-block" disabled={busy}>{busy ? "Signing in…" : "Sign in"}</button>
      </form>
      <p className="auth-switch">New here? <Link to="/register" state={{ from }}>Create an account</Link></p>
      <p className="auth-switch"><Link to="/">Continue as guest</Link></p>
    </AuthShell>
  );
}
'@

Write-ProjectFile 'src\pages\OrderConfirmation.tsx' @'
import { Link, useLocation, useParams } from "react-router-dom";
import type { Order } from "../api/types";
import { lkr } from "../components/ProductCard";

const SHOP_WHATSAPP = "94770000000";

export default function OrderConfirmation() {
  const { orderNo } = useParams();
  const order = useLocation().state as Order | undefined;
  return (
    <section>
      <h1>Order placed</h1>
      <p>Thank you for your order. Your order number is <strong>#{orderNo}</strong>.</p>
      {order && (
        <>
          <ul>{order.items.map((i) => <li key={i.id}>{i.name} × {i.qty}</li>)}</ul>
          <p>Total: {lkr(order.total)}</p>
        </>
      )}
      <div className="row">
        <Link to={`/track?orderNo=${orderNo}`}><button>Track order</button></Link>
        <a href={`https://wa.me/${SHOP_WHATSAPP}?text=${encodeURIComponent(`Hi, about my order #${orderNo}`)}`} target="_blank" rel="noreferrer">
          <button className="ghost">Contact via WhatsApp</button>
        </a>
      </div>
    </section>
  );
}
'@

Write-ProjectFile 'src\pages\ProductDetails.tsx' @'
import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { api } from "../api/client";
import type { Product } from "../api/types";
import { useCart } from "../context/CartContext";
import { lkr } from "../components/ProductCard";

export default function ProductDetails() {
  const { slug } = useParams();
  const nav = useNavigate();
  const { add } = useCart();
  const [p, setP] = useState<Product | null>(null);
  const [img, setImg] = useState(0);
  const [qty, setQty] = useState(1);
  const [msg, setMsg] = useState("");

  useEffect(() => { api.product(slug!).then(setP).catch(() => setMsg("Product not found")); }, [slug]);
  if (!p) return <p>{msg || "Loading…"}</p>;

  const addToCart = async () => {
    try { await add([{ productId: p.id, qty }]); setMsg("Added to cart"); } catch (e) { setMsg((e as Error).message); }
  };

  return (
    <div className="grid">
      <div>
        <img src={p.images[img]?.url} alt={p.name} style={{ width: "100%" }} />
        <div className="row">{p.images.map((im, i) => <img key={im.id} src={im.url} width={64} onClick={() => setImg(i)} className={i === img ? "selected" : ""} />)}</div>
      </div>
      <div>
        <h1>{p.name}</h1>
        <p>Product code: {p.code}</p>
        <h2>{lkr(p.price)}</h2>
        <p>{p.stock > 0 ? "Available" : "Sold out"}</p>
        <p>{p.description}</p>
        <div className="row">
          <button className="ghost" onClick={() => setQty(Math.max(1, qty - 1))}>−</button>
          <span>{qty}</span>
          <button className="ghost" onClick={() => setQty(Math.min(p.stock, qty + 1))}>+</button>
        </div>
        <div className="row">
          <button disabled={!p.stock} onClick={addToCart}>Add to cart</button>
          {p.tryOnEnabled && <button className="ghost" onClick={() => nav(`/try-on?products=${p.id}`)}>Try it with AI</button>}
        </div>
        {msg && <p role="status">{msg}</p>}
      </div>
    </div>
  );
}
'@

Write-ProjectFile 'src\pages\Register.tsx' @'
import { FormEvent, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import AuthShell from "../components/AuthShell";
import PasswordInput from "../components/PasswordInput";

export default function Register() {
  const { register } = useAuth();
  const nav = useNavigate();
  const from = (useLocation().state as { from?: string } | null)?.from ?? "/";
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  const submit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    setBusy(true); setErr("");
    try {
      await register({
        name: String(f.get("name")),
        email: String(f.get("email")),
        phone: String(f.get("phone") || "") || undefined,
        password: String(f.get("password")),
      });
      nav(from, { replace: true });
    } catch (e) {
      setErr((e as Error).message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <AuthShell
      title="Create your account"
      subtitle="Track orders, keep a wishlist and save your AI try-ons."
      aside={<><h2>Your jewellery, your way</h2><p>Mix earrings, necklaces and bangles into a full look, and see it on before you order.</p></>}
    >
      <form onSubmit={submit} className="form">
        <label className="field">
          <span className="field-label">Full name</span>
          <input name="name" required minLength={2} autoComplete="name" />
        </label>
        <label className="field">
          <span className="field-label">Email</span>
          <input name="email" type="email" required autoComplete="email" />
        </label>
        <label className="field">
          <span className="field-label">Mobile number <span className="optional">(optional)</span></span>
          <input name="phone" type="tel" placeholder="07XXXXXXXX" pattern="0\d{9}" autoComplete="tel" />
        </label>
        <PasswordInput name="password" label="Password" autoComplete="new-password" minLength={6} hint="At least 6 characters" />
        {err && <p className="form-error" role="alert">{err}</p>}
        <button className="btn btn-primary btn-block" disabled={busy}>{busy ? "Creating account…" : "Create account"}</button>
      </form>
      <p className="auth-switch">Already have an account? <Link to="/login" state={{ from }}>Sign in</Link></p>
    </AuthShell>
  );
}
'@

Write-ProjectFile 'src\pages\Shop.tsx' @'
import { useEffect, useState } from "react";
import { useParams, useSearchParams } from "react-router-dom";
import { api } from "../api/client";
import type { Paged, Product } from "../api/types";
import ProductCard from "../components/ProductCard";

export default function Shop() {
  const { category } = useParams();
  const [sp, setSp] = useSearchParams();
  const [data, setData] = useState<Paged<Product>>({ items: [], total: 0 });

  useEffect(() => {
    api.products({ category, ...Object.fromEntries(sp) }).then(setData);
  }, [category, sp]);

  const set = (k: string, v: string) => { const n = new URLSearchParams(sp); v ? n.set(k, v) : n.delete(k); n.delete("page"); setSp(n); };

  return (
    <>
      <div className="row">
        <input placeholder="Search by name or code" defaultValue={sp.get("q") ?? ""} onKeyDown={(e) => e.key === "Enter" && set("q", e.currentTarget.value)} />
        <input type="number" placeholder="Min price" onBlur={(e) => set("minPrice", e.target.value)} />
        <input type="number" placeholder="Max price" onBlur={(e) => set("maxPrice", e.target.value)} />
        <select value={sp.get("sort") ?? "new"} onChange={(e) => set("sort", e.target.value)}>
          <option value="new">Newest</option><option value="price_asc">Price: low to high</option><option value="price_desc">Price: high to low</option>
        </select>
        <label className="row"><input type="checkbox" checked={!!sp.get("inStock")} onChange={(e) => set("inStock", e.target.checked ? "1" : "")} /> In stock only</label>
      </div>
      <p>{data.total} items</p>
      <div className="grid">{data.items.map((p) => <ProductCard key={p.id} p={p} />)}</div>
      {!data.items.length && <p>No items match these filters. Clear a filter to see more.</p>}
      <div className="row">
        {Array.from({ length: data.pages ?? 1 }, (_, i) => (
          <button key={i} className={data.page === i + 1 ? "" : "ghost"} onClick={() => set("page", String(i + 1))}>{i + 1}</button>
        ))}
      </div>
    </>
  );
}
'@

Write-ProjectFile 'src\pages\TrackOrder.tsx' @'
import { FormEvent, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { api } from "../api/client";
import type { Order } from "../api/types";
import { lkr } from "../components/ProductCard";

const stages = ["PENDING", "CONFIRMED", "PROCESSING", "READY", "DISPATCHED", "DELIVERED"];

export default function TrackOrder() {
  const [sp] = useSearchParams();
  const [order, setOrder] = useState<Order | null>(null);
  const [err, setErr] = useState("");

  const submit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    try { setErr(""); setOrder(await api.trackOrder(String(f.get("orderNo")), String(f.get("mobile")))); }
    catch (e) { setErr((e as Error).message); setOrder(null); }
  };

  return (
    <section>
      <h1>Track your order</h1>
      <form onSubmit={submit}>
        <label>Order number<input name="orderNo" defaultValue={sp.get("orderNo") ?? ""} required /></label>
        <label>Mobile number<input name="mobile" required /></label>
        <button>Track order</button>
      </form>
      {err && <p className="error">{err}</p>}
      {order && (
        <>
          <h2>#{order.orderNo} — {lkr(order.total)}</h2>
          {order.status === "CANCELLED" ? <p>This order was cancelled.</p> : (
            <ol>{stages.map((s) => <li key={s} style={{ fontWeight: s === order.status ? 700 : 400 }}>{s.toLowerCase()}</li>)}</ol>
          )}
        </>
      )}
    </section>
  );
}
'@

Write-ProjectFile 'src\pages\TryOn.tsx' @'
import { useEffect, useRef, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { api } from "../api/client";
import type { AiModel, TryOnJob } from "../api/types";
import { useCart } from "../context/CartContext";

// Reusable: /try-on?products=id1,id2,id3  (single product or a Build Your Look set)
export default function TryOn() {
  const [sp] = useSearchParams();
  const productIds = (sp.get("products") ?? "").split(",").filter(Boolean);
  const { add } = useCart();

  const [mode, setMode] = useState<"AI_MODEL" | "UPLOAD" | null>(null);
  const [models, setModels] = useState<AiModel[]>([]);
  const [modelId, setModelId] = useState<string>();
  const [photo, setPhoto] = useState<File>();
  const [job, setJob] = useState<TryOnJob | null>(null);
  const [err, setErr] = useState("");
  const timer = useRef<number>();

  useEffect(() => { if (mode === "AI_MODEL") api.aiModels().then(setModels); }, [mode]);
  useEffect(() => () => clearInterval(timer.current), []);

  const generate = async () => {
    setErr("");
    const fd = new FormData();
    fd.append("productIds", JSON.stringify(productIds));
    fd.append("source", mode!);
    if (mode === "AI_MODEL" && modelId) fd.append("aiModelId", modelId);
    if (mode === "UPLOAD" && photo) fd.append("photo", photo);
    try {
      const j = await api.startTryOn(fd);
      setJob(j);
      timer.current = window.setInterval(async () => {
        const s = await api.tryOnStatus(j.id);
        setJob(s);
        if (s.status === "DONE" || s.status === "FAILED") clearInterval(timer.current);
      }, 2000);
    } catch (e) { setErr((e as Error).message); }
  };

  const reset = () => { setJob(null); setPhoto(undefined); };

  if (!productIds.length) return <p>Choose a product first, then select “Try with AI”.</p>;

  if (job) return (
    <section>
      <h1>Your preview</h1>
      {(job.status === "PENDING" || job.status === "PROCESSING") && <p role="status">Generating your preview…</p>}
      {job.status === "FAILED" && <p className="error">{job.error}</p>}
      {job.status === "DONE" && (
        <>
          <img src={job.resultUrl} alt="Try-on preview" style={{ maxWidth: 480, width: "100%" }} />
          <div className="row">
            <a href={job.resultUrl} download><button className="ghost">Save</button></a>
            <button className="ghost" onClick={() => navigator.share?.({ url: job.resultUrl })}>Share</button>
            <button onClick={() => add(productIds.map((productId) => ({ productId, qty: 1 })))}>Add to cart</button>
          </div>
        </>
      )}
      <button className="ghost" onClick={reset}>Try again</button>
    </section>
  );

  return (
    <section>
      <h1>Virtual try-on</h1>
      <div className="row">
        <button className={mode === "AI_MODEL" ? "" : "ghost"} onClick={() => setMode("AI_MODEL")}>Use an AI model</button>
        <button className={mode === "UPLOAD" ? "" : "ghost"} onClick={() => setMode("UPLOAD")}>Upload my photo</button>
      </div>

      {mode === "AI_MODEL" && (
        <div className="grid">
          {models.map((m) => (
            <img key={m.id} src={m.imageUrl} alt={m.name} className={modelId === m.id ? "selected" : ""} onClick={() => setModelId(m.id)} />
          ))}
        </div>
      )}

      {mode === "UPLOAD" && (
        <>
          <input type="file" accept="image/jpeg,image/png,image/webp" onChange={(e) => setPhoto(e.target.files?.[0])} />
          {photo && <img src={URL.createObjectURL(photo)} alt="Your photo" width={240} />}
          <ul><li>Face clearly visible</li><li>Good lighting</li><li>Front-facing photo</li></ul>
        </>
      )}

      {mode && <button disabled={(mode === "AI_MODEL" && !modelId) || (mode === "UPLOAD" && !photo)} onClick={generate}>Generate try-on</button>}
      {err && <p className="error">{err}</p>}
    </section>
  );
}
'@

Write-ProjectFile 'src\pages\admin\AdminLayout.tsx' @'
import { useState } from "react";
import { Link, NavLink, Outlet, useNavigate } from "react-router-dom";
import { useAuth } from "../../context/AuthContext";
import Icon, { IconName } from "../../components/Icon";

const links: { to: string; label: string; icon: IconName; end?: boolean }[] = [
  { to: "/admin", label: "Dashboard", icon: "dashboard", end: true },
  { to: "/admin/orders", label: "Orders", icon: "orders" },
  { to: "/admin/products", label: "Products", icon: "products" },
];

export default function AdminLayout() {
  const { user, logout } = useAuth();
  const nav = useNavigate();
  const [open, setOpen] = useState(false);

  const signOut = () => { logout(); nav("/admin/login", { replace: true }); };

  return (
    <div className="admin-shell">
      <aside className={`admin-side ${open ? "is-open" : ""}`}>
        <Link to="/admin" className="admin-logo">[Shop name]</Link>
        <nav className="admin-nav" aria-label="Admin">
          {links.map((l) => (
            <NavLink key={l.to} to={l.to} end={l.end} onClick={() => setOpen(false)}>
              <Icon name={l.icon} />{l.label}
            </NavLink>
          ))}
        </nav>
        <div className="admin-side-foot">
          <Link to="/" className="admin-side-link"><Icon name="store" />View shop</Link>
          <button className="admin-side-link" onClick={signOut}><Icon name="logout" />Sign out</button>
        </div>
      </aside>

      <div className="admin-main">
        <header className="admin-top">
          <button className="icon-btn admin-menu" aria-label="Open menu" aria-expanded={open} onClick={() => setOpen(!open)}>
            <Icon name="menu" />
          </button>
          <span className="admin-user"><Icon name="user" size={18} />{user?.name}</span>
        </header>
        <div className="admin-content"><Outlet /></div>
      </div>
      {open && <button className="admin-scrim" aria-label="Close menu" onClick={() => setOpen(false)} />}
    </div>
  );
}
'@

Write-ProjectFile 'src\pages\admin\AdminLogin.tsx' @'
import { FormEvent, useState } from "react";
import { Navigate, useNavigate } from "react-router-dom";
import { useAuth } from "../../context/AuthContext";
import AuthShell from "../../components/AuthShell";
import PasswordInput from "../../components/PasswordInput";

export default function AdminLogin() {
  const { user, login, logout } = useAuth();
  const nav = useNavigate();
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  if (user?.role === "ADMIN") return <Navigate to="/admin" replace />;

  const submit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    setBusy(true); setErr("");
    try {
      const u = await login(String(f.get("email")), String(f.get("password")));
      if (u.role !== "ADMIN") {
        logout();
        throw new Error("This account doesn't have admin access.");
      }
      nav("/admin", { replace: true });
    } catch (e) {
      setErr((e as Error).message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <AuthShell
      title="Admin sign in"
      subtitle="Manage products, orders and reports."
      aside={<><h2>Shop admin</h2><p>Confirm orders, update stock and see today's sales in one place.</p></>}
    >
      <form onSubmit={submit} className="form">
        <label className="field">
          <span className="field-label">Email</span>
          <input name="email" type="email" required autoComplete="username" />
        </label>
        <PasswordInput name="password" label="Password" autoComplete="current-password" />
        {err && <p className="form-error" role="alert">{err}</p>}
        <button className="btn btn-primary btn-block" disabled={busy}>{busy ? "Signing in…" : "Sign in"}</button>
      </form>
    </AuthShell>
  );
}
'@

Write-ProjectFile 'src\pages\admin\Dashboard.tsx' @'
import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../../api/client";
import type { DashboardData, OrderStatus } from "../../api/types";
import Icon from "../../components/Icon";

const lkr = (n: number) => `LKR ${n.toLocaleString("en-LK")}`;
const short = (n: number) => (n >= 1000 ? `${Math.round(n / 100) / 10}k` : String(n));

const statusLabel: Record<OrderStatus, string> = {
  PENDING: "Pending", CONFIRMED: "Confirmed", PROCESSING: "Processing", READY: "Ready",
  DISPATCHED: "Dispatched", DELIVERED: "Delivered", CANCELLED: "Cancelled",
};

function SalesChart({ days }: { days: DashboardData["last7Days"] }) {
  const max = Math.max(...days.map((d) => d.sales), 1);
  const total = days.reduce((s, d) => s + d.sales, 0);
  const dayName = (iso: string) => new Date(`${iso}T00:00:00`).toLocaleDateString("en-GB", { weekday: "short" });
  const fullDate = (iso: string) => new Date(`${iso}T00:00:00`).toLocaleDateString("en-GB", { weekday: "long", day: "numeric", month: "short" });

  return (
    <section className="panel chart-panel">
      <div className="panel-head">
        <h2>Sales, last 7 days</h2>
        <span className="panel-meta">{lkr(total)} total</span>
      </div>
      <div className="bars" role="img" aria-label="Daily sales for the last 7 days. Values in the table below.">
        <div className="bars-grid" aria-hidden="true">
          <span>{short(max)}</span>
          <span>{short(Math.round(max / 2))}</span>
          <span>0</span>
        </div>
        {days.map((d, i) => (
          <div key={d.date} className="bar-col" tabIndex={0} aria-label={`${fullDate(d.date)}: ${lkr(d.sales)}, ${d.orders} orders`}>
            <div className="bar-track">
              <div className={`bar ${i === days.length - 1 ? "is-today" : ""}`} style={{ height: `${(d.sales / max) * 100}%` }} />
              <div className="bar-tip" role="tooltip">
                <strong>{lkr(d.sales)}</strong>
                <span>{d.orders} {d.orders === 1 ? "order" : "orders"} · {fullDate(d.date)}</span>
              </div>
            </div>
            <span className="bar-label">{i === days.length - 1 ? "Today" : dayName(d.date)}</span>
          </div>
        ))}
      </div>
      <div className="sr-only">
      <table>
        <caption>Daily sales, last 7 days</caption>
        <thead><tr><th>Day</th><th>Sales</th><th>Orders</th></tr></thead>
        <tbody>{days.map((d) => <tr key={d.date}><td>{fullDate(d.date)}</td><td>{lkr(d.sales)}</td><td>{d.orders}</td></tr>)}</tbody>
      </table>
      </div>
    </section>
  );
}

export default function Dashboard() {
  const [d, setD] = useState<DashboardData | null>(null);
  const [err, setErr] = useState("");

  const load = () => { setErr(""); api.admin.dashboard().then(setD).catch((e) => setErr((e as Error).message)); };
  useEffect(load, []);

  if (err) return (
    <div className="empty">
      <p className="form-error">Couldn't load the dashboard: {err}</p>
      <button className="btn btn-secondary" onClick={load}>Try again</button>
    </div>
  );
  if (!d) return <p className="page-loading" role="status">Loading dashboard…</p>;

  const today = new Date().toLocaleDateString("en-GB", { weekday: "long", day: "numeric", month: "long" });

  return (
    <div className="dash">
      <div className="dash-head">
        <div>
          <h1>Dashboard</h1>
          <p className="muted">{today}</p>
        </div>
        <Link to="/admin/products" className="btn btn-primary">Add product</Link>
      </div>

      <section className="stats" aria-label="Today">
        <div className="stat stat-hero">
          <span className="stat-label">Today's sales</span>
          <span className="stat-value">{lkr(d.todaySales)}</span>
          <span className="stat-note">{d.todayOrders} {d.todayOrders === 1 ? "order" : "orders"} today</span>
        </div>
        <Link to="/admin/orders" className="stat stat-link">
          <span className="stat-label">Waiting to confirm</span>
          <span className="stat-value">{d.pending}</span>
          <span className="stat-note">{d.pending ? "Review pending orders" : "All caught up"}</span>
        </Link>
        <div className="stat">
          <span className="stat-label">In progress</span>
          <span className="stat-value">{d.processing}</span>
          <span className="stat-note">Confirmed to dispatched</span>
        </div>
        <div className="stat">
          <span className="stat-label">Delivered today</span>
          <span className="stat-value">{d.completed}</span>
          <span className="stat-note">Completed orders</span>
        </div>
      </section>

      <div className="dash-grid">
        <SalesChart days={d.last7Days} />

        <section className="panel">
          <div className="panel-head">
            <h2>Low stock</h2>
            <Link to="/admin/products" className="panel-link">Manage products</Link>
          </div>
          {d.lowStock.length ? (
            <ul className="stock-list">
              {d.lowStock.map((p) => (
                <li key={p.id}>
                  <span className="stock-name">{p.name}<span className="muted">{p.code}</span></span>
                  <span className={`stock-count ${p.stock === 0 ? "is-out" : ""}`}>
                    {p.stock === 0 ? <><Icon name="alert" size={14} />Sold out</> : `${p.stock} left`}
                  </span>
                </li>
              ))}
            </ul>
          ) : <p className="empty-note">Every product has more than 3 in stock.</p>}
        </section>

        <section className="panel panel-wide">
          <div className="panel-head">
            <h2>Recent orders</h2>
            <Link to="/admin/orders" className="panel-link">All orders</Link>
          </div>
          {d.recentOrders.length ? (
            <div className="table-scroll">
              <table className="table">
                <thead><tr><th>Order</th><th>Customer</th><th>Total</th><th>Status</th><th>Placed</th></tr></thead>
                <tbody>
                  {d.recentOrders.map((o) => (
                    <tr key={o.id}>
                      <td><Link to={`/admin/orders/${o.id}`}>#{o.orderNo}</Link></td>
                      <td>{o.fullName}</td>
                      <td className="num">{lkr(o.total)}</td>
                      <td><span className={`pill pill-${o.status.toLowerCase()}`}>{statusLabel[o.status]}</span></td>
                      <td className="muted">{new Date(o.createdAt).toLocaleString("en-GB", { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" })}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : <p className="empty-note">No orders yet. New orders from the shop appear here.</p>}
        </section>
      </div>
    </div>
  );
}
'@

Write-ProjectFile 'src\pages\admin\OrderDetail.tsx' @'
import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import { api } from "../../api/client";
import type { Order, OrderStatus } from "../../api/types";
import { lkr } from "../../components/ProductCard";

const next: Record<OrderStatus, { to: OrderStatus; label: string }[]> = {
  PENDING: [{ to: "CONFIRMED", label: "Confirm order" }, { to: "CANCELLED", label: "Cancel order" }],
  CONFIRMED: [{ to: "PROCESSING", label: "Start processing" }, { to: "CANCELLED", label: "Cancel order" }],
  PROCESSING: [{ to: "READY", label: "Mark ready" }, { to: "CANCELLED", label: "Cancel order" }],
  READY: [{ to: "DISPATCHED", label: "Mark dispatched" }, { to: "DELIVERED", label: "Mark picked up" }],
  DISPATCHED: [{ to: "DELIVERED", label: "Mark delivered" }],
  DELIVERED: [], CANCELLED: [],
};

export default function AdminOrderDetail() {
  const { id } = useParams();
  const [o, setO] = useState<Order | null>(null);
  const [err, setErr] = useState("");
  const load = () => api.admin.order(id!).then(setO);
  useEffect(() => { load(); }, [id]);
  if (!o) return <p>Loading…</p>;

  const move = async (to: OrderStatus) => {
    if (to === "CANCELLED" && !confirm("Cancel this order? Stock will be returned.")) return;
    try { setErr(""); await api.admin.setStatus(o.id, to); await load(); } catch (e) { setErr((e as Error).message); }
  };

  return (
    <section>
      <h1>#{o.orderNo}</h1>
      <p><strong>{o.fullName}</strong> · <a href={`tel:${o.mobile}`}>{o.mobile}</a></p>
      <table><tbody>{o.items.map((i) => <tr key={i.id}><td>{i.name}</td><td>× {i.qty}</td><td>{lkr(i.price * i.qty)}</td></tr>)}</tbody></table>
      <p>Subtotal {lkr(o.subtotal)} + delivery {lkr(o.deliveryFee)} = <strong>{lkr(o.total)}</strong></p>
      <p>Payment: {o.paymentMethod.replace("_", " ").toLowerCase()} ({o.paymentStatus.toLowerCase()})</p>
      <p>Delivery: {o.deliveryMethod === "PICKUP" ? "store pickup" : o.city}</p>
      <p>Status: <strong>{o.status.toLowerCase()}</strong></p>
      <div className="row">{next[o.status].map((n) => <button key={n.to} className={n.to === "CANCELLED" ? "ghost" : ""} onClick={() => move(n.to)}>{n.label}</button>)}</div>
      {err && <p className="error">{err}</p>}
    </section>
  );
}
'@

Write-ProjectFile 'src\pages\admin\Orders.tsx' @'
import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../../api/client";
import type { Order, OrderStatus } from "../../api/types";
import { lkr } from "../../components/ProductCard";

const filters: (OrderStatus | "")[] = ["", "PENDING", "CONFIRMED", "PROCESSING", "READY", "DISPATCHED", "DELIVERED", "CANCELLED"];

export default function AdminOrders() {
  const [status, setStatus] = useState<OrderStatus | "">("PENDING");
  const [q, setQ] = useState("");
  const [orders, setOrders] = useState<Order[]>([]);
  useEffect(() => { api.admin.orders({ status, q }).then((r) => setOrders(r.items)); }, [status, q]);

  return (
    <section>
      <h1>Orders</h1>
      <div className="row">
        {filters.map((f) => <button key={f} className={status === f ? "" : "ghost"} onClick={() => setStatus(f)}>{f ? f.toLowerCase() : "all"}</button>)}
        <input placeholder="Order no, name or mobile" onKeyDown={(e) => e.key === "Enter" && setQ(e.currentTarget.value)} />
      </div>
      <table>
        <thead><tr><th>Order</th><th>Customer</th><th>Total</th><th>Status</th><th>Date</th></tr></thead>
        <tbody>
          {orders.map((o) => (
            <tr key={o.id}>
              <td><Link to={`/admin/orders/${o.id}`}>#{o.orderNo}</Link></td>
              <td>{o.fullName}</td><td>{lkr(o.total)}</td><td>{o.status.toLowerCase()}</td>
              <td>{new Date(o.createdAt).toLocaleString()}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </section>
  );
}
'@

Write-ProjectFile 'src\pages\admin\Products.tsx' @'
import { FormEvent, useEffect, useState } from "react";
import { api } from "../../api/client";
import type { Category, Product, JewelleryType } from "../../api/types";
import { lkr } from "../../components/ProductCard";

const types: JewelleryType[] = ["EARRINGS", "NECKLACE", "CHAIN", "LONG_CHAIN", "BANGLE", "BRACELET", "RING", "ANKLET", "HAIR", "OTHER"];

export default function AdminProducts() {
  const [items, setItems] = useState<Product[]>([]);
  const [cats, setCats] = useState<Category[]>([]);
  const [editing, setEditing] = useState<Product | null | "new">(null);
  const [msg, setMsg] = useState("");

  const load = () => api.products({ limit: 60 }).then((r) => setItems(r.items));
  useEffect(() => { load(); api.categories().then(setCats); }, []);

  const save = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);
    fd.set("tryOnEnabled", fd.get("tryOnEnabled") ? "true" : "");
    fd.set("isNewArrival", fd.get("isNewArrival") ? "true" : "");
    try {
      await api.admin.saveProduct(fd, editing !== "new" ? editing?.id : undefined);
      setMsg("Product saved"); setEditing(null); load();
    } catch (e) { setMsg((e as Error).message); }
  };

  if (editing) {
    const p = editing === "new" ? undefined : editing;
    return (
      <form onSubmit={save}>
        <h1>{p ? "Edit product" : "Add product"}</h1>
        <label>Product name<input name="name" defaultValue={p?.name} required /></label>
        <label>Product code<input name="code" defaultValue={p?.code} required /></label>
        <label>Category
          <select name="categoryId" defaultValue={p?.category?.id} required>{cats.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}</select>
        </label>
        <label>Price (LKR)<input name="price" type="number" defaultValue={p?.price} required /></label>
        <label>Stock<input name="stock" type="number" defaultValue={p?.stock ?? 1} /></label>
        <label>Description<textarea name="description" defaultValue={p?.description} /></label>
        <label>Product images<input name="images" type="file" accept="image/*" multiple /></label>
        <label>Jewellery type
          <select name="jewelleryType" defaultValue={p?.jewelleryType ?? "EARRINGS"}>{types.map((t) => <option key={t}>{t}</option>)}</select>
        </label>
        <label className="row"><input type="checkbox" name="tryOnEnabled" defaultChecked={p?.tryOnEnabled ?? true} /> AI try-on enabled</label>
        <label>Try-on image (transparent PNG, optional)<input name="tryOnAsset" type="file" accept="image/png" /></label>
        <label className="row"><input type="checkbox" name="isNewArrival" /> Show in new arrivals</label>
        <div className="row"><button className="ghost" type="button" onClick={() => setEditing(null)}>Cancel</button><button>Save product</button></div>
        {msg && <p>{msg}</p>}
      </form>
    );
  }

  return (
    <section>
      <div className="row"><h1>Products</h1><button onClick={() => setEditing("new")}>Add product</button></div>
      {msg && <p role="status">{msg}</p>}
      <table>
        <thead><tr><th>Code</th><th>Name</th><th>Price</th><th>Stock</th><th>Try-on</th><th /></tr></thead>
        <tbody>
          {items.map((p) => (
            <tr key={p.id}>
              <td>{p.code}</td><td>{p.name}</td><td>{lkr(p.price)}</td><td>{p.stock}</td><td>{p.tryOnEnabled ? "On" : "Off"}</td>
              <td className="row">
                <button className="ghost" onClick={() => api.product(p.slug).then(setEditing)}>Edit</button>
                <button className="ghost" onClick={async () => { if (confirm(`Hide ${p.name} from the shop?`)) { await api.admin.deleteProduct(p.id); load(); } }}>Hide</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </section>
  );
}
'@

Write-ProjectFile 'src\styles.css' @'
/* ---------- Tokens ---------- */
:root {
  --plum: #3b1426;
  --plum-2: #5a2340;
  --plum-soft: #8c5c77;
  --plum-deep: #2a0e1b;
  --gold: #c9a24a;
  --gold-deep: #8a6a24;
  --pearl: #f5f2f5;
  --tint: #ebe3ea;
  --surface: #ffffff;
  --ink: #221a20;
  --muted: #5e5360;
  --line: #e4dce2;
  --error: #a4262c;
  --error-bg: #fbeaeb;
  --radius: 14px;
  --font-body: Manrope, system-ui, sans-serif;
  --font-display: "Bodoni Moda", Georgia, serif;
  font-family: var(--font-body);
  color: var(--ink);
  background: var(--pearl);
}
* { box-sizing: border-box; }
body { margin: 0; background: var(--pearl); color: var(--ink); }
a { color: var(--plum); }
a:hover { color: var(--plum-2); }
h1, h2 { font-family: var(--font-display); font-weight: 500; }
:focus-visible { outline: 2px solid var(--gold-deep); outline-offset: 2px; }
.muted { color: var(--muted); }
.sr-only { position: absolute; width: 1px; height: 1px; padding: 0; margin: -1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; border: 0; }
.page-loading { padding: 48px; text-align: center; color: var(--muted); }

/* ---------- Shared (existing pages) ---------- */
main { max-width: 1200px; margin: 0 auto; padding: 24px 16px; }
.nav { display: flex; gap: 24px; align-items: center; padding: 16px 24px; background: var(--surface); border-bottom: 1px solid var(--line); flex-wrap: wrap; }
.nav nav { display: flex; gap: 20px; flex: 1; flex-wrap: wrap; }
.nav a { color: var(--ink); text-decoration: none; font-weight: 500; }
.nav a.active { color: var(--plum); font-weight: 700; }
.nav-actions { display: flex; gap: 16px; align-items: center; }
.logo { font-family: var(--font-display); font-weight: 600; font-size: 1.4rem; color: var(--plum) !important; }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 20px; }
.card img { width: 100%; aspect-ratio: 1; object-fit: cover; background: var(--tint); border-radius: 10px; }
.row { display: flex; gap: 8px; flex-wrap: wrap; align-items: center; }
button { padding: 10px 16px; border: 1px solid var(--plum); background: var(--plum); color: #fff; border-radius: 22px; font: inherit; font-weight: 600; cursor: pointer; }
button.ghost { background: transparent; color: var(--plum); }
button:disabled { opacity: .5; cursor: not-allowed; }
input, select, textarea { padding: 10px 12px; border: 1px solid #cfc3cc; border-radius: 10px; width: 100%; font: inherit; background: var(--surface); color: var(--ink); }
label { display: grid; gap: 4px; margin-bottom: 12px; }
.error { color: var(--error); }
.selected { outline: 3px solid var(--gold); }
table { width: 100%; border-collapse: collapse; }
td, th { padding: 10px 8px; border-bottom: 1px solid var(--line); text-align: left; }

/* ---------- Buttons ---------- */
.btn { display: inline-flex; align-items: center; justify-content: center; gap: 8px; min-height: 48px; padding: 0 24px; border-radius: 24px; border: 1.5px solid transparent; font: inherit; font-size: 15px; font-weight: 700; text-decoration: none; cursor: pointer; }
.btn-primary { background: var(--plum); color: #fff; border-color: var(--plum); }
.btn-primary:hover { background: var(--plum-2); color: #fff; }
.btn-secondary { background: var(--surface); color: var(--plum); border-color: var(--plum); }
.btn-block { width: 100%; }
.btn-link { padding: 0; border: 0; background: none; color: var(--plum); font-weight: 600; text-decoration: underline; border-radius: 0; }
.icon-btn { width: 44px; height: 44px; padding: 0; display: inline-flex; align-items: center; justify-content: center; border: 0; border-radius: 22px; background: transparent; color: var(--ink); }
.icon-btn:hover { background: var(--tint); }

/* ---------- Forms ---------- */
.form { display: flex; flex-direction: column; gap: 18px; }
.field { display: flex; flex-direction: column; gap: 6px; margin: 0; }
.field-label { font-size: 14px; font-weight: 600; }
.field input { height: 48px; padding: 0 14px; border: 1px solid #cfc3cc; border-radius: 12px; font-size: 16px; }
.field input:focus { border-color: var(--plum); outline: 2px solid var(--plum); outline-offset: 0; }
.field-hint, .optional { font-size: 13px; color: var(--muted); font-weight: 400; }
.input-wrap { position: relative; display: block; }
.input-wrap input { padding-right: 52px; }
.input-icon { position: absolute; right: 2px; top: 2px; width: 44px; height: 44px; padding: 0; display: flex; align-items: center; justify-content: center; border: 0; border-radius: 10px; background: transparent; color: var(--muted); }
.input-icon:hover { color: var(--plum); }
.form-error { margin: 0; padding: 12px 14px; border-radius: 10px; background: var(--error-bg); color: var(--error); font-size: 14px; font-weight: 600; }

/* ---------- Auth pages ---------- */
.auth { min-height: 100vh; display: grid; grid-template-columns: minmax(0, 5fr) minmax(0, 6fr); background: var(--pearl); }
.auth-aside { display: flex; flex-direction: column; justify-content: space-between; padding: 48px 56px; background: var(--plum); color: #eadce4; }
.auth-logo { font-family: var(--font-display); font-size: 28px; font-weight: 600; color: #fff !important; text-decoration: none; }
.auth-aside-body { max-width: 420px; }
.auth-aside-body h2 { margin: 0 0 16px; font-size: 48px; line-height: 1.05; color: #fff; }
.auth-aside-body p { margin: 0; font-size: 17px; line-height: 1.6; }
.auth-main { max-width: none; margin: 0; padding: 48px 24px; display: flex; align-items: center; justify-content: center; }
.auth-card { width: 100%; max-width: 420px; }
.auth-card h1 { margin: 0 0 8px; font-size: 40px; }
.auth-sub { margin: 0 0 32px; color: var(--muted); line-height: 1.5; }
.auth-switch { margin: 20px 0 0; text-align: center; font-size: 15px; color: var(--muted); }
.auth-switch a { font-weight: 700; }
@media (max-width: 860px) {
  .auth { grid-template-columns: 1fr; }
  .auth-aside { padding: 16px 24px; }
  .auth-aside-body { display: none; }
  .auth-main { align-items: flex-start; padding-top: 40px; }
}

/* ---------- Admin shell ---------- */
.admin-shell { min-height: 100vh; display: grid; grid-template-columns: 248px minmax(0, 1fr); background: linear-gradient(to right, var(--plum-deep) 248px, var(--pearl) 248px); }
.admin-side { position: sticky; top: 0; height: 100vh; display: flex; flex-direction: column; gap: 32px; padding: 28px 16px; background: var(--plum-deep); color: #eadce4; }
.admin-logo { padding: 0 12px; font-family: var(--font-display); font-size: 24px; font-weight: 600; color: #fff !important; text-decoration: none; }
.admin-nav { display: flex; flex-direction: column; gap: 4px; flex: 1; }
.admin-nav a, .admin-side-link { display: flex; align-items: center; gap: 12px; min-height: 44px; padding: 0 12px; border: 0; border-radius: 10px; background: transparent; color: #eadce4; font: inherit; font-size: 15px; font-weight: 600; text-decoration: none; text-align: left; cursor: pointer; width: 100%; }
.admin-nav a:hover, .admin-side-link:hover { background: rgba(255, 255, 255, .08); color: #fff; }
.admin-nav a.active { background: var(--gold); color: var(--plum-deep); }
.admin-side-foot { display: flex; flex-direction: column; gap: 4px; padding-top: 16px; border-top: 1px solid #4a2336; }
.admin-main { min-width: 0; display: flex; flex-direction: column; }
.admin-top { height: 64px; display: flex; align-items: center; justify-content: flex-end; gap: 12px; padding: 0 32px; background: var(--surface); border-bottom: 1px solid var(--line); }
.admin-menu { display: none; margin-right: auto; }
.admin-user { display: flex; align-items: center; gap: 8px; font-size: 14px; font-weight: 600; }
.admin-content { padding: 32px; }
.admin-scrim { display: none; }
@media (max-width: 900px) {
  .admin-shell { grid-template-columns: 1fr; background: var(--pearl); }
  .admin-side { position: fixed; z-index: 30; left: 0; width: 260px; transform: translateX(-100%); transition: transform .2s ease; }
  .admin-side.is-open { transform: translateX(0); }
  .admin-menu { display: inline-flex; }
  .admin-top { padding: 0 12px 0 8px; }
  .admin-content { padding: 20px 16px; }
  .admin-scrim { display: block; position: fixed; inset: 0; z-index: 20; padding: 0; border: 0; border-radius: 0; background: rgba(20, 4, 12, .45); }
}
@media (prefers-reduced-motion: reduce) { .admin-side { transition: none; } }

/* ---------- Dashboard ---------- */
.dash { display: flex; flex-direction: column; gap: 28px; max-width: 1240px; }
.dash-head { display: flex; align-items: flex-end; justify-content: space-between; gap: 16px; flex-wrap: wrap; }
.dash-head h1 { margin: 0; font-size: 40px; }
.dash-head p { margin: 4px 0 0; }

.stats { display: grid; grid-template-columns: 1.4fr repeat(3, minmax(0, 1fr)); gap: 16px; }
.stat { display: flex; flex-direction: column; gap: 6px; padding: 22px; border-radius: var(--radius); background: var(--surface); border: 1px solid var(--line); color: var(--ink); text-decoration: none; }
.stat-label { font-size: 14px; font-weight: 600; color: var(--muted); }
.stat-value { font-size: 36px; font-weight: 700; line-height: 1.1; font-variant-numeric: tabular-nums; }
.stat-note { font-size: 13px; color: var(--muted); }
.stat-hero { background: var(--plum); border-color: var(--plum); color: #fff; }
.stat-hero .stat-label, .stat-hero .stat-note { color: #eadce4; }
.stat-link:hover { border-color: var(--plum); color: var(--ink); }
.stat-link .stat-note { color: var(--plum); font-weight: 600; }
@media (max-width: 1100px) { .stats { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
@media (max-width: 520px) { .stats { grid-template-columns: 1fr; } .stat-value { font-size: 30px; } }

.dash-grid { display: grid; grid-template-columns: minmax(0, 2fr) minmax(0, 1fr); gap: 16px; }
.panel { padding: 22px; border-radius: var(--radius); background: var(--surface); border: 1px solid var(--line); min-width: 0; }
.panel-wide { grid-column: 1 / -1; }
.panel-head { display: flex; align-items: baseline; justify-content: space-between; gap: 12px; margin-bottom: 18px; }
.panel-head h2 { margin: 0; font-size: 22px; }
.panel-meta { font-size: 14px; color: var(--muted); font-weight: 600; }
.panel-link { font-size: 14px; font-weight: 700; }
.empty-note { margin: 0; padding: 24px 0; color: var(--muted); text-align: center; }
.empty { display: flex; flex-direction: column; align-items: flex-start; gap: 16px; }
@media (max-width: 1000px) { .dash-grid { grid-template-columns: 1fr; } }

/* Bar chart */
.bars { position: relative; height: 240px; display: grid; grid-template-columns: repeat(7, minmax(0, 1fr)); gap: 10px; padding: 0 0 0 40px; }
.bars-grid { position: absolute; left: 0; right: 0; top: 0; bottom: 28px; display: flex; flex-direction: column; justify-content: space-between; pointer-events: none; }
.bars-grid span { position: relative; font-size: 12px; color: var(--muted); line-height: 0; font-variant-numeric: tabular-nums; }
.bars-grid span::after { content: ""; position: absolute; left: 40px; right: 0; top: 0; border-top: 1px solid var(--line); }
.bar-col { position: relative; display: flex; flex-direction: column; gap: 8px; min-width: 0; outline: none; }
.bar-track { position: relative; flex: 1; display: flex; align-items: flex-end; justify-content: center; }
.bar { width: min(36px, 70%); min-height: 2px; border-radius: 4px 4px 0 0; background: var(--plum-soft); }
.bar.is-today { background: var(--plum); }
.bar-col:hover .bar, .bar-col:focus-visible .bar { background: var(--plum-2); }
.bar-col:focus-visible .bar-track { outline: 2px solid var(--gold-deep); outline-offset: 2px; border-radius: 4px; }
.bar-label { height: 20px; font-size: 12px; font-weight: 600; color: var(--muted); text-align: center; }
.bar-tip { position: absolute; z-index: 2; bottom: calc(100% + 6px); left: 50%; transform: translateX(-50%); display: none; flex-direction: column; gap: 2px; padding: 8px 12px; border-radius: 8px; background: var(--ink); color: #fff; font-size: 12px; white-space: nowrap; pointer-events: none; }
.bar-tip strong { font-size: 14px; }
.bar-col:hover .bar-tip, .bar-col:focus-visible .bar-tip { display: flex; bottom: 50%; }

/* Low stock */
.stock-list { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; }
.stock-list li { display: flex; align-items: center; justify-content: space-between; gap: 12px; padding: 12px 0; border-bottom: 1px solid var(--line); }
.stock-list li:last-child { border-bottom: 0; }
.stock-name { display: flex; flex-direction: column; gap: 2px; font-weight: 600; min-width: 0; }
.stock-name .muted { font-size: 13px; font-weight: 400; }
.stock-count { flex-shrink: 0; display: inline-flex; align-items: center; gap: 4px; padding: 4px 10px; border-radius: 12px; background: #fbf0d9; color: #6b4a00; font-size: 13px; font-weight: 700; }
.stock-count.is-out { background: var(--error-bg); color: var(--error); }

/* Tables and status pills */
.table-scroll { overflow-x: auto; }
.table { min-width: 560px; font-size: 14px; }
.table td, .table th { white-space: nowrap; }
.table th { font-size: 13px; font-weight: 600; color: var(--muted); }
.table a { font-weight: 700; }
.table .num { font-variant-numeric: tabular-nums; }
.pill { display: inline-block; padding: 4px 10px; border-radius: 12px; font-size: 12px; font-weight: 700; }
.pill-pending { background: #fbf0d9; color: #6b4a00; }
.pill-confirmed, .pill-processing, .pill-ready, .pill-dispatched { background: #e4ecf7; color: #1f3f6b; }
.pill-delivered { background: #e1f1e6; color: #1e5b32; }
.pill-cancelled { background: #eeeaec; color: var(--muted); }
'@

Write-ProjectFile 'tsconfig.json' @'
{
  "compilerOptions": {
    "target": "ES2020", "lib": ["ES2020", "DOM", "DOM.Iterable"], "module": "ESNext",
    "moduleResolution": "bundler", "jsx": "react-jsx", "strict": true, "noEmit": true, "skipLibCheck": true
  },
  "include": ["src"]
}
'@

Write-ProjectFile 'vite.config.ts' @'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
export default defineConfig({
  plugins: [react()],
  server: { proxy: { "/api": "http://127.0.0.1:4000", "/uploads": "http://127.0.0.1:4000" } },
});
'@

# Remove copies that were downloaded into the wrong place
$loose = @('AdminLayout.tsx','AdminLogin.tsx','App.tsx','AuthContext.tsx','AuthShell.tsx','BuildLook.tsx','Cart.tsx','CartContext.tsx','Checkout.tsx','Dashboard.tsx','Home.tsx','Icon.tsx','Layout.tsx','Login.tsx','OrderConfirmation.tsx','OrderDetail.tsx','Orders.tsx','PasswordInput.tsx','ProductCard.tsx','ProductDetails.tsx','Products.tsx','Register.tsx','RequireAdmin.tsx','Shop.tsx','TrackOrder.tsx','TryOn.tsx','client.ts','main.tsx','styles.css','types.ts')
foreach ($n in $loose) { $p = Join-Path $here $n; if (Test-Path $p) { Remove-Item $p; Write-Host "removed stray $n" } }

# admin.routes.ts belongs to the backend
$stray = Join-Path $here 'admin.routes.ts'
$target = Join-Path $here '..\backend\src\modules\admin'
if (Test-Path $stray) {
  if (Test-Path $target) { Move-Item $stray (Join-Path $target 'admin.routes.ts') -Force; Write-Host 'moved admin.routes.ts to backend\src\modules\admin' }
  else { Write-Host 'admin.routes.ts: move it to backend\src\modules\admin yourself' }
}

Write-Host ''
Write-Host 'Done: 34 files. Next: npm install ; npm run dev'
