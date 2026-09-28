# E-POCH Jewelry Store - new design (taste-skill) and sign-in fix.
# Save in C:\E-POCH-Jewelry-Store-main, then run:
#   powershell -ExecutionPolicy Bypass -File .\update-design.ps1

$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)
if (-not (Test-Path (Join-Path $here 'frontend'))) { Write-Host 'Put this script in the folder that contains backend and frontend, then run it again.'; exit 1 }
function Write-ProjectFile($rel, $content) {
  $path = Join-Path $here $rel
  $dir = Split-Path $path -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
  [System.IO.File]::WriteAllText($path, (($content -replace "`r`n", "`n") + "`n"), $utf8)
}

Write-ProjectFile 'frontend\package.json' @'
{
  "name": "jewellery-frontend",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "@phosphor-icons/react": "^2.1.10",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "react-router-dom": "^6.26.2"
  },
  "devDependencies": {
    "@types/react": "^18.3.10",
    "@types/react-dom": "^18.3.0",
    "@vitejs/plugin-react": "^4.3.2",
    "typescript": "^5.6.2",
    "vite": "^5.4.8"
  }
}
'@

Write-ProjectFile 'frontend\index.html' @'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Jewellery Store</title>
    <meta name="description" content="Earrings, bangles, chains, necklaces and rings. Try any piece on with AI before you order, with islandwide delivery in Sri Lanka." />
    <meta name="theme-color" content="#f4f5f3" media="(prefers-color-scheme: light)" />
    <meta name="theme-color" content="#0e1211" media="(prefers-color-scheme: dark)" />
    <meta property="og:type" content="website" />
    <meta property="og:title" content="Jewellery Store" />
    <meta property="og:description" content="Try any piece on with AI before you order." />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&display=swap" />
  </head>
  <body><div id="root"></div><script type="module" src="/src/main.tsx"></script></body>
</html>
'@

Write-ProjectFile 'frontend\vite.config.ts' @'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
export default defineConfig({
  plugins: [react()],
  server: { proxy: { "/api": "http://127.0.0.1:4000", "/uploads": "http://127.0.0.1:4000" } },
});
'@

Write-ProjectFile 'frontend\tsconfig.json' @'
{
  "compilerOptions": {
    "target": "ES2020", "lib": ["ES2020", "DOM", "DOM.Iterable"], "module": "ESNext",
    "moduleResolution": "bundler", "jsx": "react-jsx", "strict": true, "noEmit": true, "skipLibCheck": true
  },
  "include": ["src"]
}
'@

Write-ProjectFile 'frontend\public\favicon.svg' @'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect width="64" height="64" rx="14" fill="#0e5a45"/><path d="M20 26l6-8h12l6 8-12 20z" fill="none" stroke="#fff" stroke-width="3" stroke-linejoin="round"/><path d="M20 26h24" stroke="#fff" stroke-width="3"/></svg>
'@

Write-ProjectFile 'frontend\src\App.tsx' @'
import { Routes, Route } from "react-router-dom";
import Layout from "./components/Layout";
import RequireAdmin from "./components/RequireAdmin";
import RequireAuth from "./components/RequireAuth";
import Home from "./pages/Home";
import Shop from "./pages/Shop";
import ProductDetails from "./pages/ProductDetails";
import TryOn from "./pages/TryOn";
import BuildLook from "./pages/BuildLook";
import CartPage from "./pages/Cart";
import Checkout from "./pages/Checkout";
import OrderConfirmation from "./pages/OrderConfirmation";
import TrackOrder from "./pages/TrackOrder";
import Account from "./pages/Account";
import Login from "./pages/Login";
import Register from "./pages/Register";
import { About, Contact, Delivery, Faq, NotFound, Privacy, Terms } from "./pages/Info";
import AdminLogin from "./pages/admin/AdminLogin";
import AdminLayout from "./pages/admin/AdminLayout";
import Dashboard from "./pages/admin/Dashboard";
import AdminProducts from "./pages/admin/Products";
import ProductForm from "./pages/admin/ProductForm";
import Categories from "./pages/admin/Categories";
import AdminOrders from "./pages/admin/Orders";
import AdminOrderDetail from "./pages/admin/OrderDetail";
import Customers from "./pages/admin/Customers";
import AiModels from "./pages/admin/AiModels";
import Offers from "./pages/admin/Offers";
import Reports from "./pages/admin/Reports";
import SettingsPage from "./pages/admin/Settings";

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
        <Route path="/about" element={<About />} />
        <Route path="/contact" element={<Contact />} />
        <Route path="/delivery" element={<Delivery />} />
        <Route path="/faq" element={<Faq />} />
        <Route path="/privacy" element={<Privacy />} />
        <Route path="/terms" element={<Terms />} />
        <Route element={<RequireAuth />}>
          <Route path="/account" element={<Account />} />
          <Route path="/account/:tab" element={<Account />} />
        </Route>
        <Route path="*" element={<NotFound />} />
      </Route>

      <Route path="/login" element={<Login />} />
      <Route path="/register" element={<Register />} />
      <Route path="/admin/login" element={<AdminLogin />} />
      <Route element={<RequireAdmin />}>
        <Route path="/admin" element={<AdminLayout />}>
          <Route index element={<Dashboard />} />
          <Route path="orders" element={<AdminOrders />} />
          <Route path="orders/:id" element={<AdminOrderDetail />} />
          <Route path="products" element={<AdminProducts />} />
          <Route path="products/new" element={<ProductForm />} />
          <Route path="products/:id" element={<ProductForm />} />
          <Route path="categories" element={<Categories />} />
          <Route path="customers" element={<Customers />} />
          <Route path="ai-models" element={<AiModels />} />
          <Route path="offers" element={<Offers />} />
          <Route path="reports" element={<Reports />} />
          <Route path="settings" element={<SettingsPage />} />
        </Route>
      </Route>
    </Routes>
  );
}
'@

Write-ProjectFile 'frontend\src\main.tsx' @'
import React from "react";
import ReactDOM from "react-dom/client";
import { BrowserRouter } from "react-router-dom";
import App from "./App";
import { ToastProvider } from "./context/ToastContext";
import { SettingsProvider } from "./context/SettingsContext";
import { CartProvider } from "./context/CartContext";
import { AuthProvider } from "./context/AuthContext";
import { WishlistProvider } from "./context/WishlistContext";
import "./styles.css";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <BrowserRouter>
      <ToastProvider>
        <SettingsProvider>
          <CartProvider>
            <AuthProvider>
              <WishlistProvider>
                <App />
              </WishlistProvider>
            </AuthProvider>
          </CartProvider>
        </SettingsProvider>
      </ToastProvider>
    </BrowserRouter>
  </React.StrictMode>
);
'@

Write-ProjectFile 'frontend\src\styles.css' @'
/* =========================================================
   Design tokens
   One accent (emerald), one cool-green neutral family, light + dark.
   Radius system: buttons, chips and search are pills; images and cards 16px;
   panels and large containers 20px; inputs and thumbnails 12px.
   ========================================================= */
:root {
  color-scheme: light dark;
  --bg: #f4f5f3;
  --surface: #ffffff;
  --surface-2: #e9ecea;
  --tint: #e4eae7;
  --tint-2: #eff2f0;
  --ink: #151a18;
  --ink-2: #3c4542;
  --muted: #5a6360;
  --line: #dce1de;
  --line-2: #c3cbc7;
  --accent: #0e5a45;
  --accent-2: #0a4636;
  --accent-soft: #dcebe4;
  --accent-muted: #5e8f7f;
  --on-accent: #ffffff;
  --error: #b3261e;
  --error-bg: #fbe9e7;
  --ok: #1b5e3a;
  --ok-bg: #e0f0e6;
  --warn: #7a4d00;
  --warn-bg: #faefd6;
  --info: #1f4470;
  --info-bg: #e3ecf7;
  --side-bg: #13201c;
  --side-ink: #d3dfda;
  --side-line: #26352f;
  --scrim: rgba(10, 22, 18, 0.48);
  --shadow: 0 18px 44px rgba(14, 44, 34, 0.14);
  --shadow-sm: 0 2px 8px rgba(14, 44, 34, 0.12);

  --r-pill: 999px;
  --r-lg: 20px;
  --r: 16px;
  --r-sm: 12px;

  --font: "Geist", ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif;
  --page: 1280px;
  --gutter: 24px;
  --header-h: 72px;
  --ease: cubic-bezier(0.2, 0.7, 0.2, 1);

  /* z-index scale */
  --z-sticky: 30;
  --z-drawer: 60;
  --z-toast: 90;

  font-family: var(--font);
  color: var(--ink);
  background: var(--bg);
  -webkit-font-smoothing: antialiased;
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg: #0e1211;
    --surface: #151a18;
    --surface-2: #1b211f;
    --tint: #1f2624;
    --tint-2: #1a201e;
    --ink: #e9eeeb;
    --ink-2: #c3ccc8;
    --muted: #9aa5a1;
    --line: #29312e;
    --line-2: #3a4440;
    --accent: #4fbf97;
    --accent-2: #6fd0ad;
    --accent-soft: #173a2f;
    --accent-muted: #3e7f6a;
    --on-accent: #06130e;
    --error: #f2b8b5;
    --error-bg: #3a1715;
    --ok: #9fd8b5;
    --ok-bg: #16301f;
    --warn: #f0cd86;
    --warn-bg: #33270e;
    --info: #a9c7ee;
    --info-bg: #16243a;
    --side-bg: #0a0e0d;
    --side-ink: #c9d4d0;
    --side-line: #202824;
    --scrim: rgba(0, 0, 0, 0.6);
    --shadow: 0 18px 44px rgba(0, 0, 0, 0.5);
    --shadow-sm: 0 2px 8px rgba(0, 0, 0, 0.45);
  }
}
@media (max-width: 640px) { :root { --gutter: 16px; --header-h: 64px; } }

/* =========================================================
   Base
   ========================================================= */
* { box-sizing: border-box; }
html { scroll-behavior: smooth; }
body { margin: 0; background: var(--bg); color: var(--ink); font-size: 16px; line-height: 1.55; }
img { max-width: 100%; display: block; }
a { color: var(--accent); text-underline-offset: 3px; transition: color 0.2s var(--ease); }
a:hover { color: var(--accent-2); }
h1, h2, h3 { margin: 0; font-weight: 600; letter-spacing: -0.025em; line-height: 1.08; text-wrap: balance; }
p { margin: 0; text-wrap: pretty; }
button, input, select, textarea { font: inherit; color: inherit; }
button { cursor: pointer; }
button:disabled { cursor: not-allowed; }
:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
::selection { background: var(--accent-soft); color: var(--ink); }
.muted { color: var(--muted); }
.sr-only { position: absolute !important; width: 1px; height: 1px; padding: 0; margin: -1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; border: 0; }
.skip-link { position: absolute; left: 8px; top: -60px; z-index: var(--z-toast); padding: 10px 16px; background: var(--accent); color: var(--on-accent); border-radius: var(--r-sm); }
.skip-link:focus { top: 8px; color: var(--on-accent); }
.page { width: 100%; max-width: var(--page); margin: 0 auto; padding: 36px var(--gutter) 96px; }
.page-narrow { max-width: 820px; }
.page-head { display: flex; flex-direction: column; gap: 8px; margin-bottom: 32px; }
.page-head h1 { font-size: clamp(32px, 4.6vw, 48px); }
.page-head p { color: var(--muted); max-width: 60ch; }
.section-head { display: flex; align-items: baseline; justify-content: space-between; gap: 16px; margin-bottom: 24px; }
.section-head h2 { font-size: clamp(26px, 3.4vw, 36px); }
.section-head a { font-weight: 600; font-size: 15px; white-space: nowrap; }
.num { font-variant-numeric: tabular-nums; }

/* Motion: one reveal on scroll, only when the visitor hasn't asked for reduced motion */
@media (prefers-reduced-motion: no-preference) {
  .reveal { opacity: 0; transform: translateY(18px); transition: opacity 0.6s var(--ease), transform 0.6s var(--ease); transition-delay: calc(var(--i, 0) * 70ms); }
  .reveal.is-in { opacity: 1; transform: none; }
}
@media (prefers-reduced-motion: reduce) {
  html { scroll-behavior: auto; }
  *, *::before, *::after { transition: none !important; animation: none !important; }
}

/* =========================================================
   Buttons
   ========================================================= */
.btn { display: inline-flex; align-items: center; justify-content: center; gap: 8px; min-height: 48px; padding: 0 24px; border-radius: var(--r-pill); border: 1.5px solid transparent; font-size: 15px; font-weight: 600; line-height: 1.2; text-decoration: none; text-align: center; background: none; white-space: nowrap; transition: background-color 0.2s var(--ease), border-color 0.2s var(--ease), color 0.2s var(--ease), transform 0.12s var(--ease); }
.btn:active:not(:disabled) { transform: translateY(1px) scale(0.98); }
.btn:disabled { opacity: 0.45; }
.btn-primary { background: var(--accent); color: var(--on-accent); border-color: var(--accent); }
.btn-primary:hover:not(:disabled) { background: var(--accent-2); border-color: var(--accent-2); color: var(--on-accent); }
.btn-secondary { background: transparent; color: var(--ink); border-color: var(--line-2); }
.btn-secondary:hover:not(:disabled) { border-color: var(--ink); color: var(--ink); }
.btn-quiet { color: var(--ink); border-color: var(--line); background: var(--surface); }
.btn-quiet:hover:not(:disabled) { border-color: var(--ink-2); color: var(--ink); }
.btn-danger { background: var(--error); color: var(--surface); border-color: var(--error); }
.btn-danger:hover:not(:disabled) { filter: brightness(0.92); }
.btn-sm { min-height: 44px; padding: 0 16px; font-size: 14px; }
.btn-lg { min-height: 54px; padding: 0 30px; font-size: 16px; }
.btn-block { width: 100%; }
.btn-icon-text { padding: 0 14px; }
.btn-link { padding: 0; border: 0; background: none; color: var(--accent); font-weight: 600; text-decoration: underline; text-underline-offset: 3px; min-height: 44px; }
.icon-btn { width: 44px; height: 44px; padding: 0; flex-shrink: 0; display: inline-flex; align-items: center; justify-content: center; border: 0; border-radius: var(--r-pill); background: transparent; color: var(--ink); text-decoration: none; position: relative; transition: background-color 0.2s var(--ease), transform 0.12s var(--ease); }
.icon-btn:hover { background: var(--tint); color: var(--ink); }
.icon-btn:active { transform: scale(0.94); }
.icon-btn-sm { width: 36px; height: 36px; }

/* =========================================================
   Forms
   ========================================================= */
.form { display: flex; flex-direction: column; gap: 18px; }
.form-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 18px; }
.form-grid .span-2 { grid-column: 1 / -1; }
@media (max-width: 640px) { .form-grid { grid-template-columns: 1fr; } }
.field { display: flex; flex-direction: column; gap: 6px; min-width: 0; }
.field-label { font-size: 14px; font-weight: 600; }
.field-hint, .optional { font-size: 13px; color: var(--muted); font-weight: 400; }
.input, .field input:not([type="checkbox"]):not([type="radio"]):not([type="file"]), .field select, .field textarea {
  width: 100%; min-height: 48px; padding: 10px 14px; border: 1px solid var(--line-2); border-radius: var(--r-sm); background: var(--surface); color: var(--ink); font-size: 16px; transition: border-color 0.2s var(--ease); }
.field input::placeholder, .field textarea::placeholder, .search input::placeholder { color: var(--muted); opacity: 1; }
.field textarea { min-height: 96px; resize: vertical; }
.field input:disabled { background: var(--tint-2); color: var(--muted); }
.input:focus, .field input:focus, .field select:focus, .field textarea:focus { border-color: var(--accent); outline: 2px solid var(--accent); outline-offset: 0; }
.field input[aria-invalid="true"], .field textarea[aria-invalid="true"] { border-color: var(--error); }
.input-wrap { position: relative; display: block; }
.input-wrap input { padding-right: 52px !important; }
.input-icon { position: absolute; right: 2px; top: 2px; width: 44px; height: 44px; padding: 0; display: flex; align-items: center; justify-content: center; border: 0; border-radius: 10px; background: transparent; color: var(--muted); }
.input-icon:hover { color: var(--accent); }
.form-error { padding: 12px 14px; border-radius: var(--r-sm); background: var(--error-bg); color: var(--error); font-size: 14px; font-weight: 600; }
.form-ok { padding: 12px 14px; border-radius: var(--r-sm); background: var(--ok-bg); color: var(--ok); font-size: 14px; font-weight: 600; }
.fieldset { border: 0; padding: 0; margin: 0; display: flex; flex-direction: column; gap: 12px; }
.fieldset legend { padding: 0; margin-bottom: 12px; font-size: 14px; font-weight: 600; }

.choices { display: grid; gap: 12px; }
.choices-2 { grid-template-columns: repeat(2, minmax(0, 1fr)); }
@media (max-width: 560px) { .choices-2 { grid-template-columns: 1fr; } }
.choice { position: relative; display: flex; gap: 14px; align-items: flex-start; padding: 16px; border: 1.5px solid var(--line); border-radius: var(--r); background: var(--surface); cursor: pointer; transition: border-color 0.2s var(--ease), background-color 0.2s var(--ease); }
.choice:hover { border-color: var(--line-2); }
.choice input { position: absolute; opacity: 0; pointer-events: none; }
.choice-dot { flex-shrink: 0; width: 22px; height: 22px; margin-top: 1px; border: 2px solid var(--line-2); border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.choice-dot::after { content: ""; width: 10px; height: 10px; border-radius: 50%; background: transparent; }
.choice:has(input:checked) { border-color: var(--accent); background: var(--accent-soft); }
.choice:has(input:checked) .choice-dot { border-color: var(--accent); }
.choice:has(input:checked) .choice-dot::after { background: var(--accent); }
.choice:has(input:focus-visible) { outline: 2px solid var(--accent); outline-offset: 2px; }
.choice-body { display: flex; flex-direction: column; gap: 2px; min-width: 0; }
.choice-title { display: flex; align-items: center; gap: 8px; font-weight: 600; }
.choice-note { font-size: 14px; color: var(--muted); }

.switch { display: flex; align-items: flex-start; gap: 12px; cursor: pointer; min-height: 44px; padding: 4px 0; }
.switch input { position: absolute; opacity: 0; width: 1px; height: 1px; }
.switch-track { flex-shrink: 0; position: relative; width: 44px; height: 26px; margin-top: 1px; border-radius: 13px; background: var(--line-2); transition: background-color 0.2s var(--ease); }
.switch-thumb { position: absolute; top: 3px; left: 3px; width: 20px; height: 20px; border-radius: 50%; background: var(--surface); box-shadow: var(--shadow-sm); transition: transform 0.2s var(--ease); }
.switch input:checked + .switch-track { background: var(--accent); }
.switch input:checked + .switch-track .switch-thumb { transform: translateX(18px); }
.switch input:focus-visible + .switch-track { outline: 2px solid var(--accent); outline-offset: 2px; }
.switch-text { display: flex; flex-direction: column; gap: 2px; }
.switch-label { font-weight: 600; }

.qty { display: inline-flex; align-items: center; border: 1px solid var(--line-2); border-radius: var(--r-pill); background: var(--surface); }
.qty-btn { width: 44px; height: 44px; display: flex; align-items: center; justify-content: center; border: 0; border-radius: var(--r-pill); background: none; color: var(--ink); transition: background-color 0.2s var(--ease); }
.qty-btn:hover:not(:disabled) { background: var(--tint); }
.qty-btn:disabled { color: var(--line-2); }
.qty-value { min-width: 32px; text-align: center; font-weight: 600; font-variant-numeric: tabular-nums; }

/* =========================================================
   Header, drawer, footer
   ========================================================= */
.site { min-height: 100dvh; display: flex; flex-direction: column; }
.site-main { flex: 1; }
.site-header { position: sticky; top: 0; z-index: var(--z-sticky); background: color-mix(in srgb, var(--bg) 88%, transparent); backdrop-filter: saturate(1.4) blur(12px); -webkit-backdrop-filter: saturate(1.4) blur(12px); border-bottom: 1px solid var(--line); }
.header-row { max-width: 1440px; margin: 0 auto; height: var(--header-h); padding: 0 var(--gutter); display: flex; align-items: center; gap: 28px; }
.brand { font-size: 22px; font-weight: 700; letter-spacing: -0.03em; color: var(--ink); text-decoration: none; white-space: nowrap; }
.brand:hover { color: var(--accent); }
.main-nav { display: flex; gap: 22px; flex: 1; min-width: 0; }
.main-nav a { color: var(--ink-2); text-decoration: none; font-size: 15px; font-weight: 500; white-space: nowrap; padding: 8px 0; border-bottom: 2px solid transparent; transition: color 0.2s var(--ease), border-color 0.2s var(--ease); }
.main-nav a:hover { color: var(--ink); }
.main-nav a.active { color: var(--ink); font-weight: 600; border-bottom-color: var(--accent); }
.search { display: flex; align-items: center; gap: 8px; height: 44px; padding: 0 16px; border: 1px solid var(--line-2); border-radius: var(--r-pill); background: var(--surface); color: var(--muted); transition: border-color 0.2s var(--ease); }
.search:focus-within { border-color: var(--accent); outline: 2px solid var(--accent); outline-offset: -1px; }
.search input { border: 0; outline: none; background: transparent; width: 100%; min-width: 0; font-size: 15px; color: var(--ink); }
.header-search { width: 240px; flex-shrink: 0; }
.header-icons { display: flex; align-items: center; gap: 2px; }
.count-badge { position: absolute; top: 3px; right: 1px; min-width: 18px; height: 18px; padding: 0 5px; border-radius: 9px; background: var(--accent); color: var(--on-accent); font-size: 11px; font-weight: 700; line-height: 18px; text-align: center; }
.header-signin { width: auto; gap: 8px; padding: 0 14px 0 10px; font-weight: 600; font-size: 15px; white-space: nowrap; color: var(--ink); }
@media (max-width: 560px) { .header-signin { width: 44px; padding: 0; } .header-signin-label { display: none; } }
.header-menu { display: none; margin-left: -10px; }
@media (max-width: 1240px) { .main-nav a:nth-child(n+6) { display: none; } }
@media (max-width: 1060px) {
  .main-nav, .header-search { display: none; }
  .header-menu { display: inline-flex; }
  .header-row { gap: 8px; }
  .brand { flex: 1; font-size: 20px; }
}
.drawer-scrim { position: fixed; inset: 0; z-index: var(--z-drawer); border: 0; padding: 0; background: var(--scrim); }
.drawer { position: fixed; z-index: calc(var(--z-drawer) + 1); top: 0; left: 0; bottom: 0; width: min(340px, 88vw); display: flex; flex-direction: column; gap: 20px; padding: 16px 20px 24px; background: var(--surface); transform: translateX(-100%); transition: transform 0.25s var(--ease); overflow-y: auto; visibility: hidden; }
.drawer.is-open { transform: translateX(0); visibility: visible; }
.drawer-head { display: flex; align-items: center; justify-content: space-between; }
.drawer-nav { display: flex; flex-direction: column; }
.drawer-nav a { padding: 14px 4px; color: var(--ink); text-decoration: none; font-size: 18px; font-weight: 500; }
.drawer-nav a.active { color: var(--accent); font-weight: 600; }
.drawer-foot { margin-top: auto; padding-top: 16px; border-top: 1px solid var(--line); display: flex; flex-direction: column; gap: 8px; align-items: flex-start; }
.drawer-foot a:not(.btn) { font-weight: 600; padding: 10px 0; color: var(--ink); }

.site-footer { background: var(--surface-2); color: var(--ink-2); margin-top: 24px; }
.footer-inner { max-width: var(--page); margin: 0 auto; padding: 64px var(--gutter) 40px; display: grid; grid-template-columns: minmax(0, 2fr) repeat(2, minmax(0, 1fr)); gap: 48px; }
.footer-brand { display: flex; flex-direction: column; gap: 10px; max-width: 360px; }
.footer-brand p { line-height: 1.6; }
.footer-col { display: flex; flex-direction: column; gap: 10px; font-size: 15px; }
.footer-col h2 { font-size: 15px; font-weight: 600; letter-spacing: 0; color: var(--ink); margin-bottom: 4px; }
.footer-col a { color: var(--ink-2); text-decoration: none; }
.footer-col a:hover { color: var(--accent); text-decoration: underline; }
.footer-base { max-width: var(--page); margin: 0 auto; padding: 20px var(--gutter) 32px; border-top: 1px solid var(--line); display: flex; justify-content: space-between; gap: 16px; flex-wrap: wrap; font-size: 14px; color: var(--muted); }
.footer-legal { display: flex; gap: 20px; }
.footer-legal a { color: var(--muted); }
@media (max-width: 760px) { .footer-inner { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 32px; } .footer-brand { grid-column: 1 / -1; } }

/* =========================================================
   Shared bits
   ========================================================= */
.price { display: inline-flex; flex-wrap: wrap; align-items: baseline; gap: 2px 10px; }
.price-now { font-weight: 600; color: var(--ink); font-variant-numeric: tabular-nums; }
.price-was { color: var(--muted); font-size: 14px; }
.price-off { font-size: 13px; font-weight: 600; color: var(--accent); }
.price-md .price-now { font-size: 17px; }
.price-lg .price-now { font-size: 30px; letter-spacing: -0.02em; }
.price-lg .price-was { font-size: 17px; }
.pill { display: inline-block; padding: 4px 10px; border-radius: var(--r-pill); font-size: 12px; font-weight: 600; white-space: nowrap; letter-spacing: 0; vertical-align: middle; }
.pill-pending, .pill-unpaid { background: var(--warn-bg); color: var(--warn); }
.pill-confirmed, .pill-processing, .pill-ready, .pill-dispatched { background: var(--info-bg); color: var(--info); }
.pill-delivered, .pill-paid, .pill-on { background: var(--ok-bg); color: var(--ok); }
.pill-cancelled, .pill-off, .pill-refunded { background: var(--tint); color: var(--muted); }
.crumbs ol { list-style: none; margin: 0 0 20px; padding: 0; display: flex; flex-wrap: wrap; gap: 6px; font-size: 14px; color: var(--muted); }
.crumbs li:not(:last-child)::after { content: "/"; margin-left: 6px; color: var(--line-2); }
.crumbs a { color: var(--muted); }
.crumbs a:hover { color: var(--accent); }
.pager { display: flex; justify-content: center; align-items: center; gap: 6px; margin-top: 48px; flex-wrap: wrap; }
.pager-group { display: inline-flex; align-items: center; gap: 6px; }
.pager-btn { min-width: 44px; height: 44px; padding: 0 10px; display: inline-flex; align-items: center; justify-content: center; border: 1px solid var(--line-2); border-radius: var(--r-pill); background: var(--surface); color: var(--ink); font-weight: 600; transition: border-color 0.2s var(--ease); }
.pager-btn:hover:not(:disabled) { border-color: var(--ink); }
.pager-btn.is-current { background: var(--accent); border-color: var(--accent); color: var(--on-accent); }
.pager-btn:disabled { opacity: 0.4; }
.pager-gap { color: var(--muted); }
.page-loading { display: flex; align-items: center; justify-content: center; gap: 12px; padding: 80px 16px; color: var(--muted); }
.spinner { width: 22px; height: 22px; border: 3px solid var(--tint); border-top-color: var(--accent); border-radius: 50%; animation: spin 0.8s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
.empty-state { display: flex; flex-direction: column; align-items: center; text-align: center; gap: 12px; padding: 64px 16px; }
.empty-state h2 { font-size: 26px; }
.empty-state p { color: var(--muted); max-width: 46ch; }
.empty-state .btn { margin-top: 8px; }
.empty-icon { width: 64px; height: 64px; border-radius: var(--r); background: var(--accent-soft); color: var(--accent); display: flex; align-items: center; justify-content: center; }
.empty-icon-error { background: var(--error-bg); color: var(--error); }
.empty-note { padding: 24px 0; color: var(--muted); text-align: center; }

.pimg { width: 100%; height: 100%; object-fit: cover; background: var(--tint); }
.pimg-empty { display: flex; align-items: center; justify-content: center; color: var(--muted); }

.toasts { position: fixed; z-index: var(--z-toast); left: 50%; bottom: 24px; transform: translateX(-50%); width: min(520px, calc(100vw - 32px)); display: flex; flex-direction: column; gap: 8px; pointer-events: none; }
.toast { pointer-events: auto; display: flex; align-items: center; gap: 12px; padding: 8px 8px 8px 16px; border-radius: var(--r); background: var(--ink); color: var(--bg); box-shadow: var(--shadow); font-size: 15px; animation: toast-in 0.2s var(--ease); }
.toast-error { background: var(--error); color: var(--bg); }
.toast-text { flex: 1; }
.toast-link { color: var(--bg) !important; font-weight: 700; white-space: nowrap; text-decoration: underline; }
.toast .icon-btn { color: var(--bg); }
.toast .icon-btn:hover { background: color-mix(in srgb, var(--bg) 16%, transparent); color: var(--bg); }
@keyframes toast-in { from { opacity: 0; transform: translateY(8px); } }

.modal { width: min(520px, calc(100vw - 32px)); max-height: calc(100dvh - 32px); padding: 0; border: 0; border-radius: var(--r-lg); background: var(--surface); color: var(--ink); box-shadow: var(--shadow); }
.modal-wide { width: min(760px, calc(100vw - 32px)); }
.modal::backdrop { background: var(--scrim); }
.modal-inner { display: flex; flex-direction: column; max-height: calc(100dvh - 32px); }
.modal-head { display: flex; align-items: center; justify-content: space-between; gap: 12px; padding: 20px 20px 12px 24px; }
.modal-head h2 { font-size: 24px; }
.modal-body { padding: 4px 24px 24px; overflow-y: auto; }
.modal-text { color: var(--ink-2); line-height: 1.6; }
.modal-foot { display: flex; justify-content: flex-end; gap: 10px; padding: 16px 24px 20px; border-top: 1px solid var(--line); flex-wrap: wrap; }

/* =========================================================
   Product card (no box: photo, then text)
   ========================================================= */
.pgrid { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 40px 24px; }
@media (max-width: 1100px) { .pgrid { grid-template-columns: repeat(3, minmax(0, 1fr)); } }
@media (max-width: 760px) { .pgrid { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 28px 12px; } }
.pcard { display: flex; flex-direction: column; gap: 12px; min-width: 0; flex: 1; }
.pgrid > .reveal, .rail > .reveal { display: flex; flex-direction: column; }
.pcard-media { position: relative; aspect-ratio: 4 / 5; border-radius: var(--r); overflow: hidden; background: var(--tint); }
.pcard-link { display: block; width: 100%; height: 100%; }
.pcard-media .pimg { transition: transform 0.5s var(--ease); }
.pcard:hover .pcard-media img.pimg { transform: scale(1.04); }
.pcard.is-soldout .pcard-media .pimg { opacity: 0.5; }
.pcard-wish { position: absolute; top: 10px; right: 10px; width: 44px; height: 44px; border: 0; border-radius: 50%; background: color-mix(in srgb, var(--surface) 92%, transparent); color: var(--ink); display: flex; align-items: center; justify-content: center; box-shadow: var(--shadow-sm); transition: transform 0.12s var(--ease), color 0.2s var(--ease); }
.pcard-wish:hover { color: var(--accent); }
.pcard-wish:active { transform: scale(0.92); }
.pcard-wish.is-on { color: var(--accent); }
.pcard-body { display: flex; flex-direction: column; gap: 4px; }
.pcard-meta { display: flex; gap: 10px; font-size: 13px; color: var(--muted); }
.pcard-new { color: var(--accent); font-weight: 600; }
.pcard-name { font-size: 16px; font-weight: 500; letter-spacing: -0.01em; line-height: 1.3; }
.pcard-name a { color: var(--ink); text-decoration: none; }
.pcard-name a:hover { color: var(--accent); text-decoration: underline; }
.pcard-actions { display: flex; gap: 8px; margin-top: auto; }
.pcard-add { flex: 1; min-width: 0; }
.pcard-try { width: 44px; padding: 0; flex-shrink: 0; }
@media (max-width: 760px) {
  .pcard-name { font-size: 14px; }
  .pcard .btn-sm { padding: 0 10px; font-size: 13px; }
  .price-md .price-now { font-size: 15px; }
}
.skeleton { background: linear-gradient(90deg, var(--tint) 0%, var(--tint-2) 50%, var(--tint) 100%); background-size: 200% 100%; animation: shimmer 1.2s infinite; border-radius: var(--r); }
.skeleton-card { aspect-ratio: 4 / 6.2; }
@keyframes shimmer { to { background-position: -200% 0; } }

/* Horizontal rail (categories, offers) */
.rail { display: grid; grid-auto-flow: column; grid-auto-columns: minmax(180px, calc((100% - 5 * 20px) / 6)); gap: 20px; overflow-x: auto; scroll-snap-type: x mandatory; padding-bottom: 8px; scrollbar-width: thin; }
.rail > * { scroll-snap-align: start; }
.rail-products { grid-auto-columns: minmax(220px, calc((100% - 3 * 24px) / 4)); gap: 24px; }
@media (max-width: 760px) {
  .rail { grid-auto-columns: 42%; gap: 12px; margin: 0 calc(-1 * var(--gutter)); padding: 0 var(--gutter) 8px; scroll-padding-inline: var(--gutter); }
  .rail-products { grid-auto-columns: 62%; }
}

/* =========================================================
   Home
   ========================================================= */
.hero { max-width: var(--page); margin: 0 auto; padding: 40px var(--gutter) 24px; display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 56px; align-items: center; min-height: min(calc(100dvh - var(--header-h)), 780px); }
.hero-copy { display: flex; flex-direction: column; gap: 22px; align-items: flex-start; }
.hero h1 { font-size: clamp(40px, 4.8vw, 66px); letter-spacing: -0.04em; line-height: 1.04; max-width: 14ch; }
.hero p { font-size: 19px; line-height: 1.55; color: var(--ink-2); max-width: 34ch; }
.hero-actions { display: flex; gap: 12px; flex-wrap: wrap; margin-top: 6px; }
.hero-media { position: relative; aspect-ratio: 4 / 5; max-height: calc(100dvh - var(--header-h) - 64px); justify-self: end; width: 100%; border-radius: var(--r-lg); overflow: hidden; background: var(--tint); }
.hero-media img { width: 100%; height: 100%; object-fit: cover; }
.hero-media-empty { display: flex; align-items: center; justify-content: center; color: var(--muted); }
@media (max-width: 900px) {
  .hero { grid-template-columns: 1fr; gap: 28px; min-height: 0; padding-top: 24px; }
  .hero-media { justify-self: stretch; aspect-ratio: 4 / 4.2; max-height: none; }
  .hero h1 { max-width: 14ch; }
}
@media (max-width: 560px) { .hero-actions .btn { flex: 1 1 100%; } }
.home-section { max-width: var(--page); margin: 0 auto; padding: 88px var(--gutter) 0; }
@media (max-width: 640px) { .home-section { padding-top: 64px; } }

.cat-card { display: flex; flex-direction: column; gap: 10px; text-decoration: none; color: var(--ink); }
.cat-card-img { aspect-ratio: 3 / 4; border-radius: var(--r); overflow: hidden; background: var(--tint); display: flex; align-items: center; justify-content: center; }
.cat-card-img img { width: 100%; height: 100%; object-fit: cover; transition: transform 0.5s var(--ease); }
.cat-card:hover .cat-card-img img { transform: scale(1.05); }
.cat-card-letter { font-size: 56px; font-weight: 600; letter-spacing: -0.04em; color: var(--accent); }
.cat-card-name { font-size: 15px; font-weight: 500; }
.cat-card:hover .cat-card-name { color: var(--accent); }

.look-bento { display: grid; grid-template-columns: repeat(12, minmax(0, 1fr)); grid-template-rows: auto auto; gap: 16px; }
.look-copy { grid-column: span 5; display: flex; flex-direction: column; gap: 16px; align-items: flex-start; justify-content: center; padding: 40px; border-radius: var(--r-lg); background: var(--accent-soft); }
.look-copy h2 { font-size: clamp(30px, 3.6vw, 44px); }
.look-copy p { font-size: 17px; color: var(--ink-2); max-width: 36ch; }
.look-photo { grid-column: span 7; grid-row: span 2; border-radius: var(--r-lg); overflow: hidden; background: var(--tint); min-height: 420px; }
.look-photo img { width: 100%; height: 100%; object-fit: cover; }
.look-pieces { grid-column: span 5; display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 12px; }
.look-piece { display: flex; flex-direction: column; gap: 8px; text-decoration: none; color: var(--ink); }
.look-piece-img { aspect-ratio: 1; border-radius: var(--r); overflow: hidden; background: var(--tint); }
.look-piece-img img { width: 100%; height: 100%; object-fit: cover; transition: transform 0.5s var(--ease); }
.look-piece:hover .look-piece-img img { transform: scale(1.05); }
.look-piece span { font-size: 14px; font-weight: 500; line-height: 1.3; }
@media (max-width: 900px) {
  .look-bento { grid-template-columns: 1fr; }
  .look-copy, .look-photo, .look-pieces { grid-column: auto; grid-row: auto; }
  .look-copy { padding: 28px 24px; }
  .look-photo { min-height: 0; aspect-ratio: 4 / 3; }
}

.services { max-width: var(--page); margin: 0 auto; padding: 88px var(--gutter) 88px; display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); }
.service { display: flex; gap: 12px; align-items: flex-start; padding: 4px 24px; border-left: 1px solid var(--line); }
.service:first-child { padding-left: 0; border-left: 0; }
.service svg { flex-shrink: 0; color: var(--accent); margin-top: 2px; }
.service strong { display: block; font-size: 15px; font-weight: 600; }
.service span { font-size: 14px; color: var(--muted); line-height: 1.5; }
@media (max-width: 900px) {
  .services { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 24px 0; padding: 64px var(--gutter); }
  .service:nth-child(3) { padding-left: 0; border-left: 0; }
}
@media (max-width: 480px) { .services { grid-template-columns: 1fr; } .service { padding-left: 0; border-left: 0; } }

/* =========================================================
   Shop
   ========================================================= */
.shop { display: grid; grid-template-columns: 240px minmax(0, 1fr); gap: 48px; align-items: start; }
.shop-head { display: flex; flex-direction: column; gap: 6px; margin-bottom: 28px; }
.shop-head h1 { font-size: clamp(32px, 4.6vw, 48px); }
.shop-toolbar { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-bottom: 24px; flex-wrap: wrap; }
.shop-count { color: var(--muted); font-size: 15px; }
.shop-toolbar-right { display: flex; gap: 10px; align-items: center; }
.sort select { min-height: 44px; padding: 0 36px 0 16px; border: 1px solid var(--line-2); border-radius: var(--r-pill); background: var(--surface); color: var(--ink); font-size: 14px; font-weight: 500; }
.filters-toggle { display: none; }
.filters { position: sticky; top: calc(var(--header-h) + 24px); display: flex; flex-direction: column; gap: 28px; }
.filters-head { display: none; }
.filter-group { display: flex; flex-direction: column; gap: 10px; }
.filter-group h2 { font-size: 14px; font-weight: 600; letter-spacing: 0; }
.filter-list { display: flex; flex-direction: column; gap: 2px; }
.filter-link { display: flex; justify-content: space-between; gap: 8px; padding: 8px 12px; border-radius: var(--r-sm); color: var(--ink-2); text-decoration: none; font-size: 15px; transition: background-color 0.2s var(--ease); }
.filter-link:hover { background: var(--tint); color: var(--ink); }
.filter-link.is-on { background: var(--accent-soft); color: var(--accent); font-weight: 600; }
.filter-link .muted { font-size: 13px; font-variant-numeric: tabular-nums; }
.price-inputs { display: grid; grid-template-columns: 1fr auto 1fr; align-items: center; gap: 8px; }
.price-inputs input { width: 100%; min-height: 44px; padding: 0 10px; border: 1px solid var(--line-2); border-radius: var(--r-sm); background: var(--surface); color: var(--ink); font-size: 15px; }
.chips { display: flex; flex-wrap: wrap; gap: 8px; }
.chip { min-height: 36px; padding: 0 14px; border: 1px solid var(--line-2); border-radius: var(--r-pill); background: var(--surface); color: var(--ink); font-size: 14px; font-weight: 500; display: inline-flex; align-items: center; gap: 6px; transition: border-color 0.2s var(--ease), background-color 0.2s var(--ease); }
.chip:hover { border-color: var(--ink-2); }
.chip[aria-pressed="true"] { background: var(--accent); border-color: var(--accent); color: var(--on-accent); }
.check { display: flex; align-items: center; gap: 10px; min-height: 44px; cursor: pointer; font-size: 15px; }
.check input { width: 20px; height: 20px; accent-color: var(--accent); }
.active-filters { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; margin-bottom: 24px; }
@media (max-width: 900px) {
  .shop { grid-template-columns: 1fr; }
  .filters-toggle { display: inline-flex; }
  .filters { position: fixed; z-index: calc(var(--z-drawer) + 1); inset: auto 0 0 0; top: auto; max-height: 85dvh; overflow-y: auto; padding: 20px var(--gutter) 24px; background: var(--surface); border-radius: var(--r-lg) var(--r-lg) 0 0; box-shadow: var(--shadow); transform: translateY(100%); transition: transform 0.25s var(--ease); visibility: hidden; }
  .filters.is-open { transform: translateY(0); visibility: visible; }
  .filters-head { display: flex; align-items: center; justify-content: space-between; }
  .filters-head h2 { font-size: 24px; }
}

/* =========================================================
   Product details
   ========================================================= */
.pdp { display: grid; grid-template-columns: minmax(0, 1.1fr) minmax(0, 1fr); gap: 64px; align-items: start; }
.gallery { display: flex; flex-direction: column; gap: 12px; position: sticky; top: calc(var(--header-h) + 24px); }
.gallery-main { position: relative; aspect-ratio: 1; border-radius: var(--r-lg); overflow: hidden; background: var(--tint); }
.gallery-nav { position: absolute; top: 50%; transform: translateY(-50%); background: var(--surface) !important; box-shadow: var(--shadow-sm); }
.gallery-prev { left: 12px; }
.gallery-next { right: 12px; }
.thumbs { display: flex; gap: 10px; overflow-x: auto; padding: 2px; }
.thumb { width: 76px; height: 76px; flex-shrink: 0; padding: 0; border: 2px solid transparent; border-radius: var(--r-sm); overflow: hidden; background: var(--tint); transition: border-color 0.2s var(--ease); }
.thumb[aria-current="true"] { border-color: var(--accent); }
.pdp-info { display: flex; flex-direction: column; gap: 20px; }
.pdp-info h1 { font-size: clamp(30px, 4vw, 46px); letter-spacing: -0.035em; }
.pdp-meta { display: flex; flex-wrap: wrap; gap: 8px 16px; align-items: center; font-size: 14px; color: var(--muted); }
.stock { display: inline-flex; align-items: center; gap: 6px; font-weight: 600; font-size: 14px; }
.stock-in { color: var(--ok); }
.stock-low { color: var(--warn); }
.stock-out { color: var(--error); }
.pdp-offer { font-weight: 600; font-size: 15px; color: var(--accent); }
.pdp-desc { color: var(--ink-2); line-height: 1.7; white-space: pre-line; max-width: 60ch; }
.pdp-buy { display: flex; flex-direction: column; gap: 14px; padding: 20px 0; border-top: 1px solid var(--line); border-bottom: 1px solid var(--line); }
.pdp-buy-row { display: flex; gap: 12px; align-items: center; flex-wrap: wrap; }
.pdp-buy-row .btn-primary { flex: 1; min-width: 180px; }
.try-cta { display: flex; gap: 16px; align-items: center; padding: 16px 18px; border-radius: var(--r); background: var(--accent-soft); color: var(--ink); text-decoration: none; transition: background-color 0.2s var(--ease); }
.try-cta:hover { background: color-mix(in srgb, var(--accent-soft) 80%, var(--accent)); color: var(--ink); }
.try-cta-icon { width: 44px; height: 44px; flex-shrink: 0; border-radius: var(--r-sm); background: var(--accent); color: var(--on-accent); display: flex; align-items: center; justify-content: center; }
.try-cta strong { display: block; font-size: 16px; font-weight: 600; }
.try-cta span { font-size: 14px; color: var(--ink-2); }
.try-cta .try-cta-icon { color: var(--on-accent); }
.try-cta > svg:last-child { margin-left: auto; flex-shrink: 0; }
.pdp-actions { display: flex; gap: 8px; flex-wrap: wrap; }
.pdp-details { display: grid; grid-template-columns: auto 1fr; gap: 8px 24px; font-size: 15px; }
.pdp-details dt { color: var(--muted); }
.pdp-details dd { margin: 0; font-weight: 500; }
.related { margin-top: 96px; }
@media (max-width: 900px) { .pdp { grid-template-columns: 1fr; gap: 28px; } .gallery { position: static; } }

/* =========================================================
   Try-on
   ========================================================= */
.tryon { display: grid; grid-template-columns: minmax(0, 1fr) 320px; gap: 40px; align-items: start; }
.stepper { display: flex; gap: 8px; list-style: none; margin: 0 0 28px; padding: 0; flex-wrap: wrap; }
.stepper li { display: flex; align-items: center; gap: 8px; font-size: 14px; font-weight: 500; color: var(--muted); }
.stepper li:not(:last-child)::after { content: ""; width: 28px; height: 1px; background: var(--line-2); margin-left: 4px; }
.step-dot { width: 28px; height: 28px; border-radius: 50%; border: 1.5px solid var(--line-2); display: flex; align-items: center; justify-content: center; font-size: 13px; font-variant-numeric: tabular-nums; }
.stepper li.is-current { color: var(--ink); font-weight: 600; }
.stepper li.is-current .step-dot { background: var(--accent); border-color: var(--accent); color: var(--on-accent); }
.stepper li.is-done .step-dot { background: var(--accent-soft); border-color: var(--accent-soft); color: var(--accent); }
.method-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px; }
.method { display: flex; flex-direction: column; align-items: flex-start; gap: 12px; padding: 28px; border: 1.5px solid var(--line); border-radius: var(--r-lg); background: var(--surface); color: var(--ink); text-align: left; transition: border-color 0.2s var(--ease), transform 0.12s var(--ease); }
.method:hover { border-color: var(--accent); }
.method:active { transform: scale(0.99); }
.method-icon { width: 52px; height: 52px; border-radius: var(--r-sm); background: var(--accent-soft); color: var(--accent); display: flex; align-items: center; justify-content: center; }
.method strong { font-size: 20px; font-weight: 600; letter-spacing: -0.02em; }
.method span { color: var(--muted); font-size: 15px; line-height: 1.5; }
@media (max-width: 640px) { .method-grid { grid-template-columns: 1fr; } .method { padding: 20px; } }
.model-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 14px; }
.model-card { position: relative; padding: 0; border: 3px solid transparent; border-radius: var(--r); overflow: hidden; background: var(--tint); aspect-ratio: 3 / 4; transition: border-color 0.2s var(--ease); }
.model-card img { width: 100%; height: 100%; object-fit: cover; }
.model-card[aria-pressed="true"] { border-color: var(--accent); }
.model-card-check { position: absolute; top: 8px; right: 8px; width: 28px; height: 28px; border-radius: 50%; background: var(--accent); color: var(--on-accent); display: none; align-items: center; justify-content: center; }
.model-card[aria-pressed="true"] .model-card-check { display: flex; }
.model-card-name { display: block; padding-top: 6px; font-size: 13px; font-weight: 500; color: var(--ink-2); text-align: left; }
.model-pick { display: flex; flex-direction: column; }
.dropzone { display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 10px; min-height: 260px; padding: 24px; border: 2px dashed var(--line-2); border-radius: var(--r-lg); background: var(--surface); text-align: center; cursor: pointer; transition: border-color 0.2s var(--ease), background-color 0.2s var(--ease); }
.dropzone:hover, .dropzone.is-over { border-color: var(--accent); background: var(--accent-soft); }
.dropzone:focus-within { outline: 2px solid var(--accent); outline-offset: 2px; }
.dropzone strong { font-size: 17px; }
.dropzone span { color: var(--muted); font-size: 14px; }
.dropzone-icon { width: 52px; height: 52px; border-radius: var(--r-sm); background: var(--accent-soft); color: var(--accent); display: flex; align-items: center; justify-content: center; }
.photo-preview { display: grid; grid-template-columns: 200px 1fr; gap: 20px; align-items: start; }
.photo-preview img { width: 200px; aspect-ratio: 3 / 4; object-fit: cover; border-radius: var(--r); }
.tips { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 10px; }
.tips li { display: flex; gap: 10px; align-items: center; font-size: 15px; }
.tips svg { color: var(--ok); flex-shrink: 0; }
@media (max-width: 560px) { .photo-preview { grid-template-columns: 1fr; } .photo-preview img { width: 100%; max-width: 260px; } }
.tryon-actions { display: flex; gap: 12px; margin-top: 28px; flex-wrap: wrap; }
.tryon-side { position: sticky; top: calc(var(--header-h) + 24px); display: flex; flex-direction: column; gap: 14px; padding: 20px; border-radius: var(--r-lg); background: var(--surface); }
.tryon-side h2 { font-size: 15px; font-weight: 600; letter-spacing: 0; }
.mini-item { display: flex; gap: 12px; align-items: center; }
.mini-item-img { width: 56px; height: 56px; flex-shrink: 0; border-radius: var(--r-sm); overflow: hidden; }
.mini-item-name { font-weight: 500; font-size: 14px; line-height: 1.3; color: var(--ink); }
.mini-item .price-now { font-size: 14px; }
.generating { display: flex; flex-direction: column; align-items: center; gap: 20px; padding: 64px 16px; text-align: center; }
.generating-art { position: relative; width: 112px; height: 112px; border-radius: 50%; background: var(--accent-soft); color: var(--accent); display: flex; align-items: center; justify-content: center; }
.generating-art::after { content: ""; position: absolute; inset: -6px; border-radius: 50%; border: 3px solid transparent; border-top-color: var(--accent); animation: spin 1.2s linear infinite; }
.generating h2 { font-size: 28px; }
.generating p { color: var(--muted); }
.result { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 32px; align-items: start; }
.result-img { border-radius: var(--r-lg); overflow: hidden; background: var(--tint); aspect-ratio: 3 / 4; }
.result-img img { width: 100%; height: 100%; object-fit: cover; }
.result-info { display: flex; flex-direction: column; gap: 18px; }
.result-info h2 { font-size: 34px; }
.result-note { font-size: 13px; color: var(--muted); }
@media (max-width: 900px) { .tryon { grid-template-columns: 1fr; } .tryon-side { position: static; order: -1; } .result { grid-template-columns: 1fr; } }

/* =========================================================
   Create your look
   ========================================================= */
.look { display: grid; grid-template-columns: minmax(0, 1fr) 320px; gap: 40px; align-items: start; }
.look-options { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 24px 16px; }
.look-option { position: relative; display: flex; flex-direction: column; gap: 10px; padding: 0; border: 0; background: none; color: var(--ink); text-align: left; }
.look-option-img { aspect-ratio: 1; border-radius: var(--r); overflow: hidden; outline: 3px solid transparent; outline-offset: -3px; transition: outline-color 0.2s var(--ease); }
.look-option:hover .look-option-img { outline-color: var(--line-2); }
.look-option[aria-pressed="true"] .look-option-img { outline-color: var(--accent); }
.look-option-name { font-weight: 500; font-size: 14px; line-height: 1.3; }
.look-option .price-now { font-size: 15px; }
.look-option-check { position: absolute; top: 10px; right: 10px; width: 30px; height: 30px; border-radius: 50%; background: var(--accent); color: var(--on-accent); display: none; align-items: center; justify-content: center; }
.look-option[aria-pressed="true"] .look-option-check { display: flex; }
.look-tray { position: sticky; top: calc(var(--header-h) + 24px); display: flex; flex-direction: column; gap: 14px; padding: 20px; border-radius: var(--r-lg); background: var(--surface); }
.look-tray h2 { font-size: 22px; }
.tray-slot { display: flex; gap: 12px; align-items: center; min-height: 56px; }
.tray-slot-img { width: 56px; height: 56px; flex-shrink: 0; border-radius: var(--r-sm); overflow: hidden; background: var(--tint); color: var(--muted); display: flex; align-items: center; justify-content: center; }
.tray-slot-empty .tray-slot-img { border: 1.5px dashed var(--line-2); background: transparent; }
.tray-slot-text { display: flex; flex-direction: column; min-width: 0; font-size: 14px; }
.tray-slot-text strong { font-weight: 500; line-height: 1.3; }
.tray-total { display: flex; justify-content: space-between; padding-top: 14px; border-top: 1px solid var(--line); font-weight: 600; font-size: 17px; }
.look-nav { display: flex; gap: 12px; margin-top: 32px; justify-content: space-between; flex-wrap: wrap; }
@media (max-width: 900px) { .look { grid-template-columns: 1fr; } .look-tray { position: static; } }

/* =========================================================
   Cart & checkout
   ========================================================= */
.cart { display: grid; grid-template-columns: minmax(0, 1fr) 380px; gap: 40px; align-items: start; }
.cart-lines { display: flex; flex-direction: column; background: var(--surface); border-radius: var(--r-lg); padding: 8px 24px; }
.cart-line { display: grid; grid-template-columns: 96px minmax(0, 1fr) auto; gap: 20px; padding: 20px 0; align-items: center; }
.cart-line + .cart-line { border-top: 1px solid var(--line); }
.cart-line-img { width: 96px; height: 96px; border-radius: var(--r-sm); overflow: hidden; }
.cart-line-info { display: flex; flex-direction: column; gap: 6px; min-width: 0; }
.cart-line-name { font-weight: 500; color: var(--ink); text-decoration: none; }
.cart-line-name:hover { text-decoration: underline; color: var(--accent); }
.cart-line-controls { display: flex; gap: 12px; align-items: center; margin-top: 4px; flex-wrap: wrap; }
.cart-line-total { font-weight: 600; font-size: 17px; text-align: right; font-variant-numeric: tabular-nums; }
.cart-line-warn { font-size: 13px; color: var(--error); font-weight: 600; }
@media (max-width: 560px) {
  .cart-lines { padding: 4px 16px; }
  .cart-line { grid-template-columns: 72px minmax(0, 1fr); gap: 14px; }
  .cart-line-img { width: 72px; height: 72px; }
  .cart-line-total { grid-column: 2; text-align: left; }
}
.summary { position: sticky; top: calc(var(--header-h) + 24px); display: flex; flex-direction: column; gap: 14px; padding: 24px; border-radius: var(--r-lg); background: var(--surface); }
.summary h2 { font-size: 24px; }
.summary-row { display: flex; justify-content: space-between; gap: 12px; font-size: 15px; }
.summary-row span:last-child { font-variant-numeric: tabular-nums; }
.summary-total { padding-top: 14px; border-top: 1px solid var(--line); font-size: 19px; font-weight: 600; }
.summary-note { font-size: 13px; color: var(--muted); }
.free-bar { display: flex; flex-direction: column; gap: 6px; font-size: 13px; color: var(--ink-2); }
.free-bar-track { height: 4px; border-radius: 2px; background: var(--tint); overflow: hidden; }
.free-bar-fill { display: block; height: 100%; border-radius: 2px; background: var(--accent); }
.summary-items { display: flex; flex-direction: column; gap: 12px; max-height: 320px; overflow-y: auto; padding: 8px 8px 4px 0; margin-top: -8px; }
.summary-item { display: grid; grid-template-columns: 52px minmax(0, 1fr) auto; gap: 12px; align-items: center; font-size: 14px; }
.summary-item-img { position: relative; width: 52px; height: 52px; }
.summary-item-img .pimg { border-radius: 10px; }
.summary-item-qty { position: absolute; top: -6px; right: -6px; min-width: 20px; height: 20px; padding: 0 5px; border-radius: 10px; background: var(--ink); color: var(--bg); font-size: 11px; font-weight: 700; line-height: 20px; text-align: center; }
@media (max-width: 960px) { .cart { grid-template-columns: 1fr; } .summary { position: static; } }
.checkout-section { display: flex; flex-direction: column; gap: 18px; padding: 28px; border-radius: var(--r-lg); background: var(--surface); }
.checkout-section h2 { display: flex; align-items: center; gap: 12px; font-size: 22px; }
.checkout-num { width: 30px; height: 30px; border-radius: 50%; background: var(--accent-soft); color: var(--accent); font-size: 14px; font-weight: 700; display: flex; align-items: center; justify-content: center; letter-spacing: 0; }
.checkout-sections { display: flex; flex-direction: column; gap: 20px; }
.bank-box { padding: 16px; border-radius: var(--r-sm); background: var(--tint-2); border: 1px solid var(--line); font-size: 14px; line-height: 1.6; white-space: pre-line; }
@media (max-width: 560px) { .checkout-section { padding: 20px 16px; } }

/* =========================================================
   Order confirmation & tracking
   ========================================================= */
.confirm { max-width: 720px; margin: 0 auto; display: flex; flex-direction: column; gap: 24px; }
.confirm-hero { display: flex; flex-direction: column; align-items: center; text-align: center; gap: 14px; padding: 40px 24px; border-radius: var(--r-lg); background: var(--surface); }
.confirm-icon { width: 68px; height: 68px; border-radius: 50%; background: var(--ok-bg); color: var(--ok); display: flex; align-items: center; justify-content: center; }
.confirm-hero h1 { font-size: clamp(30px, 4.6vw, 42px); }
.order-no { font-size: 15px; color: var(--muted); }
.order-no strong { display: block; margin-top: 4px; font-size: 28px; font-weight: 600; color: var(--ink); letter-spacing: 0.01em; font-variant-numeric: tabular-nums; }
.card { padding: 24px; border-radius: var(--r-lg); background: var(--surface); }
.card h2 { font-size: 22px; margin-bottom: 16px; }
.card-actions { display: flex; gap: 12px; flex-wrap: wrap; justify-content: center; }
.timeline { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; }
.tl-step { position: relative; display: grid; grid-template-columns: 32px 1fr; gap: 14px; padding-bottom: 22px; }
.tl-step:last-child { padding-bottom: 0; }
.tl-step:not(:last-child)::before { content: ""; position: absolute; left: 15px; top: 30px; bottom: 0; width: 2px; background: var(--line); }
.tl-step.is-done:not(:last-child)::before { background: var(--accent); }
.tl-dot { width: 32px; height: 32px; border-radius: 50%; border: 2px solid var(--line-2); background: var(--surface); display: flex; align-items: center; justify-content: center; color: var(--on-accent); z-index: 1; }
.tl-step.is-done .tl-dot { background: var(--accent); border-color: var(--accent); }
.tl-step.is-current .tl-dot { border-color: var(--accent); box-shadow: 0 0 0 4px var(--accent-soft); }
.tl-step.is-current .tl-dot::after { content: ""; width: 12px; height: 12px; border-radius: 50%; background: var(--accent); }
.tl-text { display: flex; flex-direction: column; padding-top: 4px; }
.tl-text strong { font-size: 16px; font-weight: 600; }
.tl-step:not(.is-done):not(.is-current) .tl-text strong { color: var(--muted); font-weight: 500; }
.tl-text span { font-size: 13px; color: var(--muted); }
.track-grid { display: grid; grid-template-columns: 360px minmax(0, 1fr); gap: 32px; align-items: start; }
@media (max-width: 860px) { .track-grid { grid-template-columns: 1fr; } }
.order-lines { display: flex; flex-direction: column; gap: 12px; }
.order-line { display: grid; grid-template-columns: 52px minmax(0, 1fr) auto; gap: 12px; align-items: center; font-size: 15px; }
.order-line-img { width: 52px; height: 52px; border-radius: 10px; overflow: hidden; }
.order-totals { display: flex; flex-direction: column; gap: 8px; margin-top: 16px; padding-top: 16px; border-top: 1px solid var(--line); }

/* =========================================================
   Account
   ========================================================= */
.account { display: grid; grid-template-columns: 240px minmax(0, 1fr); gap: 40px; align-items: start; }
.account-nav { display: flex; flex-direction: column; gap: 4px; position: sticky; top: calc(var(--header-h) + 24px); }
.account-nav a, .account-nav button { display: flex; align-items: center; gap: 12px; min-height: 48px; padding: 0 14px; border: 0; border-radius: var(--r-sm); background: none; color: var(--ink-2); text-decoration: none; font-weight: 500; font-size: 15px; text-align: left; transition: background-color 0.2s var(--ease); }
.account-nav a:hover, .account-nav button:hover { background: var(--tint); color: var(--ink); }
.account-nav a.active { background: var(--accent-soft); color: var(--accent); font-weight: 600; }
@media (max-width: 860px) {
  .account { grid-template-columns: 1fr; gap: 20px; }
  .account-nav { position: static; flex-direction: row; overflow-x: auto; gap: 6px; margin: 0 calc(-1 * var(--gutter)); padding: 0 var(--gutter) 4px; }
  .account-nav a, .account-nav button { flex-shrink: 0; min-height: 44px; border: 1px solid var(--line-2); border-radius: var(--r-pill); white-space: nowrap; }
  .account-nav a.active { border-color: var(--accent); }
}
.order-card { display: flex; flex-direction: column; gap: 16px; padding: 20px 24px; border-radius: var(--r-lg); background: var(--surface); }
.order-card-head { display: flex; justify-content: space-between; align-items: flex-start; gap: 12px; flex-wrap: wrap; }
.order-card-head strong { font-size: 17px; font-weight: 600; }
.order-card-thumbs { display: flex; gap: 8px; }
.order-card-thumbs .order-line-img { width: 56px; height: 56px; }
.order-card-foot { display: flex; justify-content: space-between; align-items: center; gap: 12px; flex-wrap: wrap; }
.order-card-detail { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 32px; }
@media (max-width: 640px) { .order-card-detail { grid-template-columns: 1fr; } }
.stack { display: flex; flex-direction: column; gap: 16px; }
.tryon-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 24px 16px; }
.tryon-card { display: flex; flex-direction: column; gap: 10px; }
.tryon-card img { aspect-ratio: 3 / 4; object-fit: cover; border-radius: var(--r); }
.tryon-card-body { display: flex; flex-direction: column; gap: 4px; font-size: 14px; }

/* =========================================================
   Info pages
   ========================================================= */
.prose { display: flex; flex-direction: column; gap: 16px; font-size: 17px; line-height: 1.7; color: var(--ink-2); max-width: 65ch; }
.prose h2 { font-size: 26px; color: var(--ink); margin-top: 20px; }
.faq-list { display: grid; gap: 40px; margin: 0; }
.faq-item { display: grid; grid-template-columns: minmax(0, 5fr) minmax(0, 7fr); gap: 32px; scroll-margin-top: calc(var(--header-h) + 24px); }
.faq-item dt { font-size: 19px; font-weight: 600; letter-spacing: -0.015em; line-height: 1.35; }
.faq-item dd { margin: 0; color: var(--ink-2); line-height: 1.7; max-width: 60ch; }
.faq-item:target dt { color: var(--accent); }
@media (max-width: 720px) { .faq-item { grid-template-columns: 1fr; gap: 8px; } }
.contact-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 16px; }
.contact-card { display: flex; flex-direction: column; gap: 8px; padding: 24px; border-radius: var(--r-lg); background: var(--surface); color: var(--ink); text-decoration: none; transition: box-shadow 0.2s var(--ease); }
a.contact-card:hover { color: var(--ink); box-shadow: 0 0 0 1.5px var(--accent); }
.contact-card-icon { color: var(--accent); margin-bottom: 4px; }
.contact-card strong { font-size: 17px; font-weight: 600; }
.contact-card span { color: var(--muted); font-size: 15px; word-break: break-word; }
.not-found { display: flex; flex-direction: column; align-items: center; text-align: center; gap: 16px; padding: 96px var(--gutter); }
.not-found h1 { font-size: clamp(40px, 6vw, 64px); }
.not-found p { color: var(--muted); max-width: 46ch; }
.not-found-art { color: var(--accent); }

/* =========================================================
   Auth pages
   ========================================================= */
.auth { min-height: 100dvh; display: grid; grid-template-columns: minmax(0, 5fr) minmax(0, 6fr); background: var(--bg); }
.auth-aside { position: relative; display: flex; flex-direction: column; justify-content: space-between; gap: 32px; padding: 32px; margin: 16px 0 16px 16px; border-radius: var(--r-lg); background: var(--surface-2); overflow: hidden; }
.auth-photo { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; }
.auth-aside.has-photo::after { content: ""; position: absolute; inset: 0; background: linear-gradient(180deg, rgba(8, 16, 13, 0.35) 0%, rgba(8, 16, 13, 0) 30%, rgba(8, 16, 13, 0) 45%, rgba(8, 16, 13, 0.78) 100%); }
.auth-aside > :not(.auth-photo) { position: relative; z-index: 1; }
.auth-logo { font-size: 22px; font-weight: 700; letter-spacing: -0.03em; color: var(--ink) !important; text-decoration: none; }
.auth-aside-body { max-width: 420px; color: var(--ink-2); }
.auth-aside-body h2 { margin: 0 0 12px; font-size: 40px; letter-spacing: -0.035em; color: var(--ink); }
.auth-aside-body p { font-size: 17px; line-height: 1.6; }
.auth-aside.has-photo .auth-logo, .auth-aside.has-photo .auth-aside-body h2 { color: #f4f7f5 !important; }
.auth-aside.has-photo .auth-aside-body { color: #dfe7e3; }
.auth-main { padding: 48px 24px; display: flex; align-items: center; justify-content: center; }
.auth-card { width: 100%; max-width: 420px; }
.auth-card h1 { margin: 0 0 8px; font-size: 38px; letter-spacing: -0.035em; }
.auth-sub { margin: 0 0 32px; color: var(--muted); line-height: 1.5; }
.auth-switch { margin: 20px 0 0; text-align: center; font-size: 15px; color: var(--muted); }
.auth-switch a { font-weight: 600; }
@media (max-width: 860px) {
  .auth { grid-template-columns: 1fr; }
  .auth-aside { margin: 0; border-radius: 0; padding: 16px 24px; background: transparent; border-bottom: 1px solid var(--line); }
  .auth-aside.has-photo::after, .auth-photo, .auth-aside-body { display: none; }
  .auth-aside.has-photo .auth-logo { color: var(--ink) !important; }
  .auth-main { align-items: flex-start; padding-top: 40px; }
}

/* =========================================================
   Admin shell (shares tokens; layout unchanged)
   ========================================================= */
.admin-shell { min-height: 100dvh; display: grid; grid-template-columns: 248px minmax(0, 1fr); background: linear-gradient(to right, var(--side-bg) 248px, var(--bg) 248px); }
.admin-side { position: sticky; top: 0; height: 100dvh; display: flex; flex-direction: column; gap: 28px; padding: 24px 16px; background: var(--side-bg); color: var(--side-ink); overflow-y: auto; }
.admin-logo { padding: 0 12px; font-size: 20px; font-weight: 700; letter-spacing: -0.03em; color: #f1f5f3 !important; text-decoration: none; }
.admin-nav { display: flex; flex-direction: column; gap: 2px; flex: 1; }
.admin-nav a, .admin-side-link { display: flex; align-items: center; gap: 12px; min-height: 44px; padding: 0 12px; border: 0; border-radius: 10px; background: transparent; color: var(--side-ink); font-size: 15px; font-weight: 500; text-decoration: none; text-align: left; width: 100%; transition: background-color 0.2s var(--ease); }
.admin-nav a:hover, .admin-side-link:hover { background: rgba(255, 255, 255, 0.07); color: #f1f5f3; }
.admin-nav a.active { background: #dcebe4; color: #0a3a2c; font-weight: 600; }
.admin-nav-count { margin-left: auto; min-width: 22px; height: 22px; padding: 0 6px; border-radius: 11px; background: #4fbf97; color: #06130e; font-size: 12px; font-weight: 700; line-height: 22px; text-align: center; }
.admin-side-foot { display: flex; flex-direction: column; gap: 2px; padding-top: 16px; border-top: 1px solid var(--side-line); }
.admin-main { min-width: 0; display: flex; flex-direction: column; }
.admin-top { height: 64px; display: flex; align-items: center; justify-content: flex-end; gap: 12px; padding: 0 32px; background: var(--surface); border-bottom: 1px solid var(--line); }
.admin-menu { display: none; margin-right: auto; }
.admin-user { display: flex; align-items: center; gap: 8px; font-size: 14px; font-weight: 600; }
.admin-content { padding: 32px; }
.admin-scrim { display: none; }
@media (max-width: 900px) {
  .admin-shell { grid-template-columns: 1fr; background: var(--bg); }
  .admin-side { position: fixed; z-index: calc(var(--z-drawer) + 1); left: 0; width: 264px; transform: translateX(-100%); transition: transform 0.25s var(--ease); visibility: hidden; }
  .admin-side.is-open { transform: translateX(0); visibility: visible; }
  .admin-menu { display: inline-flex; }
  .admin-top { padding: 0 12px 0 8px; position: sticky; top: 0; z-index: var(--z-sticky); }
  .admin-content { padding: 20px 16px 64px; }
  .admin-scrim { display: block; position: fixed; inset: 0; z-index: var(--z-drawer); padding: 0; border: 0; background: var(--scrim); }
}
.admin-page { display: flex; flex-direction: column; gap: 24px; max-width: 1240px; }
.admin-head { display: flex; align-items: flex-end; justify-content: space-between; gap: 16px; flex-wrap: wrap; }
.admin-head h1 { font-size: clamp(28px, 3.6vw, 36px); letter-spacing: -0.03em; }
.admin-head p { margin-top: 4px; color: var(--muted); }
.admin-head-actions { display: flex; gap: 10px; flex-wrap: wrap; }
.back-link { display: inline-flex; align-items: center; gap: 6px; font-weight: 600; font-size: 14px; text-decoration: none; min-height: 32px; }
.panel { padding: 22px; border-radius: var(--r); background: var(--surface); border: 1px solid var(--line); min-width: 0; }
.panel-head { display: flex; align-items: baseline; justify-content: space-between; gap: 12px; margin-bottom: 18px; flex-wrap: wrap; }
.panel-head h2 { font-size: 20px; }
.panel-meta { font-size: 14px; color: var(--muted); font-weight: 500; }
.panel-link { font-size: 14px; font-weight: 600; }
.panel-flush { padding: 0; overflow: hidden; }
.toolbar { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
.toolbar .search { flex: 1; min-width: 200px; max-width: 360px; }
.toolbar select { min-height: 44px; padding: 0 12px; border: 1px solid var(--line-2); border-radius: var(--r-pill); background: var(--surface); color: var(--ink); font-size: 14px; font-weight: 500; }
.tabs { display: flex; gap: 6px; overflow-x: auto; padding-bottom: 2px; }
.tab { flex-shrink: 0; display: inline-flex; align-items: center; gap: 8px; min-height: 40px; padding: 0 14px; border: 1px solid var(--line-2); border-radius: var(--r-pill); background: var(--surface); font-size: 14px; font-weight: 500; color: var(--ink); transition: border-color 0.2s var(--ease); }
.tab:hover { border-color: var(--ink-2); }
.tab[aria-pressed="true"] { background: var(--accent); border-color: var(--accent); color: var(--on-accent); }
.tab-count { min-width: 20px; height: 20px; padding: 0 6px; border-radius: 10px; background: var(--tint); color: var(--ink-2); font-size: 12px; font-weight: 700; line-height: 20px; text-align: center; }
.tab[aria-pressed="true"] .tab-count { background: color-mix(in srgb, var(--on-accent) 20%, transparent); color: var(--on-accent); }

.table-scroll { overflow-x: auto; }
.table { width: 100%; border-collapse: collapse; font-size: 14px; }
.table th, .table td { padding: 12px 14px; border-bottom: 1px solid var(--line); text-align: left; vertical-align: middle; white-space: nowrap; }
.table th { font-size: 13px; font-weight: 600; color: var(--muted); background: var(--tint-2); }
.table tbody tr:last-child td { border-bottom: 0; }
.table tbody tr { transition: background-color 0.15s var(--ease); }
.table tbody tr:hover td { background: var(--tint-2); }
.table a { font-weight: 600; }
.table .num { text-align: right; font-variant-numeric: tabular-nums; }
.table-thumb { width: 44px; height: 44px; border-radius: 8px; overflow: hidden; flex-shrink: 0; }
.cell-product { display: flex; align-items: center; gap: 12px; }
.cell-product strong { display: block; }
.row-actions { display: flex; gap: 4px; justify-content: flex-end; }
.is-hidden-row td { color: var(--muted); }
.stock-num-low { color: var(--warn); font-weight: 700; }
.stock-num-out { color: var(--error); font-weight: 700; }

.admin-form { display: grid; grid-template-columns: minmax(0, 1fr) 340px; gap: 24px; align-items: start; }
.admin-form-main, .admin-form-side { display: flex; flex-direction: column; gap: 20px; }
.admin-form-side { position: sticky; top: 88px; }
@media (max-width: 1100px) { .admin-form { grid-template-columns: 1fr; } .admin-form-side { position: static; } }
.save-bar { position: sticky; bottom: 0; z-index: 20; display: flex; justify-content: flex-end; gap: 10px; margin: 0 -32px -32px; padding: 14px 32px; background: var(--surface); border-top: 1px solid var(--line); }
@media (max-width: 900px) { .save-bar { margin: 0 -16px -64px; padding: 12px 16px; } }
.image-manager { display: grid; grid-template-columns: repeat(auto-fill, minmax(120px, 1fr)); gap: 12px; }
.im-tile { position: relative; aspect-ratio: 1; border-radius: var(--r-sm); overflow: hidden; background: var(--tint); }
.im-tile img { width: 100%; height: 100%; object-fit: cover; }
.im-tile-main, .im-tile-new { position: absolute; left: 6px; top: 6px; padding: 2px 8px; border-radius: 10px; font-size: 11px; font-weight: 700; }
.im-tile-main { background: var(--accent); color: var(--on-accent); }
.im-tile-new { background: var(--surface); color: var(--ink); }
.im-tile-actions { position: absolute; right: 4px; bottom: 4px; display: flex; gap: 4px; }
.im-tile-actions .icon-btn { width: 36px; height: 36px; background: var(--surface); box-shadow: var(--shadow-sm); }
.im-add { position: relative; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 6px; aspect-ratio: 1; border: 2px dashed var(--line-2); border-radius: var(--r-sm); background: var(--surface); color: var(--accent); font-size: 13px; font-weight: 600; cursor: pointer; text-align: center; padding: 8px; }
.im-add:hover { border-color: var(--accent); background: var(--accent-soft); }
.im-add:focus-within { outline: 2px solid var(--accent); outline-offset: 2px; }
.im-add input { position: absolute; opacity: 0; width: 1px; height: 1px; }
.asset-row { display: flex; gap: 14px; align-items: center; }
.asset-preview { width: 88px; height: 88px; flex-shrink: 0; border-radius: var(--r-sm); background: repeating-conic-gradient(var(--tint) 0% 25%, var(--surface) 0% 50%) 50% / 16px 16px; overflow: hidden; display: flex; align-items: center; justify-content: center; color: var(--muted); }
.asset-preview img { width: 100%; height: 100%; object-fit: contain; }
.gallery-admin { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 16px; }
.model-admin { display: flex; flex-direction: column; gap: 10px; padding: 8px 8px 12px; border-radius: var(--r); background: var(--surface); border: 1px solid var(--line); }
.model-admin img { aspect-ratio: 3 / 4; object-fit: cover; border-radius: 10px; }
.model-admin.is-off img { opacity: 0.45; }
.model-admin-body { display: flex; justify-content: space-between; align-items: center; gap: 8px; padding: 0 4px; }
.model-admin-body strong { font-size: 15px; }
.model-admin-actions { display: flex; gap: 6px; padding: 0 4px; }
.detail-grid { display: grid; grid-template-columns: minmax(0, 1fr) 360px; gap: 20px; align-items: start; }
.detail-side { display: flex; flex-direction: column; gap: 20px; }
@media (max-width: 1100px) { .detail-grid { grid-template-columns: 1fr; } }
.kv { display: grid; grid-template-columns: auto 1fr; gap: 8px 16px; font-size: 15px; }
.kv dt { color: var(--muted); }
.kv dd { margin: 0; font-weight: 500; min-width: 0; word-break: break-word; }
.contact-actions { display: flex; gap: 8px; flex-wrap: wrap; margin-top: 12px; }
.status-actions { display: flex; flex-direction: column; gap: 10px; }
.cat-row-img { width: 44px; height: 44px; border-radius: var(--r-sm); overflow: hidden; background: var(--accent-soft); color: var(--accent); display: flex; align-items: center; justify-content: center; flex-shrink: 0; font-weight: 700; }
.cat-row-img img { width: 100%; height: 100%; object-fit: cover; }

.stats { display: grid; grid-template-columns: 1.4fr repeat(3, minmax(0, 1fr)); gap: 16px; }
.stat { display: flex; flex-direction: column; gap: 6px; padding: 22px; border-radius: var(--r); background: var(--surface); border: 1px solid var(--line); color: var(--ink); text-decoration: none; transition: border-color 0.2s var(--ease); }
.stat-label { font-size: 14px; font-weight: 500; color: var(--muted); }
.stat-value { font-size: 34px; font-weight: 600; letter-spacing: -0.03em; line-height: 1.1; font-variant-numeric: tabular-nums; }
.stat-note { font-size: 13px; color: var(--muted); }
.stat-hero { background: var(--accent); border-color: var(--accent); color: var(--on-accent); }
.stat-hero .stat-label, .stat-hero .stat-note { color: color-mix(in srgb, var(--on-accent) 80%, transparent); }
a.stat:hover { border-color: var(--accent); color: var(--ink); }
.stat-link .stat-note { color: var(--accent); font-weight: 600; }
@media (max-width: 1100px) { .stats { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
@media (max-width: 520px) { .stats { grid-template-columns: 1fr; } .stat-value { font-size: 30px; } }
.dash-grid { display: grid; grid-template-columns: minmax(0, 2fr) minmax(0, 1fr); gap: 16px; }
.panel-wide { grid-column: 1 / -1; }
@media (max-width: 1000px) { .dash-grid { grid-template-columns: 1fr; } }
.stock-list { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; }
.stock-list li { display: flex; align-items: center; justify-content: space-between; gap: 12px; padding: 12px 0; }
.stock-list li + li { border-top: 1px solid var(--line); }
.stock-name { display: flex; flex-direction: column; gap: 2px; font-weight: 500; min-width: 0; }
.stock-name .muted { font-size: 13px; font-weight: 400; }
a.stock-name { color: var(--ink); text-decoration: none; }
a.stock-name:hover { color: var(--accent); text-decoration: underline; }
.stock-count { flex-shrink: 0; display: inline-flex; align-items: center; gap: 4px; padding: 4px 10px; border-radius: var(--r-pill); background: var(--warn-bg); color: var(--warn); font-size: 13px; font-weight: 600; }
.stock-count.is-out { background: var(--error-bg); color: var(--error); }

.bars { position: relative; display: grid; gap: 10px; padding: 0 0 0 44px; }
.bars-dense { gap: 3px; }
.bars-grid { position: absolute; left: 0; right: 0; top: 0; bottom: 28px; display: flex; flex-direction: column; justify-content: space-between; pointer-events: none; }
.bars-grid span { position: relative; font-size: 12px; color: var(--muted); line-height: 0; font-variant-numeric: tabular-nums; }
.bars-grid span::after { content: ""; position: absolute; left: 44px; right: 0; top: 0; border-top: 1px solid var(--line); }
.bar-col { position: relative; display: flex; flex-direction: column; gap: 8px; min-width: 0; outline: none; }
.bar-track { position: relative; flex: 1; display: flex; align-items: flex-end; justify-content: center; }
.bar { width: min(36px, 72%); min-height: 2px; border-radius: 4px 4px 0 0; background: var(--accent-muted); transition: background-color 0.15s var(--ease); }
.bars-dense .bar { width: 100%; }
.bar.is-highlight { background: var(--accent); }
.bar-col:hover .bar, .bar-col:focus-visible .bar { background: var(--accent-2); }
.bar-col:focus-visible .bar-track { outline: 2px solid var(--accent); outline-offset: 2px; border-radius: 4px; }
.bar-label { height: 20px; font-size: 12px; font-weight: 500; color: var(--muted); text-align: center; white-space: nowrap; overflow: visible; }
.bar-tip { position: absolute; z-index: 2; bottom: 50%; left: 50%; transform: translateX(-50%); display: none; flex-direction: column; gap: 2px; padding: 8px 12px; border-radius: 8px; background: var(--ink); color: var(--bg); font-size: 12px; white-space: nowrap; pointer-events: none; }
.bar-tip.tip-left { left: auto; right: 0; transform: none; }
.bar-tip.tip-right { left: 0; transform: none; }
.bar-tip strong { font-size: 14px; }
.bar-col:hover .bar-tip, .bar-col:focus-visible .bar-tip { display: flex; }
.hbars { display: flex; flex-direction: column; gap: 12px; }
.hbar { display: grid; grid-template-columns: 110px minmax(0, 1fr) 44px; gap: 12px; align-items: center; font-size: 14px; color: var(--ink); text-decoration: none; }
.hbar:hover { color: var(--accent); }
.hbar-track { height: 10px; }
.hbar-fill { display: block; height: 100%; border-radius: 0 4px 4px 0; background: var(--accent-muted); min-width: 2px; }
.hbar-value { text-align: right; font-weight: 600; font-variant-numeric: tabular-nums; }
.rank-list { list-style: none; margin: 0; padding: 0; counter-reset: rank; display: flex; flex-direction: column; }
.rank-list li { counter-increment: rank; display: grid; grid-template-columns: 28px minmax(0, 1fr) auto; gap: 10px; align-items: center; padding: 10px 0; font-size: 14px; }
.rank-list li + li { border-top: 1px solid var(--line); }
.rank-list li::before { content: counter(rank); width: 24px; height: 24px; border-radius: 50%; background: var(--accent-soft); color: var(--accent); font-size: 12px; font-weight: 700; display: flex; align-items: center; justify-content: center; }
.rank-list strong { font-variant-numeric: tabular-nums; }
.report-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px; }
@media (max-width: 900px) { .report-grid { grid-template-columns: 1fr; } }

/* Print (order packing slip) */
.print-only { display: none; }
@media print {
  :root { color-scheme: light; }
  body { background: #fff; color: #111; }
  .admin-side, .admin-top, .no-print, .toasts, .save-bar { display: none !important; }
  .admin-shell { display: block; background: #fff; }
  .admin-content { padding: 0; }
  .print-only { display: block; }
  .panel { border: 1px solid #ccc; break-inside: avoid; }
  .detail-grid { grid-template-columns: 1fr; }
}
'@

Write-ProjectFile 'frontend\src\components\AuthShell.tsx' @'
import { ReactNode, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../api/client";
import { useSettings } from "../context/SettingsContext";

type Props = { title: string; subtitle: string; aside: ReactNode; children: ReactNode };

export default function AuthShell({ title, subtitle, aside, children }: Props) {
  const s = useSettings();
  const [photo, setPhoto] = useState<string | null>(null);
  useEffect(() => { api.aiModels().then((m) => setPhoto(m[1]?.imageUrl ?? m[0]?.imageUrl ?? null)).catch(() => undefined); }, []);

  return (
    <div className="auth">
      <aside className={`auth-aside ${photo ? "has-photo" : ""}`}>
        {photo && <img className="auth-photo" src={photo} alt="" />}
        <Link to="/" className="auth-logo">{s.shopName}</Link>
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

Write-ProjectFile 'frontend\src\components\BarChart.tsx' @'
import { lkr } from "../api/format";

// One series of bars (sales per period). Hover or focus a bar to see its value; a hidden table
// gives screen readers the same numbers.
type Bar = { key: string; label: string; fullLabel: string; value: number; orders: number; highlight?: boolean };

const short = (n: number) => (n >= 1_000_000 ? `${Math.round(n / 100_000) / 10}M` : n >= 1000 ? `${Math.round(n / 100) / 10}k` : String(n));

export default function BarChart({ bars, caption, height = 240 }: { bars: Bar[]; caption: string; height?: number }) {
  const max = Math.max(...bars.map((b) => b.value), 1);
  const dense = bars.length > 14;
  return (
    <>
      <div className={`bars ${dense ? "bars-dense" : ""}`} style={{ height, gridTemplateColumns: `repeat(${bars.length}, minmax(0, 1fr))` }}
        role="img" aria-label={`${caption}. Values are in the table that follows.`}>
        <div className="bars-grid" aria-hidden="true">
          <span>{short(max)}</span>
          <span>{short(Math.round(max / 2))}</span>
          <span>0</span>
        </div>
        {bars.map((b, i) => (
          <div key={b.key} className="bar-col" tabIndex={0} aria-label={`${b.fullLabel}: ${lkr(b.value)}, ${b.orders} orders`}>
            <div className="bar-track">
              <div className={`bar ${b.highlight ? "is-highlight" : ""}`} style={{ height: `${(b.value / max) * 100}%` }} />
              <div className={`bar-tip ${i > bars.length * 0.7 ? "tip-left" : i < bars.length * 0.3 ? "tip-right" : ""}`} role="tooltip">
                <strong>{lkr(b.value)}</strong>
                <span>{b.orders} {b.orders === 1 ? "order" : "orders"} · {b.fullLabel}</span>
              </div>
            </div>
            <span className="bar-label">{dense && i % 5 !== 0 && i !== bars.length - 1 ? "" : b.label}</span>
          </div>
        ))}
      </div>
      <div className="sr-only">
        <table>
          <caption>{caption}</caption>
          <thead><tr><th>Period</th><th>Sales</th><th>Orders</th></tr></thead>
          <tbody>{bars.map((b) => <tr key={b.key}><td>{b.fullLabel}</td><td>{lkr(b.value)}</td><td>{b.orders}</td></tr>)}</tbody>
        </table>
      </div>
    </>
  );
}
'@

Write-ProjectFile 'frontend\src\components\Icon.tsx' @'
import type { Icon as PhosphorIcon } from "@phosphor-icons/react";
import {
  ArrowLeftIcon, ArrowsClockwiseIcon, BankIcon, CameraIcon, CaretDownIcon, CaretLeftIcon, CaretRightIcon, ChartBarIcon,
  ChatCircleIcon, CheckCircleIcon, CheckIcon, ClockIcon, CreditCardIcon, DiamondIcon, DownloadSimpleIcon, EnvelopeIcon,
  EyeIcon, EyeSlashIcon, FunnelIcon, GearIcon, GiftIcon, HandbagIcon, HeartIcon, HouseIcon, ImageIcon, ListIcon, LockIcon,
  MagnifyingGlassIcon, MapPinIcon, MinusIcon, MoneyIcon, PackageIcon, PencilSimpleIcon, PersonSimpleIcon, PhoneIcon,
  PlusIcon, PrinterIcon, ShareNetworkIcon, SignOutIcon, SparkleIcon, SquaresFourIcon, StorefrontIcon, TagIcon, TrashIcon,
  TruckIcon, UploadSimpleIcon, UserIcon, UsersThreeIcon, WarningIcon, XIcon,
} from "@phosphor-icons/react";

// One icon set (Phosphor) for the whole site, used through short names.
const icons = {
  dashboard: SquaresFourIcon, products: DiamondIcon, diamond: DiamondIcon, sparkle: SparkleIcon, orders: PackageIcon,
  bag: HandbagIcon, categories: SquaresFourIcon, customers: UsersThreeIcon, reports: ChartBarIcon, offers: TagIcon,
  settings: GearIcon, model: PersonSimpleIcon, logout: SignOutIcon, store: StorefrontIcon, home: HouseIcon, eye: EyeIcon,
  eyeOff: EyeSlashIcon, alert: WarningIcon, menu: ListIcon, user: UserIcon, heart: HeartIcon, search: MagnifyingGlassIcon,
  close: XIcon, check: CheckIcon, checkCircle: CheckCircleIcon, chevronLeft: CaretLeftIcon, chevronRight: CaretRightIcon,
  chevronDown: CaretDownIcon, arrowLeft: ArrowLeftIcon, plus: PlusIcon, minus: MinusIcon, trash: TrashIcon,
  edit: PencilSimpleIcon, upload: UploadSimpleIcon, camera: CameraIcon, image: ImageIcon, share: ShareNetworkIcon,
  download: DownloadSimpleIcon, filter: FunnelIcon, truck: TruckIcon, cash: MoneyIcon, bank: BankIcon, card: CreditCardIcon,
  chat: ChatCircleIcon, phone: PhoneIcon, mail: EnvelopeIcon, pin: MapPinIcon, clock: ClockIcon, print: PrinterIcon,
  refresh: ArrowsClockwiseIcon, lock: LockIcon, gift: GiftIcon,
} satisfies Record<string, PhosphorIcon>;

export type IconName = keyof typeof icons;

export default function Icon({ name, size = 20, filled = false }: { name: IconName; size?: number; filled?: boolean }) {
  const C = icons[name];
  return <C size={size} weight={filled ? "fill" : "regular"} aria-hidden="true" focusable="false" />;
}
'@

Write-ProjectFile 'frontend\src\components\Layout.tsx' @'
import { FormEvent, useEffect, useState } from "react";
import { Link, NavLink, Outlet, useLocation, useNavigate } from "react-router-dom";
import { useCart } from "../context/CartContext";
import { useAuth } from "../context/AuthContext";
import { useWishlist } from "../context/WishlistContext";
import { useSettings } from "../context/SettingsContext";
import { phoneLink, whatsappLink } from "../api/format";
import Icon from "./Icon";

const links = [
  { to: "/", label: "Home", end: true },
  { to: "/shop", label: "Shop" },
  { to: "/shop?newArrivals=1", label: "New arrivals" },
  { to: "/shop?onSale=1", label: "Offers" },
  { to: "/build-look", label: "Create your look" },
  { to: "/about", label: "About" },
  { to: "/contact", label: "Contact" },
];

function SearchForm({ onDone, id }: { onDone?: () => void; id: string }) {
  const nav = useNavigate();
  const submit = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const q = String(new FormData(e.currentTarget).get("q") || "").trim();
    nav(q ? `/shop?q=${encodeURIComponent(q)}` : "/shop");
    onDone?.();
  };
  return (
    <form className="search" role="search" onSubmit={submit}>
      <label htmlFor={id} className="sr-only">Search jewellery</label>
      <Icon name="search" size={18} />
      <input id={id} name="q" type="search" placeholder="Search jewellery or code" />
    </form>
  );
}

export default function Layout() {
  const { count } = useCart();
  const { user, logout } = useAuth();
  const { ids } = useWishlist();
  const s = useSettings();
  const loc = useLocation();
  const [menu, setMenu] = useState(false);

  useEffect(() => { setMenu(false); window.scrollTo(0, 0); }, [loc.pathname, loc.search]);
  useEffect(() => {
    document.body.style.overflow = menu ? "hidden" : "";
    return () => { document.body.style.overflow = ""; };
  }, [menu]);

  const isActive = (to: string) => {
    const [path, query] = to.split("?");
    if (query) return loc.pathname === path && loc.search.includes(query);
    if (path === "/shop") return loc.pathname.startsWith("/shop") && !/newArrivals|onSale/.test(loc.search);
    return undefined;
  };

  return (
    <div className="site">
      <a href="#main" className="skip-link">Skip to content</a>
      <header className="site-header">
        <div className="header-row">
          <button className="icon-btn header-menu" aria-label="Open menu" aria-expanded={menu} aria-controls="mobile-menu" onClick={() => setMenu(true)}>
            <Icon name="menu" />
          </button>
          <Link to="/" className="brand">{s.shopName}</Link>
          <nav className="main-nav" aria-label="Main">
            {links.map((l) => {
              const active = isActive(l.to);
              return (
                <NavLink key={l.to} to={l.to} end={l.end}
                  className={({ isActive: a }) => ((active ?? a) ? "active" : "")}>
                  {l.label}
                </NavLink>
              );
            })}
          </nav>
          <div className="header-search"><SearchForm id="search-desktop" /></div>
          <div className="header-icons">
            <Link to={user ? "/account/wishlist" : "/login"} className="icon-btn header-icon" aria-label={`Wishlist${ids.size ? `, ${ids.size} items` : ""}`}>
              <Icon name="heart" />
              {ids.size > 0 && <span className="count-badge">{ids.size}</span>}
            </Link>
            <Link to="/cart" className="icon-btn header-icon" aria-label={`Cart, ${count} ${count === 1 ? "item" : "items"}`}>
              <Icon name="bag" />
              {count > 0 && <span className="count-badge">{count}</span>}
            </Link>
            {user ? (
              <Link to={user.role === "ADMIN" ? "/admin" : "/account"} className="icon-btn header-icon" aria-label={user.role === "ADMIN" ? "Admin" : "My account"}>
                <Icon name="user" />
              </Link>
            ) : (
              <Link to="/login" state={{ from: loc.pathname + loc.search }} className="icon-btn header-signin" aria-label="Sign in"><Icon name="user" /><span className="header-signin-label" aria-hidden="true">Sign in</span></Link>
            )}
          </div>
        </div>
      </header>

      {menu && <button className="drawer-scrim" aria-label="Close menu" onClick={() => setMenu(false)} />}
      <aside id="mobile-menu" className={`drawer ${menu ? "is-open" : ""}`} aria-label="Menu" aria-hidden={!menu}>
        <div className="drawer-head">
          <span className="brand">{s.shopName}</span>
          <button className="icon-btn" aria-label="Close menu" onClick={() => setMenu(false)} tabIndex={menu ? 0 : -1}><Icon name="close" /></button>
        </div>
        {menu && <SearchForm id="search-mobile" onDone={() => setMenu(false)} />}
        <nav className="drawer-nav" aria-label="Mobile">
          {links.map((l) => <NavLink key={l.to} to={l.to} end={l.end} tabIndex={menu ? 0 : -1}>{l.label}</NavLink>)}
          <NavLink to="/track" tabIndex={menu ? 0 : -1}>Track your order</NavLink>
        </nav>
        <div className="drawer-foot">
          {user ? (
            <>
              <Link to={user.role === "ADMIN" ? "/admin" : "/account"} tabIndex={menu ? 0 : -1}>{user.role === "ADMIN" ? "Admin" : "My account"}</Link>
              <button className="btn-link" onClick={logout} tabIndex={menu ? 0 : -1}>Sign out</button>
            </>
          ) : (
            <Link to="/login" className="btn btn-primary btn-block" tabIndex={menu ? 0 : -1}>Sign in</Link>
          )}
        </div>
      </aside>

      <main id="main" className="site-main"><Outlet /></main>

      <footer className="site-footer">
        <div className="footer-inner">
          <div className="footer-brand">
            <Link to="/" className="brand">{s.shopName}</Link>
            <p>{s.tagline}</p>
          </div>
          <div className="footer-col">
            <h2>Help</h2>
            <Link to="/track">Track your order</Link>
            <Link to="/delivery">Delivery and returns</Link>
            <Link to="/faq">FAQ</Link>
            <Link to="/faq#try-on">How AI try-on works</Link>
          </div>
          <div className="footer-col">
            <h2>Contact</h2>
            {s.phone && <a href={phoneLink(s.phone)}>{s.phone}</a>}
            {s.whatsapp && <a href={whatsappLink(s.whatsapp)} target="_blank" rel="noreferrer">WhatsApp {s.whatsapp}</a>}
            {s.email && <a href={`mailto:${s.email}`}>{s.email}</a>}
            {s.address && <span>{s.address}</span>}
            {!s.phone && !s.whatsapp && !s.email && !s.address && <Link to="/contact">Contact us</Link>}
          </div>
        </div>
        <div className="footer-base">
          <span>© {new Date().getFullYear()} {s.shopName}</span>
          <nav className="footer-legal" aria-label="Legal">
            <Link to="/privacy">Privacy</Link>
            <Link to="/terms">Terms</Link>
          </nav>
        </div>
      </footer>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\components\OrderView.tsx' @'
import { Link } from "react-router-dom";
import type { Order, OrderStatus } from "../api/types";
import { customerStatus, dateTime, deliveryLabel, lkr, paymentLabel } from "../api/format";
import Icon from "./Icon";
import { ProductImage } from "./ui";

const flowDelivery: OrderStatus[] = ["PENDING", "CONFIRMED", "PROCESSING", "DISPATCHED", "DELIVERED"];
const flowPickup: OrderStatus[] = ["PENDING", "CONFIRMED", "PROCESSING", "READY", "DELIVERED"];

export function OrderTimeline({ order }: { order: Order }) {
  const history = order.history ?? [];
  const when = (s: OrderStatus) => history.find((h) => h.status === s)?.createdAt;

  if (order.status === "CANCELLED") {
    return (
      <ol className="timeline">
        <li className="tl-step is-done"><span className="tl-dot"><Icon name="check" size={16} /></span><span className="tl-text"><strong>Order received</strong>{when("PENDING") && <span>{dateTime(when("PENDING")!)}</span>}</span></li>
        <li className="tl-step is-current"><span className="tl-dot" /><span className="tl-text"><strong>Cancelled</strong>{when("CANCELLED") && <span>{dateTime(when("CANCELLED")!)}</span>}</span></li>
      </ol>
    );
  }

  const flow = order.deliveryMethod === "PICKUP" ? flowPickup : flowDelivery;
  const reached = history.map((h) => h.status);
  // READY can happen on delivery orders too; place the current step at the furthest reached point.
  const currentIndex = Math.max(flow.indexOf(order.status), ...reached.map((s) => flow.indexOf(s)));
  const labels: Partial<Record<OrderStatus, string>> = order.deliveryMethod === "PICKUP" ? { READY: "Ready to collect", DELIVERED: "Collected" } : {};

  return (
    <ol className="timeline">
      {flow.map((s, i) => {
        const state = i < currentIndex || (i === currentIndex && s === "DELIVERED") ? "is-done" : i === currentIndex ? "is-current" : "";
        return (
          <li key={s} className={`tl-step ${state}`} aria-current={state === "is-current" ? "step" : undefined}>
            <span className="tl-dot">{state === "is-done" && <Icon name="check" size={16} />}</span>
            <span className="tl-text"><strong>{labels[s] ?? customerStatus[s]}</strong>{when(s) && <span>{dateTime(when(s)!)}</span>}</span>
          </li>
        );
      })}
    </ol>
  );
}

export function OrderLines({ order }: { order: Order }) {
  return (
    <>
      <div className="order-lines">
        {order.items.map((i) => (
          <div key={i.id} className="order-line">
            <span className="order-line-img"><ProductImage url={i.product?.images[0]?.url} alt="" /></span>
            <span>{i.product?.slug ? <Link to={`/product/${i.product.slug}`}>{i.name}</Link> : i.name} <span className="muted">× {i.qty}</span></span>
            <span className="num">{lkr(i.price * i.qty)}</span>
          </div>
        ))}
      </div>
      <div className="order-totals">
        <div className="summary-row"><span>Subtotal</span><span>{lkr(order.subtotal)}</span></div>
        <div className="summary-row"><span>{deliveryLabel[order.deliveryMethod]}</span><span>{order.deliveryFee ? lkr(order.deliveryFee) : "Free"}</span></div>
        <div className="summary-row summary-total"><span>Total</span><span>{lkr(order.total)}</span></div>
        <div className="summary-row muted"><span>Payment</span><span>{paymentLabel[order.paymentMethod]}</span></div>
      </div>
    </>
  );
}
'@

Write-ProjectFile 'frontend\src\components\PasswordInput.tsx' @'
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

Write-ProjectFile 'frontend\src\components\ProductCard.tsx' @'
import { Link, useNavigate } from "react-router-dom";
import type { Product } from "../api/types";
import { useCart } from "../context/CartContext";
import { useWishlist } from "../context/WishlistContext";
import Icon from "./Icon";
import { Price, ProductImage } from "./ui";

export default function ProductCard({ p }: { p: Product }) {
  const { add } = useCart();
  const { has, toggle } = useWishlist();
  const nav = useNavigate();
  const saved = has(p.id);
  const soldOut = p.stock <= 0;

  return (
    <article className={`pcard ${soldOut ? "is-soldout" : ""}`}>
      <div className="pcard-media">
        <Link to={`/product/${p.slug}`} className="pcard-link" tabIndex={-1} aria-hidden="true">
          <ProductImage url={p.images[0]?.url} alt={p.name} type={p.jewelleryType} />
        </Link>
        <button className={`pcard-wish ${saved ? "is-on" : ""}`} aria-pressed={saved} aria-label={saved ? `Remove ${p.name} from wishlist` : `Save ${p.name} to wishlist`} onClick={() => toggle(p.id, p.name)}>
          <Icon name="heart" size={20} filled={saved} />
        </button>
      </div>
      <div className="pcard-body">
        <div className="pcard-meta">
          <span>{p.code}</span>
          {p.isNewArrival && !soldOut && <span className="pcard-new">New</span>}
        </div>
        <h3 className="pcard-name"><Link to={`/product/${p.slug}`}>{p.name}</Link></h3>
        <Price price={p.price} pricing={p} />
      </div>
      <div className="pcard-actions">
        <button className="btn btn-primary btn-sm pcard-add" disabled={soldOut} onClick={() => add([{ productId: p.id, qty: 1 }], `${p.name} added to cart`)}>
          {soldOut ? "Sold out" : "Add to cart"}
        </button>
        {p.tryOnEnabled && (
          <button className="btn btn-quiet btn-sm pcard-try" onClick={() => nav(`/try-on?products=${p.id}`)} aria-label={`Try on ${p.name} with AI`} title="Try on with AI">
            <Icon name="sparkle" size={18} />
          </button>
        )}
      </div>
    </article>
  );
}
'@

Write-ProjectFile 'frontend\src\components\RequireAdmin.tsx' @'
import { Navigate, Outlet } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { PageLoading } from "./ui";

export default function RequireAdmin() {
  const { user, loading } = useAuth();
  if (loading) return <PageLoading />;
  if (!user) return <Navigate to="/admin/login" replace />;
  if (user.role !== "ADMIN") return <Navigate to="/" replace />;
  return <Outlet />;
}
'@

Write-ProjectFile 'frontend\src\components\RequireAuth.tsx' @'
import { Navigate, Outlet, useLocation } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { PageLoading } from "./ui";

export default function RequireAuth() {
  const { user, loading } = useAuth();
  const loc = useLocation();
  if (loading) return <PageLoading />;
  if (!user) return <Navigate to="/login" replace state={{ from: loc.pathname }} />;
  return <Outlet />;
}
'@

Write-ProjectFile 'frontend\src\components\Reveal.tsx' @'
import { ElementType, ReactNode, useEffect, useRef, useState } from "react";

// Fades a block in once when it scrolls into view. CSS skips the effect for visitors
// who prefer reduced motion, so the content is simply shown.
export default function Reveal({ as: Tag = "div", index = 0, className = "", children, ...rest }: {
  as?: ElementType; index?: number; className?: string; children: ReactNode; [key: string]: unknown;
}) {
  const ref = useRef<HTMLElement>(null);
  const [shown, setShown] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    if (typeof IntersectionObserver === "undefined") { setShown(true); return; }
    const io = new IntersectionObserver((entries) => {
      if (entries.some((e) => e.isIntersecting)) { setShown(true); io.disconnect(); }
    }, { rootMargin: "0px 0px -10% 0px" });
    io.observe(el);
    return () => io.disconnect();
  }, []);

  return (
    <Tag ref={ref} className={`reveal ${shown ? "is-in" : ""} ${className}`} style={{ "--i": index } as React.CSSProperties} {...rest}>
      {children}
    </Tag>
  );
}
'@

Write-ProjectFile 'frontend\src\components\ui.tsx' @'
import { ReactNode, useEffect, useRef, useState } from "react";
import { Link } from "react-router-dom";
import type { JewelleryType, OrderStatus, Pricing } from "../api/types";
import { lkr, statusLabel } from "../api/format";
import Icon, { IconName } from "./Icon";

/* ---------- Product image with a drawn placeholder ---------- */
export function ProductImage({ url, alt, type, className = "", iconSize = 72 }: { url?: string | null; alt: string; type?: JewelleryType; className?: string; iconSize?: number }) {
  const [failed, setFailed] = useState(false);
  if (url && !failed) return <img src={url} alt={alt} className={`pimg ${className}`} loading="lazy" onError={() => setFailed(true)} />;
  return <span className={`pimg pimg-empty ${className}`} role="img" aria-label={alt} data-type={type}><Icon name="diamond" size={Math.round(iconSize * 0.6)} /></span>;
}

/* ---------- Price with offer ---------- */
export function Price({ price, pricing, size = "md" }: { price: number; pricing?: Pricing; size?: "md" | "lg" }) {
  const sale = pricing?.salePrice;
  return (
    <span className={`price price-${size}`}>
      {sale != null ? (
        <>
          <span className="price-now">{lkr(sale)}</span>
          <s className="price-was"><span className="sr-only">Was </span>{lkr(price)}</s>
          <span className="price-off">{pricing?.offerPercent}% off</span>
        </>
      ) : <span className="price-now">{lkr(price)}</span>}
    </span>
  );
}

/* ---------- Quantity stepper ---------- */
export function QtyStepper({ value, max, onChange, label = "Quantity", disabled }: { value: number; max: number; onChange: (n: number) => void; label?: string; disabled?: boolean }) {
  return (
    <div className="qty" role="group" aria-label={label}>
      <button type="button" className="qty-btn" aria-label="Decrease quantity" disabled={disabled || value <= 1} onClick={() => onChange(value - 1)}><Icon name="minus" size={16} /></button>
      <output className="qty-value" aria-live="polite">{value}</output>
      <button type="button" className="qty-btn" aria-label="Increase quantity" disabled={disabled || value >= max} onClick={() => onChange(value + 1)}><Icon name="plus" size={16} /></button>
    </div>
  );
}

/* ---------- Order status pill ---------- */
export function StatusPill({ status, label }: { status: OrderStatus; label?: string }) {
  return <span className={`pill pill-${status.toLowerCase()}`}>{label ?? statusLabel[status]}</span>;
}

/* ---------- Loading / empty / error ---------- */
export function PageLoading({ label = "Loading…" }: { label?: string }) {
  return <div className="page-loading" role="status"><span className="spinner" aria-hidden="true" />{label}</div>;
}

export function EmptyState({ icon = "search", title, children, action }: { icon?: IconName; title: string; children?: ReactNode; action?: ReactNode }) {
  return (
    <div className="empty-state">
      <span className="empty-icon"><Icon name={icon} size={28} /></span>
      <h2>{title}</h2>
      {children && <p>{children}</p>}
      {action}
    </div>
  );
}

export function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div className="empty-state">
      <span className="empty-icon empty-icon-error"><Icon name="alert" size={28} /></span>
      <h2>That didn't load</h2>
      <p>{message}</p>
      {onRetry && <button className="btn btn-secondary" onClick={onRetry}><Icon name="refresh" size={18} />Try again</button>}
    </div>
  );
}

/* ---------- Pagination ---------- */
export function Pagination({ page, pages, onPage }: { page: number; pages: number; onPage: (p: number) => void }) {
  if (pages <= 1) return null;
  const nums = Array.from({ length: pages }, (_, i) => i + 1).filter((n) => n === 1 || n === pages || Math.abs(n - page) <= 1);
  return (
    <nav className="pager" aria-label="Pages">
      <button className="pager-btn" disabled={page <= 1} onClick={() => onPage(page - 1)} aria-label="Previous page"><Icon name="chevronLeft" size={18} /></button>
      {nums.map((n, i) => (
        <span key={n} className="pager-group">
          {i > 0 && n - nums[i - 1] > 1 && <span className="pager-gap" aria-hidden="true">…</span>}
          <button className={`pager-btn ${n === page ? "is-current" : ""}`} aria-current={n === page ? "page" : undefined} onClick={() => onPage(n)}>{n}</button>
        </span>
      ))}
      <button className="pager-btn" disabled={page >= pages} onClick={() => onPage(page + 1)} aria-label="Next page"><Icon name="chevronRight" size={18} /></button>
    </nav>
  );
}

/* ---------- Modal (native dialog) ---------- */
export function Modal({ open, title, onClose, children, footer, wide }: { open: boolean; title: string; onClose: () => void; children: ReactNode; footer?: ReactNode; wide?: boolean }) {
  const ref = useRef<HTMLDialogElement>(null);
  useEffect(() => {
    const d = ref.current;
    if (!d) return;
    if (open && !d.open) d.showModal();
    if (!open && d.open) d.close();
  }, [open]);
  return (
    <dialog ref={ref} className={`modal ${wide ? "modal-wide" : ""}`} onClose={onClose} onCancel={(e) => { e.preventDefault(); onClose(); }}
      onClick={(e) => { if (e.target === ref.current) onClose(); }}>
      {open && (
        <div className="modal-inner">
          <header className="modal-head">
            <h2>{title}</h2>
            <button className="icon-btn" aria-label="Close" onClick={onClose}><Icon name="close" /></button>
          </header>
          <div className="modal-body">{children}</div>
          {footer && <footer className="modal-foot">{footer}</footer>}
        </div>
      )}
    </dialog>
  );
}

export function ConfirmDialog({ open, title, body, confirmLabel, danger, busy, onConfirm, onClose }: {
  open: boolean; title: string; body: ReactNode; confirmLabel: string; danger?: boolean; busy?: boolean; onConfirm: () => void; onClose: () => void;
}) {
  return (
    <Modal open={open} title={title} onClose={onClose} footer={
      <>
        <button className="btn btn-secondary" onClick={onClose}>Keep it</button>
        <button className={`btn ${danger ? "btn-danger" : "btn-primary"}`} disabled={busy} onClick={onConfirm}>{busy ? "Working…" : confirmLabel}</button>
      </>
    }>
      <p className="modal-text">{body}</p>
    </Modal>
  );
}

/* ---------- Breadcrumb ---------- */
export function Breadcrumb({ items }: { items: { to?: string; label: string }[] }) {
  return (
    <nav className="crumbs" aria-label="Breadcrumb">
      <ol>
        {items.map((it, i) => (
          <li key={i}>
            {it.to && i < items.length - 1 ? <Link to={it.to}>{it.label}</Link> : <span aria-current={i === items.length - 1 ? "page" : undefined}>{it.label}</span>}
          </li>
        ))}
      </ol>
    </nav>
  );
}

/* ---------- Switch (checkbox styled as a toggle) ---------- */
export function Switch({ name, label, hint, defaultChecked, checked, onChange }: { name?: string; label: string; hint?: string; defaultChecked?: boolean; checked?: boolean; onChange?: (v: boolean) => void }) {
  return (
    <label className="switch">
      <input type="checkbox" role="switch" name={name} defaultChecked={defaultChecked} checked={checked} onChange={onChange ? (e) => onChange(e.target.checked) : undefined} />
      <span className="switch-track" aria-hidden="true"><span className="switch-thumb" /></span>
      <span className="switch-text"><span className="switch-label">{label}</span>{hint && <span className="field-hint">{hint}</span>}</span>
    </label>
  );
}
'@

Write-ProjectFile 'frontend\src\api\client.ts' @'
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
'@

Write-ProjectFile 'frontend\src\api\format.ts' @'
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
  PENDING: "Order received", CONFIRMED: "Confirmed", PROCESSING: "Being prepared", READY: "Ready",
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
'@

Write-ProjectFile 'frontend\src\api\types.ts' @'
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
'@

Write-ProjectFile 'frontend\src\pages\Account.tsx' @'
import { FormEvent, useEffect, useState } from "react";
import { Link, NavLink, Navigate, useNavigate, useParams } from "react-router-dom";
import { api } from "../api/client";
import type { Order, Product, SavedTryOn } from "../api/types";
import { customerStatus, lkr, shortDate } from "../api/format";
import { useAuth } from "../context/AuthContext";
import { useToast } from "../context/ToastContext";
import { useWishlist } from "../context/WishlistContext";
import ProductCard from "../components/ProductCard";
import PasswordInput from "../components/PasswordInput";
import Icon from "../components/Icon";
import { EmptyState, ErrorState, PageLoading, ProductImage, StatusPill } from "../components/ui";
import { OrderLines, OrderTimeline } from "../components/OrderView";

function Orders() {
  const [orders, setOrders] = useState<Order[] | null>(null);
  const [err, setErr] = useState("");
  const [open, setOpen] = useState<string | null>(null);
  const load = () => { setErr(""); api.myOrders().then(setOrders).catch((e) => setErr((e as Error).message)); };
  useEffect(load, []);

  if (err) return <ErrorState message={err} onRetry={load} />;
  if (!orders) return <PageLoading />;
  if (!orders.length) return <EmptyState icon="bag" title="No orders yet" action={<Link to="/shop" className="btn btn-primary">Start shopping</Link>}>Orders you place while signed in show here.</EmptyState>;

  return (
    <div className="stack">
      {orders.map((o) => (
        <article key={o.id} className="order-card">
          <div className="order-card-head">
            <div><strong>{o.orderNo}</strong><div className="muted" style={{ fontSize: 14 }}>Placed {shortDate(o.createdAt)} · {o.items.reduce((s, i) => s + i.qty, 0)} pieces</div></div>
            <StatusPill status={o.status} label={customerStatus[o.status]} />
          </div>
          <div className="order-card-thumbs">
            {o.items.slice(0, 5).map((i) => <span key={i.id} className="order-line-img"><ProductImage url={i.product?.images[0]?.url} alt={i.name} /></span>)}
          </div>
          {open === o.id && (
            <div className="track-grid" style={{ gridTemplateColumns: "minmax(0, 1fr) minmax(0, 1fr)" }}>
              <OrderTimeline order={o} />
              <div><OrderLines order={o} /></div>
            </div>
          )}
          <div className="order-card-foot">
            <strong className="num">{lkr(o.total)}</strong>
            <button className="btn btn-quiet btn-sm" aria-expanded={open === o.id} onClick={() => setOpen(open === o.id ? null : o.id)}>
              {open === o.id ? "Hide details" : "View details"}<Icon name="chevronDown" size={16} />
            </button>
          </div>
        </article>
      ))}
    </div>
  );
}

function Wishlist() {
  const { ids } = useWishlist();
  const [items, setItems] = useState<Product[] | null>(null);
  useEffect(() => { api.wishlist().then(setItems).catch(() => setItems([])); }, []);
  if (!items) return <PageLoading />;
  const shown = items.filter((p) => ids.has(p.id));
  if (!shown.length) return <EmptyState icon="heart" title="Your wishlist is empty" action={<Link to="/shop" className="btn btn-primary">Browse jewellery</Link>}>Tap the heart on any piece to save it here.</EmptyState>;
  return <div className="pgrid" style={{ gridTemplateColumns: "repeat(auto-fill, minmax(200px, 1fr))" }}>{shown.map((p) => <ProductCard key={p.id} p={p} />)}</div>;
}

function TryOns() {
  const [items, setItems] = useState<SavedTryOn[] | null>(null);
  useEffect(() => { api.myTryOns().then(setItems).catch(() => setItems([])); }, []);
  if (!items) return <PageLoading />;
  if (!items.length) return <EmptyState icon="sparkle" title="No try-ons yet" action={<Link to="/shop?tryOn=1" className="btn btn-primary">Try something on</Link>}>Previews you create while signed in are saved here.</EmptyState>;
  return (
    <div className="tryon-grid">
      {items.map((t) => {
        const live = t.items.filter((i) => i.product.isActive);
        return (
          <article key={t.id} className="tryon-card">
            <a href={t.resultUrl} target="_blank" rel="noreferrer"><img src={t.resultUrl} alt={`Try-on of ${t.items.map((i) => i.product.name).join(", ")}`} /></a>
            <div className="tryon-card-body">
              {t.items.map((i) => i.product.isActive ? <Link key={i.product.id} to={`/product/${i.product.slug}`}>{i.product.name}</Link> : <span key={i.product.id} className="muted">{i.product.name}</span>)}
              <span className="muted">{shortDate(t.createdAt)}</span>
              {live.length > 0 && <Link to={`/try-on?products=${live.map((i) => i.product.id).join(",")}`} className="btn btn-quiet btn-sm" style={{ marginTop: 6 }}>Try again</Link>}
            </div>
          </article>
        );
      })}
    </div>
  );
}

function Profile() {
  const { user, setUser } = useAuth();
  const { show } = useToast();
  const [err, setErr] = useState("");
  const [pwErr, setPwErr] = useState("");
  const [busy, setBusy] = useState(false);

  const save = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    setErr(""); setBusy(true);
    try {
      setUser(await api.updateMe({ name: String(f.get("name")), phone: String(f.get("phone") || "") }));
      show("Details saved");
    } catch (e) { setErr((e as Error).message); } finally { setBusy(false); }
  };

  const changePw = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const form = e.currentTarget;
    const f = new FormData(form);
    setPwErr("");
    if (f.get("next") !== f.get("confirm")) { setPwErr("The new passwords don't match."); return; }
    try {
      await api.changePassword(String(f.get("current")), String(f.get("next")));
      form.reset();
      show("Password changed");
    } catch (e) { setPwErr((e as Error).message); }
  };

  return (
    <div className="stack" style={{ maxWidth: 560 }}>
      <form className="card form" onSubmit={save}>
        <h2 style={{ marginBottom: 0 }}>Your details</h2>
        <label className="field"><span className="field-label">Full name</span><input name="name" required minLength={2} defaultValue={user?.name} autoComplete="name" /></label>
        <label className="field"><span className="field-label">Email</span><input value={user?.email ?? ""} disabled /><span className="field-hint">Contact us to change your email.</span></label>
        <label className="field"><span className="field-label">Mobile number <span className="optional">(optional)</span></span><input name="phone" type="tel" pattern="0\d{9}" placeholder="07XXXXXXXX" defaultValue={user?.phone ?? ""} autoComplete="tel" /></label>
        {err && <p className="form-error" role="alert">{err}</p>}
        <button className="btn btn-primary" style={{ alignSelf: "flex-start" }} disabled={busy}>Save details</button>
      </form>
      <form className="card form" onSubmit={changePw}>
        <h2 style={{ marginBottom: 0 }}>Change password</h2>
        <PasswordInput name="current" label="Current password" autoComplete="current-password" />
        <PasswordInput name="next" label="New password" autoComplete="new-password" minLength={6} hint="At least 6 characters" />
        <PasswordInput name="confirm" label="Confirm new password" autoComplete="new-password" minLength={6} />
        {pwErr && <p className="form-error" role="alert">{pwErr}</p>}
        <button className="btn btn-secondary" style={{ alignSelf: "flex-start" }}>Change password</button>
      </form>
    </div>
  );
}

const tabs = [
  { key: "", label: "My orders", icon: "bag" as const, title: "My orders" },
  { key: "wishlist", label: "Wishlist", icon: "heart" as const, title: "Wishlist" },
  { key: "try-ons", label: "Saved try-ons", icon: "sparkle" as const, title: "Saved try-ons" },
  { key: "profile", label: "Profile", icon: "user" as const, title: "Profile" },
];

export default function Account() {
  const { tab = "" } = useParams();
  const { user, logout } = useAuth();
  const nav = useNavigate();
  const current = tabs.find((t) => t.key === tab);
  if (!current) return <Navigate to="/account" replace />;
  if (user?.role === "ADMIN") return <Navigate to="/admin" replace />;

  return (
    <div className="page">
      <div className="page-head"><h1>{current.title}</h1><p>Hi {user?.name.split(" ")[0]}.</p></div>
      <div className="account">
        <nav className="account-nav" aria-label="Account">
          {tabs.map((t) => <NavLink key={t.key} to={t.key ? `/account/${t.key}` : "/account"} end><Icon name={t.icon} size={18} />{t.label}</NavLink>)}
          <button onClick={() => { logout(); nav("/"); }}><Icon name="logout" size={18} />Sign out</button>
        </nav>
        <div>
          {tab === "" && <Orders />}
          {tab === "wishlist" && <Wishlist />}
          {tab === "try-ons" && <TryOns />}
          {tab === "profile" && <Profile />}
        </div>
      </div>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\BuildLook.tsx' @'
import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { api } from "../api/client";
import type { JewelleryType, Product } from "../api/types";
import { lkr } from "../api/format";
import { useCart } from "../context/CartContext";
import Icon from "../components/Icon";
import { EmptyState, PageLoading, Price, ProductImage } from "../components/ui";

const steps: { title: string; short: string; types: JewelleryType[] }[] = [
  { title: "Choose earrings", short: "Earrings", types: ["EARRINGS"] },
  { title: "Choose a necklace or chain", short: "Necklace", types: ["NECKLACE", "CHAIN", "LONG_CHAIN"] },
  { title: "Choose bangles or a bracelet", short: "Bangles", types: ["BANGLE", "BRACELET"] },
];

export default function BuildLook() {
  const nav = useNavigate();
  const { add } = useCart();
  const [step, setStep] = useState(0);
  const [options, setOptions] = useState<Product[] | null>(null);
  const [picked, setPicked] = useState<(Product | undefined)[]>([]);

  useEffect(() => {
    if (step >= steps.length) return;
    setOptions(null);
    Promise.all(steps[step].types.map((type) => api.products({ type, inStock: 1, tryOn: 1, limit: 24 })))
      .then((rs) => setOptions(rs.flatMap((r) => r.items)))
      .catch(() => setOptions([]));
  }, [step]);

  const chosen = picked.filter(Boolean) as Product[];
  const total = chosen.reduce((s, p) => s + (p.salePrice ?? p.price), 0);
  const pick = (p: Product) => setPicked((prev) => { const n = [...prev]; n[step] = n[step]?.id === p.id ? undefined : p; return n; });
  const finished = step >= steps.length;

  const tray = (
    <aside className="look-tray" aria-label="Your look">
      <h2>Your look</h2>
      {steps.map((s, i) => {
        const p = picked[i];
        return (
          <div key={s.short} className={`tray-slot ${p ? "" : "tray-slot-empty"}`}>
            <span className="tray-slot-img">{p ? <ProductImage url={p.images[0]?.url} alt="" type={p.jewelleryType} iconSize={28} /> : <Icon name="plus" size={20} />}</span>
            <span className="tray-slot-text">
              {p ? <><strong>{p.name}</strong><span className="muted">{lkr(p.salePrice ?? p.price)}</span></> : <span className="muted">{s.short}: not chosen</span>}
            </span>
          </div>
        );
      })}
      <div className="tray-total"><span>Total</span><span className="num">{lkr(total)}</span></div>
    </aside>
  );

  if (finished) return (
    <div className="page">
      <div className="page-head"><h1>Your look</h1><p>Preview the full set with AI, or add it straight to your cart.</p></div>
      <div className="look">
        {chosen.length ? (
          <div className="stack">
            <div className="look-options">
              {chosen.map((p) => (
                <div key={p.id} className="look-option" style={{ cursor: "default" }}>
                  <span className="look-option-img"><ProductImage url={p.images[0]?.url} alt="" type={p.jewelleryType} /></span>
                  <Link to={`/product/${p.slug}`} className="look-option-name">{p.name}</Link>
                  <Price price={p.price} pricing={p} />
                </div>
              ))}
            </div>
            <div className="look-nav">
              <button className="btn btn-quiet" onClick={() => setStep(0)}><Icon name="edit" size={18} />Change pieces</button>
              <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
                <button className="btn btn-secondary" onClick={() => nav(`/try-on?products=${chosen.map((p) => p.id).join(",")}`)}><Icon name="sparkle" size={18} />Preview with AI</button>
                <button className="btn btn-primary" onClick={async () => { if (await add(chosen.map((p) => ({ productId: p.id, qty: 1 })), "Your look was added to the cart")) nav("/cart"); }}>Add all to cart · {lkr(total)}</button>
              </div>
            </div>
          </div>
        ) : (
          <EmptyState icon="sparkle" title="You haven't picked anything yet" action={<button className="btn btn-primary" onClick={() => setStep(0)}>Start again</button>}>
            Go back and choose at least one piece.
          </EmptyState>
        )}
        {tray}
      </div>
    </div>
  );

  return (
    <div className="page">
      <div className="page-head"><h1>Create your look</h1><p>Choose a piece at each step, or skip any you don't need.</p></div>
      <ol className="stepper" aria-label="Steps">
        {[...steps.map((s) => s.short), "Review"].map((label, i) => (
          <li key={label} className={step === i ? "is-current" : step > i ? "is-done" : ""} aria-current={step === i ? "step" : undefined}>
            <span className="step-dot">{step > i ? <Icon name="check" size={14} /> : i + 1}</span>{label}
          </li>
        ))}
      </ol>
      <div className="look">
        <div>
          <h2 style={{ fontSize: 28, marginBottom: 20 }}>{steps[step].title}</h2>
          {!options ? <PageLoading /> : !options.length ? (
            <p className="empty-note" style={{ textAlign: "left" }}>No pieces available for this step right now. Skip to the next one.</p>
          ) : (
            <div className="look-options">
              {options.map((p) => (
                <button key={p.id} className="look-option" aria-pressed={picked[step]?.id === p.id} onClick={() => pick(p)}>
                  <span className="look-option-img"><ProductImage url={p.images[0]?.url} alt="" type={p.jewelleryType} /></span>
                  <span className="look-option-name">{p.name}</span>
                  <Price price={p.price} pricing={p} />
                  <span className="look-option-check" aria-hidden="true"><Icon name="check" size={16} /></span>
                </button>
              ))}
            </div>
          )}
          <div className="look-nav">
            {step > 0 ? <button className="btn btn-quiet" onClick={() => setStep(step - 1)}><Icon name="arrowLeft" size={18} />Back</button> : <span />}
            <button className="btn btn-primary" onClick={() => setStep(step + 1)}>
              {picked[step] ? (step === steps.length - 1 ? "Review your look" : "Next") : "Skip this step"}<Icon name="chevronRight" size={18} />
            </button>
          </div>
        </div>
        {tray}
      </div>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\Cart.tsx' @'
import { Link } from "react-router-dom";
import { lkr } from "../api/format";
import { useCart } from "../context/CartContext";
import Icon from "../components/Icon";
import { EmptyState, PageLoading, Price, ProductImage, QtyStepper } from "../components/ui";

export function FreeDeliveryBar({ subtotal, over }: { subtotal: number; over: number | null }) {
  if (!over) return null;
  const left = over - subtotal;
  return (
    <div className="free-bar">
      <span>{left > 0 ? <>Add <strong>{lkr(left)}</strong> more for free delivery</> : <strong>You get free delivery</strong>}</span>
      <span className="free-bar-track"><span className="free-bar-fill" style={{ width: `${Math.min(100, (subtotal / over) * 100)}%` }} /></span>
    </div>
  );
}

export default function CartPage() {
  const { cart, setQty, remove } = useCart();
  if (!cart) return <PageLoading />;
  if (!cart.items.length) return (
    <div className="page">
      <EmptyState icon="bag" title="Your cart is empty" action={<Link to="/shop" className="btn btn-primary">Browse jewellery</Link>}>
        Pieces you add will show here.
      </EmptyState>
    </div>
  );

  const blocked = cart.items.some((i) => !i.inStock);
  const count = cart.items.reduce((s, i) => s + i.qty, 0);

  return (
    <div className="page">
      <div className="page-head"><h1>Your cart</h1><p>{count} {count === 1 ? "piece" : "pieces"}</p></div>
      <div className="cart">
        <div className="cart-lines">
          {cart.items.map((i) => (
            <div key={i.id} className="cart-line">
              <Link to={`/product/${i.product.slug}`} className="cart-line-img" tabIndex={-1} aria-hidden="true">
                <ProductImage url={i.product.images[0]?.url} alt="" type={i.product.jewelleryType} />
              </Link>
              <div className="cart-line-info">
                <Link to={`/product/${i.product.slug}`} className="cart-line-name">{i.product.name}</Link>
                <Price price={i.product.price} pricing={i.product} />
                {!i.inStock && <span className="cart-line-warn">{i.product.stock ? `Only ${i.product.stock} left. Lower the quantity to continue.` : "Sold out. Remove it to continue."}</span>}
                <div className="cart-line-controls">
                  <QtyStepper value={i.qty} max={Math.max(1, Math.min(i.product.stock, 20))} onChange={(n) => setQty(i.productId, n)} label={`Quantity of ${i.product.name}`} />
                  <button className="btn-link" onClick={() => remove(i.productId)} style={{ fontSize: 14 }}>Remove</button>
                </div>
              </div>
              <span className="cart-line-total">{lkr(i.lineTotal)}</span>
            </div>
          ))}
        </div>

        <aside className="summary" aria-label="Order summary">
          <h2>Summary</h2>
          <div className="summary-row"><span>Subtotal</span><span>{lkr(cart.subtotal)}</span></div>
          <div className="summary-row"><span>Delivery</span><span>{cart.deliveryFee ? lkr(cart.deliveryFee) : "Free"}</span></div>
          <FreeDeliveryBar subtotal={cart.subtotal} over={cart.freeDeliveryOver} />
          <div className="summary-row summary-total"><span>Total</span><span>{lkr(cart.total)}</span></div>
          <p className="summary-note">Store pickup is free. You'll choose at checkout.</p>
          {blocked ? (
            <button className="btn btn-primary btn-lg btn-block" disabled>Checkout</button>
          ) : (
            <Link to="/checkout" className="btn btn-primary btn-lg btn-block"><Icon name="lock" size={18} />Checkout</Link>
          )}
          <Link to="/shop" className="btn btn-quiet btn-block">Continue shopping</Link>
        </aside>
      </div>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\Checkout.tsx' @'
import { FormEvent, useEffect, useState } from "react";
import { Link, Navigate, useNavigate } from "react-router-dom";
import { api, ApiError } from "../api/client";
import type { DeliveryMethod, PaymentMethod } from "../api/types";
import { lkr, paymentLabel } from "../api/format";
import { useCart } from "../context/CartContext";
import { useAuth } from "../context/AuthContext";
import { useSettings } from "../context/SettingsContext";
import Icon, { IconName } from "../components/Icon";
import { PageLoading, ProductImage } from "../components/ui";
import { FreeDeliveryBar } from "./Cart";

const paymentInfo: Record<PaymentMethod, { icon: IconName; note: string }> = {
  COD: { icon: "cash", note: "Pay in cash when your order arrives." },
  BANK_TRANSFER: { icon: "bank", note: "Transfer the total and send us the slip on WhatsApp." },
  ONLINE: { icon: "card", note: "Pay securely by card." },
};

export default function Checkout() {
  const nav = useNavigate();
  const { cart, refresh } = useCart();
  const { user } = useAuth();
  const s = useSettings();
  const methods = (["COD", "BANK_TRANSFER", "ONLINE"] as PaymentMethod[]).filter((m) => ({ COD: s.codEnabled, BANK_TRANSFER: s.bankEnabled, ONLINE: s.onlineEnabled })[m]);
  const [delivery, setDelivery] = useState<DeliveryMethod>("DELIVERY");
  const [payment, setPayment] = useState<PaymentMethod | "">("");
  const [err, setErr] = useState("");
  const [badField, setBadField] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => { if (!payment && methods.length) setPayment(methods[0]); }, [methods, payment]);

  if (!cart) return <PageLoading />;
  if (!cart.items.length && !busy) return <Navigate to="/cart" replace />;

  const fee = delivery === "DELIVERY" ? cart.deliveryFee : 0;
  const total = cart.subtotal + fee;

  const submit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setErr(""); setBadField("");
    const body = Object.fromEntries(new FormData(e.currentTarget));
    setBusy(true);
    try {
      const order = await api.placeOrder(body);
      await refresh();
      nav(`/order/${order.orderNo}`, { state: order, replace: true });
    } catch (e) {
      setBusy(false);
      setErr((e as Error).message);
      if (e instanceof ApiError && e.field) {
        setBadField(e.field);
        document.querySelector<HTMLInputElement>(`[name="${e.field}"]`)?.focus();
      } else window.scrollTo({ top: 0, behavior: "smooth" });
    }
  };
  const invalid = (name: string) => (badField === name ? { "aria-invalid": true as const } : {});

  return (
    <div className="page">
      <div className="page-head"><h1>Checkout</h1><p>{user ? `Signed in as ${user.email}` : <>Checking out as a guest. <Link to="/login" state={{ from: "/checkout" }}>Sign in</Link> to track orders in your account.</>}</p></div>
      <form className="cart" onSubmit={submit} noValidate={false}>
        <div className="checkout-sections">
          {err && <p className="form-error" role="alert">{err}</p>}

          <section className="checkout-section" aria-labelledby="co-details">
            <h2 id="co-details"><span className="checkout-num">1</span>Your details</h2>
            <div className="form-grid">
              <label className="field span-2"><span className="field-label">Full name</span><input name="fullName" required minLength={2} autoComplete="name" defaultValue={user?.name ?? ""} {...invalid("fullName")} /></label>
              <label className="field"><span className="field-label">Mobile number</span><input name="mobile" type="tel" required pattern="0\d{9}" placeholder="07XXXXXXXX" autoComplete="tel" inputMode="tel" defaultValue={user?.phone ?? ""} {...invalid("mobile")} /><span className="field-hint">We'll call or message about your order</span></label>
              <label className="field"><span className="field-label">WhatsApp number <span className="optional">(optional)</span></span><input name="whatsapp" type="tel" placeholder="If different from mobile" inputMode="tel" /></label>
              <label className="field span-2"><span className="field-label">Email <span className="optional">(optional)</span></span><input name="email" type="email" autoComplete="email" defaultValue={user?.email ?? ""} {...invalid("email")} /></label>
            </div>
          </section>

          <section className="checkout-section" aria-labelledby="co-delivery">
            <h2 id="co-delivery"><span className="checkout-num">2</span>Delivery</h2>
            <fieldset className="fieldset">
              <legend className="sr-only">Delivery method</legend>
              <div className="choices choices-2">
                <label className="choice">
                  <input type="radio" name="deliveryMethod" value="DELIVERY" checked={delivery === "DELIVERY"} onChange={() => setDelivery("DELIVERY")} />
                  <span className="choice-dot" aria-hidden="true" />
                  <span className="choice-body"><span className="choice-title"><Icon name="truck" size={18} />Deliver to me</span><span className="choice-note">{cart.deliveryFee ? lkr(cart.deliveryFee) : "Free"} · islandwide</span></span>
                </label>
                {s.pickupEnabled && (
                  <label className="choice">
                    <input type="radio" name="deliveryMethod" value="PICKUP" checked={delivery === "PICKUP"} onChange={() => setDelivery("PICKUP")} />
                    <span className="choice-dot" aria-hidden="true" />
                    <span className="choice-body"><span className="choice-title"><Icon name="store" size={18} />Store pickup</span><span className="choice-note">Free{s.address ? ` · ${s.address}` : ""}</span></span>
                  </label>
                )}
              </div>
            </fieldset>
            {delivery === "DELIVERY" && (
              <div className="form-grid">
                <label className="field span-2"><span className="field-label">Address</span><textarea name="address" required rows={2} autoComplete="street-address" {...invalid("address")} /></label>
                <label className="field"><span className="field-label">City</span><input name="city" required autoComplete="address-level2" {...invalid("city")} /></label>
                <label className="field"><span className="field-label">Postal code <span className="optional">(optional)</span></span><input name="postalCode" autoComplete="postal-code" inputMode="numeric" /></label>
              </div>
            )}
            <label className="field"><span className="field-label">Order note <span className="optional">(optional)</span></span><textarea name="note" rows={2} placeholder="Gift wrapping, a delivery time, anything we should know" /></label>
          </section>

          <section className="checkout-section" aria-labelledby="co-payment">
            <h2 id="co-payment"><span className="checkout-num">3</span>Payment</h2>
            {methods.length ? (
              <fieldset className="fieldset">
                <legend className="sr-only">Payment method</legend>
                <div className="choices">
                  {methods.map((m) => (
                    <label key={m} className="choice">
                      <input type="radio" name="paymentMethod" value={m} checked={payment === m} onChange={() => setPayment(m)} required />
                      <span className="choice-dot" aria-hidden="true" />
                      <span className="choice-body"><span className="choice-title"><Icon name={paymentInfo[m].icon} size={18} />{paymentLabel[m]}</span><span className="choice-note">{paymentInfo[m].note}</span></span>
                    </label>
                  ))}
                </div>
              </fieldset>
            ) : <p className="form-error">No payment methods are available right now. Contact the shop to order.</p>}
            {payment === "BANK_TRANSFER" && s.bankDetails && <div className="bank-box"><strong>Bank details</strong>{"\n"}{s.bankDetails}</div>}
          </section>
        </div>

        <aside className="summary" aria-label="Order summary">
          <h2>Your order</h2>
          <div className="summary-items">
            {cart.items.map((i) => (
              <div key={i.id} className="summary-item">
                <span className="summary-item-img"><ProductImage url={i.product.images[0]?.url} alt="" type={i.product.jewelleryType} /><span className="summary-item-qty" aria-label={`Quantity ${i.qty}`}>{i.qty}</span></span>
                <span>{i.product.name}</span>
                <span className="num">{lkr(i.lineTotal)}</span>
              </div>
            ))}
          </div>
          <div className="summary-row"><span>Subtotal</span><span>{lkr(cart.subtotal)}</span></div>
          <div className="summary-row"><span>Delivery</span><span>{fee ? lkr(fee) : "Free"}</span></div>
          {delivery === "DELIVERY" && <FreeDeliveryBar subtotal={cart.subtotal} over={cart.freeDeliveryOver} />}
          <div className="summary-row summary-total"><span>Total</span><span>{lkr(total)}</span></div>
          <button className="btn btn-primary btn-lg btn-block" disabled={busy || !methods.length}>{busy ? "Placing order…" : `Place order · ${lkr(total)}`}</button>
          <p className="summary-note">We'll confirm your order by phone or WhatsApp before it's sent.</p>
        </aside>
      </form>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\Home.tsx' @'
import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../api/client";
import type { Category, JewelleryType, Product } from "../api/types";
import { lkr } from "../api/format";
import { useSettings } from "../context/SettingsContext";
import ProductCard from "../components/ProductCard";
import Icon from "../components/Icon";
import Reveal from "../components/Reveal";

const lookTypes: { label: string; types: JewelleryType[] }[] = [
  { label: "Earrings", types: ["EARRINGS"] },
  { label: "Necklace", types: ["NECKLACE", "CHAIN", "LONG_CHAIN"] },
  { label: "Bangles", types: ["BANGLE", "BRACELET"] },
];

export default function Home() {
  const s = useSettings();
  const [cats, setCats] = useState<Category[]>([]);
  const [fresh, setFresh] = useState<Product[]>([]);
  const [sale, setSale] = useState<Product[]>([]);
  const [models, setModels] = useState<string[]>([]);
  const [lookPieces, setLookPieces] = useState<{ label: string; p: Product }[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      api.categories().then(setCats),
      api.products({ newArrivals: 1, limit: 8 }).then(async (r) => {
        // Fall back to the newest pieces when nothing is marked as a new arrival.
        setFresh(r.items.length ? r.items : (await api.products({ limit: 8 })).items);
      }),
      api.products({ onSale: 1, limit: 12 }).then((r) => setSale(r.items)),
      api.aiModels().then((m) => setModels(m.map((x) => x.imageUrl))),
      Promise.all(lookTypes.map(async (t) => {
        const found = (await Promise.all(t.types.map((type) => api.products({ type, tryOn: 1, inStock: 1, limit: 1 })))).flatMap((r) => r.items)[0];
        return found?.images[0] ? { label: t.label, p: found } : null;
      })).then((list) => setLookPieces(list.filter(Boolean) as { label: string; p: Product }[])),
    ]).catch(() => undefined).finally(() => setLoading(false));
  }, []);

  const heroImg = models[0] ?? fresh.find((p) => p.images[0])?.images[0]?.url;
  const lookImg = models[1] ?? models[0] ?? heroImg;
  const catsWithItems = cats.filter((c) => (c._count?.products ?? 0) > 0);
  const shownCats = catsWithItems.length ? catsWithItems : cats;

  return (
    <>
      <section className="hero" aria-labelledby="hero-title">
        <div className="hero-copy">
          <h1 id="hero-title">Discover your perfect jewellery</h1>
          <p>See any piece on a model or on your own photo before you order.</p>
          <div className="hero-actions">
            <Link to="/shop" className="btn btn-primary btn-lg">Shop now</Link>
            <Link to="/shop?tryOn=1" className="btn btn-secondary btn-lg"><Icon name="sparkle" size={18} />Try on with AI</Link>
          </div>
        </div>
        <div className={`hero-media ${heroImg ? "" : "hero-media-empty"}`}>
          {heroImg ? <img src={heroImg} alt="A model wearing earrings and bangles from the shop" {...{ fetchpriority: "high" }} /> : <Icon name="diamond" size={96} />}
        </div>
      </section>

      {shownCats.length > 0 && (
        <section className="home-section" aria-labelledby="cat-title">
          <div className="section-head">
            <h2 id="cat-title">Shop by category</h2>
            <Link to="/shop">View all</Link>
          </div>
          <div className="rail">
            {shownCats.map((c, i) => (
              <Reveal key={c.id} index={i}>
                <Link to={`/shop/${c.slug}`} className="cat-card">
                  <span className="cat-card-img">
                    {c.imageUrl ? <img src={c.imageUrl} alt="" loading="lazy" /> : <span className="cat-card-letter" aria-hidden="true">{c.name.charAt(0)}</span>}
                  </span>
                  <span className="cat-card-name">{c.name}</span>
                </Link>
              </Reveal>
            ))}
          </div>
        </section>
      )}

      <section className="home-section" aria-labelledby="new-title">
        <div className="section-head">
          <h2 id="new-title">New arrivals</h2>
          <Link to="/shop?newArrivals=1">See all</Link>
        </div>
        {loading ? (
          <div className="pgrid">{[0, 1, 2, 3].map((i) => <div key={i} className="skeleton skeleton-card" />)}</div>
        ) : fresh.length ? (
          <div className="pgrid">{fresh.map((p, i) => <Reveal key={p.id} index={i % 4}><ProductCard p={p} /></Reveal>)}</div>
        ) : (
          <p className="empty-note">New pieces are on their way. Check back soon.</p>
        )}
      </section>

      <section className="home-section" aria-labelledby="look-title">
        <Reveal className="look-bento">
          <div className="look-copy">
            <h2 id="look-title">Create your look</h2>
            <p>Pick earrings, a necklace and bangles, then see the whole set on a model before you order.</p>
            <Link to="/build-look" className="btn btn-primary">Start your look</Link>
          </div>
          {lookImg && <div className="look-photo"><img src={lookImg} alt="A model wearing a full jewellery set" loading="lazy" /></div>}
          {lookPieces.length > 0 && (
            <div className="look-pieces">
              {lookPieces.map(({ label, p }) => (
                <Link key={p.id} to={`/product/${p.slug}`} className="look-piece">
                  <span className="look-piece-img"><img src={p.images[0].url} alt="" loading="lazy" /></span>
                  <span>{label}<br /><span className="muted">{lkr(p.salePrice ?? p.price)}</span></span>
                </Link>
              ))}
            </div>
          )}
        </Reveal>
      </section>

      {sale.length > 0 && (
        <section className="home-section" aria-labelledby="sale-title">
          <div className="section-head">
            <h2 id="sale-title">On offer now</h2>
            <Link to="/shop?onSale=1">See all offers</Link>
          </div>
          <div className="rail rail-products">
            {sale.map((p) => <ProductCard key={p.id} p={p} />)}
          </div>
        </section>
      )}

      <section className="services" aria-label="Delivery and payment">
        <div className="service"><Icon name="truck" size={22} /><span><strong>Islandwide delivery</strong><span>{s.freeDeliveryOver ? `Free over ${lkr(s.freeDeliveryOver)}, otherwise ${lkr(s.deliveryFee)}` : `Delivered to your door for ${lkr(s.deliveryFee)}`}</span></span></div>
        {s.codEnabled && <div className="service"><Icon name="cash" size={22} /><span><strong>Cash on delivery</strong><span>{s.bankEnabled ? "Or pay by bank transfer" : "Pay when it arrives"}</span></span></div>}
        <div className="service"><Icon name="chat" size={22} /><span><strong>Help on WhatsApp</strong><span>Ask about any piece or order</span></span></div>
        {s.pickupEnabled && <div className="service"><Icon name="store" size={22} /><span><strong>Store pickup</strong><span>{s.address ? `Collect from ${s.address}` : "Collect from our shop"}</span></span></div>}
      </section>
    </>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\Info.tsx' @'
import { useEffect } from "react";
import { Link, useLocation } from "react-router-dom";
import { lkr, phoneLink, whatsappLink } from "../api/format";
import { useSettings } from "../context/SettingsContext";
import Icon from "../components/Icon";

// Text marked [LIKE THIS] is a placeholder for the shop to replace with its own details.

export function About() {
  const s = useSettings();
  return (
    <div className="page page-narrow">
      <div className="page-head"><h1>About {s.shopName}</h1><p>{s.tagline}</p></div>
      <div className="prose">
        <p>[Tell your story here: when the shop started, who runs it and what kind of jewellery you love to sell.]</p>
        <h2>See it on before you buy</h2>
        <p>Choosing jewellery online is hard when you can't hold it up to yourself. Every piece that supports it can be tried on with AI, on one of our models or on your own photo, before you order.</p>
        <h2>Order your way</h2>
        <p>Pay by cash on delivery or bank transfer, have it delivered anywhere in Sri Lanka, or collect it from our shop. If you have a question about a piece, message us on WhatsApp.</p>
        <p><Link to="/shop" className="btn btn-primary">Shop now</Link></p>
      </div>
    </div>
  );
}

export function Contact() {
  const s = useSettings();
  const cards = [
    s.whatsapp && { href: whatsappLink(s.whatsapp, "Hi, I have a question."), icon: "chat" as const, title: "WhatsApp", text: s.whatsapp, external: true },
    s.phone && { href: phoneLink(s.phone), icon: "phone" as const, title: "Call us", text: s.phone },
    s.email && { href: `mailto:${s.email}`, icon: "mail" as const, title: "Email", text: s.email },
  ].filter(Boolean) as { href: string; icon: "chat" | "phone" | "mail"; title: string; text: string; external?: boolean }[];

  return (
    <div className="page page-narrow">
      <div className="page-head"><h1>Contact us</h1><p>Questions about a piece, an order or a custom request? We're happy to help.</p></div>
      <div className="contact-grid">
        {cards.map((c) => (
          <a key={c.title} href={c.href} className="contact-card" {...(c.external ? { target: "_blank", rel: "noreferrer" } : {})}>
            <span className="contact-card-icon"><Icon name={c.icon} size={24} /></span>
            <strong>{c.title}</strong><span>{c.text}</span>
          </a>
        ))}
        <div className="contact-card">
          <span className="contact-card-icon"><Icon name="pin" size={24} /></span>
          <strong>Visit the shop</strong><span>{s.address || "[Shop address]"}</span>
        </div>
        <div className="contact-card">
          <span className="contact-card-icon"><Icon name="clock" size={24} /></span>
          <strong>Opening hours</strong><span>[Days and hours]</span>
        </div>
      </div>
      {!cards.length && <p className="muted" style={{ marginTop: 20 }}>Contact details appear here once they're added in the admin settings.</p>}
    </div>
  );
}

export function Delivery() {
  const s = useSettings();
  const methods = [s.codEnabled && "cash on delivery", s.bankEnabled && "bank transfer", s.onlineEnabled && "online card payment"].filter(Boolean).join(", ");
  return (
    <div className="page page-narrow">
      <div className="page-head"><h1>Delivery and returns</h1></div>
      <div className="prose">
        <h2>Delivery</h2>
        <p>We deliver anywhere in Sri Lanka for {lkr(s.deliveryFee)}{s.freeDeliveryOver ? `, and free on orders over ${lkr(s.freeDeliveryOver)}` : ""}. Most orders arrive within [number of] working days after we confirm them.</p>
        {s.pickupEnabled && <p>Prefer to collect? Choose store pickup at checkout. It's free, and we'll message you when your order is ready{s.address ? ` at ${s.address}` : ""}.</p>}
        <h2>Payment</h2>
        <p>You can pay by {methods || "the methods shown at checkout"}. For bank transfers, use your order number as the reference and send us the slip on WhatsApp.</p>
        <h2>Returns and exchanges</h2>
        <p>[Your return policy: how many days customers have, what condition items must be in, and which items can't be returned, for example earrings for hygiene reasons.]</p>
        <p>To start a return, <Link to="/contact">contact us</Link> with your order number.</p>
      </div>
    </div>
  );
}

const faqs = [
  { id: "order", q: "How do I place an order?", a: <>Add pieces to your cart and go to checkout. You can order as a guest or sign in. We contact you to confirm the order before it's sent.</> },
  { id: "try-on", q: "How does AI try-on work?", a: <>On any piece you can try on, choose one of our models or upload a clear, front-facing photo of yourself. The AI places the piece where it's worn, for example earrings on the earlobes and necklaces around the neck, and shows a preview in a few seconds. Size and colour can vary slightly in real life.</> },
  { id: "photo", q: "What happens to my photo?", a: <>Your photo is only used to create your preview. If you're signed in, the preview is saved to your account so you can see it again.</> },
  { id: "look", q: "Can I try on a full set?", a: <>Yes. Use <Link to="/build-look">Create your look</Link> to pick earrings, a necklace and bangles, then preview them together.</> },
  { id: "track", q: "How do I track my order?", a: <>Go to <Link to="/track">Track your order</Link> and enter your order number and mobile number.</> },
  { id: "pay", q: "How can I pay?", a: <>Cash on delivery or bank transfer. See <Link to="/delivery">Delivery and returns</Link> for details.</> },
];

export function Faq() {
  const { hash } = useLocation();
  useEffect(() => { if (hash) document.getElementById(hash.slice(1))?.scrollIntoView(); }, [hash]);
  return (
    <div className="page page-narrow">
      <div className="page-head"><h1>Questions and answers</h1></div>
      <dl className="faq-list">
        {faqs.map((f) => (
          <div key={f.id} id={f.id} className="faq-item">
            <dt>{f.q}</dt>
            <dd>{f.a}</dd>
          </div>
        ))}
      </dl>
    </div>
  );
}

export function Privacy() {
  const s = useSettings();
  return (
    <div className="page page-narrow">
      <div className="page-head"><h1>Privacy</h1></div>
      <div className="prose">
        <p>This page explains what {s.shopName} collects when you use this website and why.</p>
        <h2>What we collect</h2>
        <p>Your name, mobile number, address and email when you place an order or create an account. Photos you upload for AI try-on. Pieces you save to your wishlist.</p>
        <h2>How we use it</h2>
        <p>To deliver your order, contact you about it, create try-on previews and keep your account working. We don't sell your details.</p>
        <p>[Add how long you keep data, who you share it with (for example your delivery company) and how customers can ask for their data to be deleted.]</p>
        <p>Questions? <Link to="/contact">Contact us</Link>.</p>
      </div>
    </div>
  );
}

export function Terms() {
  const s = useSettings();
  return (
    <div className="page page-narrow">
      <div className="page-head"><h1>Terms</h1></div>
      <div className="prose">
        <p>These terms apply when you order from {s.shopName}.</p>
        <h2>Orders and prices</h2>
        <p>Prices are in Sri Lankan rupees. An order is accepted when we confirm it by phone or WhatsApp.</p>
        <h2>AI previews</h2>
        <p>Try-on previews show how a piece may look. Size and colour can vary slightly from the real piece.</p>
        <p>[Add your returns, warranty and any other conditions here. See <Link to="/delivery">Delivery and returns</Link>.]</p>
      </div>
    </div>
  );
}

export function NotFound() {
  return (
    <div className="not-found">
      <span className="not-found-art"><Icon name="diamond" size={72} /></span>
      <h1>Page not found</h1>
      <p>The page you're looking for doesn't exist or has moved.</p>
      <div className="card-actions"><Link to="/" className="btn btn-primary">Go to home</Link><Link to="/shop" className="btn btn-quiet">Browse jewellery</Link></div>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\Login.tsx' @'
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

Write-ProjectFile 'frontend\src\pages\OrderConfirmation.tsx' @'
import { Link, useLocation, useParams } from "react-router-dom";
import type { Order } from "../api/types";
import { lkr, whatsappLink } from "../api/format";
import { useSettings } from "../context/SettingsContext";
import { useAuth } from "../context/AuthContext";
import Icon from "../components/Icon";
import { OrderLines } from "../components/OrderView";

export default function OrderConfirmation() {
  const { orderNo } = useParams();
  const order = useLocation().state as Order | undefined;
  const s = useSettings();
  const { user } = useAuth();
  const contact = s.whatsapp || s.phone;
  const msg = `Hi, about my order ${orderNo}${order ? ` (${lkr(order.total)})` : ""}.`;

  return (
    <div className="page">
      <div className="confirm">
        <section className="confirm-hero">
          <span className="confirm-icon"><Icon name="check" size={36} /></span>
          <h1>Thank you for your order</h1>
          <p className="order-no">Your order number<strong>{orderNo}</strong></p>
          <p className="muted">We'll contact you{order ? ` on ${order.mobile}` : ""} to confirm it. Keep your order number to track it.</p>
          <div className="card-actions" style={{ marginTop: 8 }}>
            <Link to={`/track?orderNo=${orderNo}${order ? `&mobile=${order.mobile}` : ""}`} className="btn btn-primary">Track order</Link>
            {contact && <a href={whatsappLink(contact, msg)} target="_blank" rel="noreferrer" className="btn btn-secondary"><Icon name="chat" size={18} />WhatsApp us</a>}
          </div>
        </section>

        {order?.paymentMethod === "BANK_TRANSFER" && (
          <section className="card" aria-labelledby="pay-title">
            <h2 id="pay-title">Complete your payment</h2>
            <p style={{ marginBottom: 12 }}>Transfer <strong>{lkr(order.total)}</strong> and use <strong>{orderNo}</strong> as the reference. Then send the slip to us on WhatsApp.</p>
            {s.bankDetails ? <div className="bank-box">{s.bankDetails}</div> : <p className="muted">We'll send you our bank details when we confirm your order.</p>}
          </section>
        )}

        {order && (
          <section className="card" aria-labelledby="sum-title">
            <h2 id="sum-title">Order summary</h2>
            <OrderLines order={order} />
          </section>
        )}

        <div className="card-actions">
          {user?.role === "CUSTOMER" && <Link to="/account" className="btn btn-quiet">View my orders</Link>}
          <Link to="/shop" className="btn btn-quiet">Continue shopping</Link>
        </div>
      </div>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\ProductDetails.tsx' @'
import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { api } from "../api/client";
import type { Product } from "../api/types";
import { typeLabel } from "../api/format";
import { useCart } from "../context/CartContext";
import { useWishlist } from "../context/WishlistContext";
import { useToast } from "../context/ToastContext";
import ProductCard from "../components/ProductCard";
import Icon from "../components/Icon";
import { Breadcrumb, EmptyState, PageLoading, Price, ProductImage, QtyStepper } from "../components/ui";

export default function ProductDetails() {
  const { slug } = useParams();
  const { add } = useCart();
  const { has, toggle } = useWishlist();
  const { show } = useToast();
  const [p, setP] = useState<Product | null>(null);
  const [related, setRelated] = useState<Product[]>([]);
  const [missing, setMissing] = useState(false);
  const [img, setImg] = useState(0);
  const [qty, setQty] = useState(1);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    setP(null); setMissing(false); setImg(0); setQty(1);
    api.product(slug!).then(setP).catch(() => setMissing(true));
    api.related(slug!).then(setRelated).catch(() => setRelated([]));
  }, [slug]);

  if (missing) return (
    <div className="page">
      <EmptyState icon="search" title="This piece isn't available" action={<Link to="/shop" className="btn btn-primary">Browse jewellery</Link>}>
        It may have sold out or been removed.
      </EmptyState>
    </div>
  );
  if (!p) return <PageLoading />;

  const images = p.images;
  const saved = has(p.id);
  const soldOut = p.stock <= 0;
  const low = !soldOut && p.stock <= 3;

  const addToCart = async () => {
    setBusy(true);
    await add([{ productId: p.id, qty }], `${p.name} added to cart`);
    setBusy(false);
  };

  const share = async () => {
    const url = window.location.href;
    try {
      if (navigator.share) await navigator.share({ title: p.name, url });
      else { await navigator.clipboard.writeText(url); show("Link copied"); }
    } catch { /* closed the share sheet */ }
  };

  return (
    <div className="page">
      <Breadcrumb items={[{ to: "/", label: "Home" }, { to: "/shop", label: "Shop" }, ...(p.category ? [{ to: `/shop/${p.category.slug}`, label: p.category.name }] : []), { label: p.name }]} />

      <div className="pdp">
        <div className="gallery">
          <div className="gallery-main">
            <ProductImage url={images[img]?.url} alt={`${p.name}${images.length > 1 ? `, photo ${img + 1} of ${images.length}` : ""}`} type={p.jewelleryType} iconSize={160} />
            {images.length > 1 && (
              <>
                <button className="icon-btn gallery-nav gallery-prev" aria-label="Previous photo" onClick={() => setImg((img - 1 + images.length) % images.length)}><Icon name="chevronLeft" /></button>
                <button className="icon-btn gallery-nav gallery-next" aria-label="Next photo" onClick={() => setImg((img + 1) % images.length)}><Icon name="chevronRight" /></button>
              </>
            )}
          </div>
          {images.length > 1 && (
            <div className="thumbs">
              {images.map((im, i) => (
                <button key={im.id} className="thumb" aria-current={i === img} aria-label={`Show photo ${i + 1}`} onClick={() => setImg(i)}>
                  <ProductImage url={im.url} alt="" type={p.jewelleryType} iconSize={32} />
                </button>
              ))}
            </div>
          )}
        </div>

        <div className="pdp-info">
          <div className="pdp-meta">
            <span>Code {p.code}</span>
            {soldOut ? <span className="stock stock-out"><Icon name="close" size={16} />Sold out</span>
              : low ? <span className="stock stock-low"><Icon name="alert" size={16} />Only {p.stock} left</span>
              : <span className="stock stock-in"><Icon name="check" size={16} />In stock</span>}
          </div>
          <h1>{p.name}</h1>
          <Price price={p.price} pricing={p} size="lg" />
          {p.offerTitle && <p className="pdp-offer">{p.offerTitle}: {p.offerPercent}% off</p>}
          {p.description && <p className="pdp-desc">{p.description}</p>}

          <div className="pdp-buy">
            <div className="pdp-buy-row">
              {!soldOut && <QtyStepper value={qty} max={Math.min(p.stock, 20)} onChange={setQty} />}
              <button className="btn btn-primary btn-lg" disabled={soldOut || busy} onClick={addToCart}>
                {soldOut ? "Sold out" : busy ? "Adding…" : "Add to cart"}
              </button>
            </div>
            {p.tryOnEnabled && (
              <Link to={`/try-on?products=${p.id}`} className="try-cta">
                <span className="try-cta-icon"><Icon name="sparkle" size={22} /></span>
                <span><strong>Try it on with AI</strong><span>See it on a model or on your own photo</span></span>
                <Icon name="chevronRight" />
              </Link>
            )}
          </div>

          <div className="pdp-actions">
            <button className="btn btn-quiet btn-sm" aria-pressed={saved} onClick={() => toggle(p.id, p.name)}>
              <Icon name="heart" size={18} filled={saved} />{saved ? "Saved" : "Save to wishlist"}
            </button>
            <button className="btn btn-quiet btn-sm" onClick={share}><Icon name="share" size={18} />Share</button>
          </div>

          <dl className="pdp-details">
            <dt>Type</dt><dd>{typeLabel[p.jewelleryType]}</dd>
            {p.category && <><dt>Category</dt><dd><Link to={`/shop/${p.category.slug}`}>{p.category.name}</Link></dd></>}
            {p.style && <><dt>Style</dt><dd>{p.style}</dd></>}
            {p.colour && <><dt>Colour</dt><dd>{p.colour}</dd></>}
          </dl>
        </div>
      </div>

      {related.length > 0 && (
        <section className="related" aria-labelledby="related-title">
          <div className="section-head"><h2 id="related-title">You may also like</h2>{p.category && <Link to={`/shop/${p.category.slug}`}>More {p.category.name.toLowerCase()}</Link>}</div>
          <div className="pgrid">{related.map((r) => <ProductCard key={r.id} p={r} />)}</div>
        </section>
      )}
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\Register.tsx' @'
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

Write-ProjectFile 'frontend\src\pages\Shop.tsx' @'
import { FormEvent, useEffect, useMemo, useState } from "react";
import { Link, useParams, useSearchParams } from "react-router-dom";
import { api } from "../api/client";
import type { Category, Paged, Product, ProductFilters } from "../api/types";
import ProductCard from "../components/ProductCard";
import Icon from "../components/Icon";
import { Breadcrumb, EmptyState, ErrorState, Pagination } from "../components/ui";

const sorts = [
  { v: "new", label: "Newest" },
  { v: "price_asc", label: "Price: low to high" },
  { v: "price_desc", label: "Price: high to low" },
  { v: "name", label: "Name A to Z" },
];

export default function Shop() {
  const { category } = useParams();
  const [sp, setSp] = useSearchParams();
  const [data, setData] = useState<Paged<Product> | null>(null);
  const [cats, setCats] = useState<Category[]>([]);
  const [facets, setFacets] = useState<ProductFilters | null>(null);
  const [err, setErr] = useState("");
  const [open, setOpen] = useState(false);
  const [reload, setReload] = useState(0);

  useEffect(() => {
    api.categories().then(setCats).catch(() => undefined);
    api.productFilters().then(setFacets).catch(() => undefined);
  }, []);

  useEffect(() => {
    setErr("");
    setData(null);
    api.products({ category, ...Object.fromEntries(sp), limit: 24 }).then(setData).catch((e) => setErr((e as Error).message));
  }, [category, sp, reload]);

  useEffect(() => { setOpen(false); }, [category, sp]);

  const set = (k: string, v: string | null) => {
    const n = new URLSearchParams(sp);
    v ? n.set(k, v) : n.delete(k);
    if (k !== "page") n.delete("page");
    setSp(n);
  };
  const toggle = (k: string) => set(k, sp.get(k) ? null : "1");

  const current = cats.find((c) => c.slug === category);
  const q = sp.get("q");
  const title = q ? `Results for “${q}”` : current?.name ?? (sp.get("newArrivals") ? "New arrivals" : sp.get("onSale") ? "Offers" : sp.get("tryOn") ? "Try on with AI" : "All jewellery");

  const activeChips = useMemo(() => {
    const chips: { label: string; clear: () => void }[] = [];
    if (q) chips.push({ label: `“${q}”`, clear: () => set("q", null) });
    if (sp.get("minPrice") || sp.get("maxPrice")) chips.push({ label: `LKR ${sp.get("minPrice") || "0"} to ${sp.get("maxPrice") || "any"}`, clear: () => { const n = new URLSearchParams(sp); n.delete("minPrice"); n.delete("maxPrice"); n.delete("page"); setSp(n); } });
    if (sp.get("style")) chips.push({ label: sp.get("style")!, clear: () => set("style", null) });
    if (sp.get("colour")) chips.push({ label: sp.get("colour")!, clear: () => set("colour", null) });
    if (sp.get("inStock")) chips.push({ label: "In stock", clear: () => set("inStock", null) });
    if (sp.get("onSale")) chips.push({ label: "On offer", clear: () => set("onSale", null) });
    if (sp.get("newArrivals")) chips.push({ label: "New arrivals", clear: () => set("newArrivals", null) });
    if (sp.get("tryOn")) chips.push({ label: "AI try-on", clear: () => set("tryOn", null) });
    return chips;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [sp]);

  const applyPrice = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    const n = new URLSearchParams(sp);
    const min = String(f.get("minPrice") || ""), max = String(f.get("maxPrice") || "");
    min ? n.set("minPrice", min) : n.delete("minPrice");
    max ? n.set("maxPrice", max) : n.delete("maxPrice");
    n.delete("page");
    setSp(n);
  };

  const keep = sp.toString() ? `?${new URLSearchParams([...sp].filter(([k]) => k !== "page")).toString()}` : "";

  return (
    <div className="page">
      <Breadcrumb items={[{ to: "/", label: "Home" }, { to: "/shop", label: "Shop" }, ...(current ? [{ label: current.name }] : [])]} />
      <div className="shop-head">
        <h1>{title}</h1>
      </div>

      <div className="shop">
        {open && <button className="drawer-scrim" aria-label="Close filters" onClick={() => setOpen(false)} />}
        <aside className={`filters ${open ? "is-open" : ""}`} aria-label="Filters">
          <div className="filters-head">
            <h2>Filters</h2>
            <button className="icon-btn" aria-label="Close filters" onClick={() => setOpen(false)}><Icon name="close" /></button>
          </div>

          <div className="filter-group">
            <h2>Category</h2>
            <div className="filter-list">
              <Link to={`/shop${keep}`} className={`filter-link ${!category ? "is-on" : ""}`}>All jewellery</Link>
              {cats.map((c) => (
                <Link key={c.id} to={`/shop/${c.slug}${keep}`} className={`filter-link ${category === c.slug ? "is-on" : ""}`} aria-current={category === c.slug ? "page" : undefined}>
                  {c.name}<span className="muted">{c._count?.products ?? ""}</span>
                </Link>
              ))}
            </div>
          </div>

          <form className="filter-group" onSubmit={applyPrice} key={`${sp.get("minPrice")}-${sp.get("maxPrice")}`}>
            <h2>Price (LKR)</h2>
            <div className="price-inputs">
              <label className="sr-only" htmlFor="minPrice">Minimum price</label>
              <input id="minPrice" name="minPrice" type="number" min={0} inputMode="numeric" placeholder={facets ? String(facets.minPrice) : "Min"} defaultValue={sp.get("minPrice") ?? ""} />
              <span aria-hidden="true">to</span>
              <label className="sr-only" htmlFor="maxPrice">Maximum price</label>
              <input id="maxPrice" name="maxPrice" type="number" min={0} inputMode="numeric" placeholder={facets ? String(facets.maxPrice) : "Max"} defaultValue={sp.get("maxPrice") ?? ""} />
            </div>
            <button className="btn btn-quiet btn-sm">Apply price</button>
          </form>

          {!!facets?.styles.length && (
            <div className="filter-group">
              <h2>Style</h2>
              <div className="chips">
                {facets.styles.map((st) => <button key={st} type="button" className="chip" aria-pressed={sp.get("style") === st} onClick={() => set("style", sp.get("style") === st ? null : st)}>{st}</button>)}
              </div>
            </div>
          )}
          {!!facets?.colours.length && (
            <div className="filter-group">
              <h2>Colour</h2>
              <div className="chips">
                {facets.colours.map((c) => <button key={c} type="button" className="chip" aria-pressed={sp.get("colour") === c} onClick={() => set("colour", sp.get("colour") === c ? null : c)}>{c}</button>)}
              </div>
            </div>
          )}

          <div className="filter-group">
            <h2>Show</h2>
            <label className="check"><input type="checkbox" checked={!!sp.get("inStock")} onChange={() => toggle("inStock")} />In stock only</label>
            <label className="check"><input type="checkbox" checked={!!sp.get("onSale")} onChange={() => toggle("onSale")} />On offer</label>
            <label className="check"><input type="checkbox" checked={!!sp.get("newArrivals")} onChange={() => toggle("newArrivals")} />New arrivals</label>
            <label className="check"><input type="checkbox" checked={!!sp.get("tryOn")} onChange={() => toggle("tryOn")} />Can try on with AI</label>
          </div>
        </aside>

        <div>
          <div className="shop-toolbar">
            <span className="shop-count" aria-live="polite">{data ? `${data.total} ${data.total === 1 ? "piece" : "pieces"}` : "Loading…"}</span>
            <div className="shop-toolbar-right">
              <button className="btn btn-quiet btn-sm filters-toggle" onClick={() => setOpen(true)} aria-expanded={open}><Icon name="filter" size={18} />Filters{activeChips.length ? ` (${activeChips.length})` : ""}</button>
              <label className="sort">
                <span className="sr-only">Sort by</span>
                <select value={sp.get("sort") ?? "new"} onChange={(e) => set("sort", e.target.value === "new" ? null : e.target.value)}>
                  {sorts.map((s) => <option key={s.v} value={s.v}>{s.label}</option>)}
                </select>
              </label>
            </div>
          </div>

          {activeChips.length > 0 && (
            <div className="active-filters">
              {activeChips.map((c) => <button key={c.label} className="chip" onClick={c.clear} aria-label={`Remove filter ${c.label}`}>{c.label}<Icon name="close" size={14} /></button>)}
              <Link to={category ? `/shop/${category}` : "/shop"} className="btn-link" style={{ minHeight: 36, fontSize: 14 }}>Clear all</Link>
            </div>
          )}

          {err ? <ErrorState message={err} onRetry={() => setReload((n) => n + 1)} />
            : !data ? <div className="pgrid">{Array.from({ length: 8 }, (_, i) => <div key={i} className="skeleton skeleton-card" />)}</div>
            : !data.items.length ? (
              <EmptyState title="No pieces match" action={<Link to="/shop" className="btn btn-primary">See all jewellery</Link>}>
                {activeChips.length ? "Remove a filter or search for something else." : "There's nothing in this category yet."}
              </EmptyState>
            ) : (
              <>
                <div className="pgrid">{data.items.map((p) => <ProductCard key={p.id} p={p} />)}</div>
                <Pagination page={data.page} pages={data.pages} onPage={(p) => set("page", p === 1 ? null : String(p))} />
              </>
            )}
        </div>
      </div>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\TrackOrder.tsx' @'
import { FormEvent, useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { api } from "../api/client";
import type { Order } from "../api/types";
import { customerStatus, shortDate, whatsappLink } from "../api/format";
import { useSettings } from "../context/SettingsContext";
import Icon from "../components/Icon";
import { OrderLines, OrderTimeline } from "../components/OrderView";

export default function TrackOrder() {
  const [sp, setSp] = useSearchParams();
  const s = useSettings();
  const [order, setOrder] = useState<Order | null>(null);
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  const lookup = async (orderNo: string, mobile: string) => {
    setBusy(true); setErr("");
    try { setOrder(await api.trackOrder(orderNo, mobile)); }
    catch (e) { setErr((e as Error).message); setOrder(null); }
    finally { setBusy(false); }
  };

  useEffect(() => {
    const o = sp.get("orderNo"), m = sp.get("mobile");
    if (o && m) lookup(o, m);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const submit = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    const orderNo = String(f.get("orderNo")).trim(), mobile = String(f.get("mobile")).trim();
    setSp({ orderNo, mobile }, { replace: true });
    lookup(orderNo, mobile);
  };

  const contact = s.whatsapp || s.phone;

  return (
    <div className="page">
      <div className="page-head"><h1>Track your order</h1><p>Enter your order number and the mobile number you used at checkout.</p></div>
      <div className="track-grid">
        <form className="card form" onSubmit={submit}>
          <label className="field"><span className="field-label">Order number</span><input name="orderNo" required placeholder="ORD-000125" defaultValue={sp.get("orderNo") ?? ""} autoCapitalize="characters" /></label>
          <label className="field"><span className="field-label">Mobile number</span><input name="mobile" type="tel" required placeholder="07XXXXXXXX" inputMode="tel" defaultValue={sp.get("mobile") ?? ""} /></label>
          {err && <p className="form-error" role="alert">{err}</p>}
          <button className="btn btn-primary btn-block" disabled={busy}>{busy ? "Checking…" : "Track order"}</button>
        </form>

        {order ? (
          <div className="stack">
            <section className="card" aria-labelledby="status-title">
              <div className="order-card-head" style={{ marginBottom: 20 }}>
                <div><h2 id="status-title" style={{ marginBottom: 4 }}>{customerStatus[order.status]}</h2><span className="muted">{order.orderNo} · placed {shortDate(order.createdAt)}</span></div>
                {contact && <a href={whatsappLink(contact, `Hi, about my order ${order.orderNo}.`)} target="_blank" rel="noreferrer" className="btn btn-quiet btn-sm"><Icon name="chat" size={16} />Ask on WhatsApp</a>}
              </div>
              <OrderTimeline order={order} />
            </section>
            <section className="card" aria-labelledby="items-title">
              <h2 id="items-title">Items</h2>
              <OrderLines order={order} />
            </section>
          </div>
        ) : (
          <div className="card" style={{ display: "flex", gap: 16, alignItems: "center" }}>
            <span className="empty-icon" style={{ flexShrink: 0 }}><Icon name="truck" size={26} /></span>
            <p className="muted">Your order number is on the confirmation page and in the message we sent you. It looks like ORD-000125.</p>
          </div>
        )}
      </div>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\TryOn.tsx' @'
import { DragEvent, useEffect, useRef, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { api } from "../api/client";
import type { AiModel, Product, TryOnJob } from "../api/types";
import { lkr } from "../api/format";
import { useCart } from "../context/CartContext";
import { useToast } from "../context/ToastContext";
import Icon from "../components/Icon";
import { EmptyState, PageLoading, Price, ProductImage } from "../components/ui";

type Mode = "AI_MODEL" | "UPLOAD";
const MAX_MB = 8;

export default function TryOn() {
  const [sp] = useSearchParams();
  const ids = (sp.get("products") ?? "").split(",").filter(Boolean);
  const { add } = useCart();
  const { show } = useToast();

  const [items, setItems] = useState<Product[] | null>(null);
  const [mode, setMode] = useState<Mode | null>(null);
  const [models, setModels] = useState<AiModel[] | null>(null);
  const [modelId, setModelId] = useState<string>();
  const [photo, setPhoto] = useState<File>();
  const [preview, setPreview] = useState<string>();
  const [over, setOver] = useState(false);
  const [job, setJob] = useState<TryOnJob | null>(null);
  const [err, setErr] = useState("");
  const timer = useRef<number>();
  const started = useRef(0);

  useEffect(() => {
    if (!ids.length) { setItems([]); return; }
    api.products({ ids: ids.join(","), limit: 20 }).then((r) => setItems(r.items.filter((p) => p.tryOnEnabled))).catch(() => setItems([]));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [sp.get("products")]);

  useEffect(() => { if (mode === "AI_MODEL" && !models) api.aiModels().then(setModels).catch(() => setModels([])); }, [mode, models]);
  useEffect(() => () => { window.clearInterval(timer.current); }, []);
  useEffect(() => {
    if (!photo) { setPreview(undefined); return; }
    const url = URL.createObjectURL(photo);
    setPreview(url);
    return () => URL.revokeObjectURL(url);
  }, [photo]);

  if (!items) return <PageLoading />;
  if (!items.length) return (
    <div className="page">
      <EmptyState icon="sparkle" title="Choose a piece to try on" action={<Link to="/shop?tryOn=1" className="btn btn-primary">Browse pieces you can try on</Link>}>
        Open any product and select “Try it on with AI”, or build a full set in Create your look.
      </EmptyState>
    </div>
  );

  const pickFile = (f?: File) => {
    setErr("");
    if (!f) return;
    if (!/image\/(jpeg|png|webp)/.test(f.type)) { setErr("Choose a JPG, PNG or WebP photo."); return; }
    if (f.size > MAX_MB * 1024 * 1024) { setErr(`That photo is over ${MAX_MB} MB. Choose a smaller one.`); return; }
    setPhoto(f);
  };
  const onDrop = (e: DragEvent) => { e.preventDefault(); setOver(false); pickFile(e.dataTransfer.files[0]); };

  const poll = (id: string) => {
    started.current = Date.now();
    timer.current = window.setInterval(async () => {
      try {
        const s = await api.tryOnStatus(id);
        setJob(s);
        if (s.status === "DONE" || s.status === "FAILED") window.clearInterval(timer.current);
      } catch { /* keep polling */ }
      if (Date.now() - started.current > 120_000) {
        window.clearInterval(timer.current);
        setJob({ id, status: "FAILED", error: "This is taking longer than expected. Try again in a moment." });
      }
    }, 2000);
  };

  const generate = async () => {
    setErr("");
    const fd = new FormData();
    fd.append("productIds", JSON.stringify(items.map((p) => p.id)));
    fd.append("source", mode!);
    if (mode === "AI_MODEL" && modelId) fd.append("aiModelId", modelId);
    if (mode === "UPLOAD" && photo) fd.append("photo", photo);
    try {
      const j = await api.startTryOn(fd);
      setJob(j);
      poll(j.id);
    } catch (e) { setErr((e as Error).message); }
  };

  const reset = () => { window.clearInterval(timer.current); setJob(null); };
  const step = job ? 3 : mode ? 2 : 1;
  const total = items.reduce((s, p) => s + (p.salePrice ?? p.price), 0);
  const ready = (mode === "AI_MODEL" && !!modelId) || (mode === "UPLOAD" && !!photo);

  const save = async () => {
    if (!job?.resultUrl) return;
    try {
      const blob = await (await fetch(job.resultUrl)).blob();
      const a = document.createElement("a");
      a.href = URL.createObjectURL(blob);
      a.download = "my-try-on.jpg";
      a.click();
      URL.revokeObjectURL(a.href);
    } catch { window.open(job.resultUrl, "_blank"); }
  };
  const share = async () => {
    if (!job?.resultUrl) return;
    try {
      if (navigator.share) await navigator.share({ title: "My try-on", url: job.resultUrl });
      else { await navigator.clipboard.writeText(job.resultUrl); show("Link copied"); }
    } catch { /* closed */ }
  };

  return (
    <div className="page">
      <div className="page-head"><h1>Virtual try-on</h1></div>
      <ol className="stepper" aria-label="Steps">
        {["Choose how", mode === "UPLOAD" ? "Add your photo" : "Pick a model", "Your preview"].map((label, i) => (
          <li key={label} className={step === i + 1 ? "is-current" : step > i + 1 ? "is-done" : ""} aria-current={step === i + 1 ? "step" : undefined}>
            <span className="step-dot">{step > i + 1 ? <Icon name="check" size={14} /> : i + 1}</span>{label}
          </li>
        ))}
      </ol>

      <div className="tryon">
        <div>
          {job ? (
            job.status === "DONE" && job.resultUrl ? (
              <div className="result">
                <div className="result-img"><img src={job.resultUrl} alt={`Preview wearing ${items.map((p) => p.name).join(", ")}`} /></div>
                <div className="result-info">
                  <h2>Here's how it looks</h2>
                  <p className="muted">Wearing {items.map((p) => p.name).join(", ")}.</p>
                  <button className="btn btn-primary btn-lg" onClick={() => add(items.map((p) => ({ productId: p.id, qty: 1 })), items.length > 1 ? "Your look was added to the cart" : `${items[0].name} added to cart`)}>
                    Add {items.length > 1 ? `all ${items.length} to cart` : "to cart"} · {lkr(total)}
                  </button>
                  <div className="tryon-actions" style={{ marginTop: 0 }}>
                    <button className="btn btn-quiet" onClick={save}><Icon name="download" size={18} />Save</button>
                    <button className="btn btn-quiet" onClick={share}><Icon name="share" size={18} />Share</button>
                    <button className="btn btn-quiet" onClick={reset}><Icon name="refresh" size={18} />Try again</button>
                  </div>
                  <p className="result-note">AI previews show how a piece may look. Size and colour can vary slightly in real life.</p>
                </div>
              </div>
            ) : job.status === "FAILED" ? (
              <div className="empty-state">
                <span className="empty-icon empty-icon-error"><Icon name="alert" size={28} /></span>
                <h2>We couldn't make the preview</h2>
                <p>{job.error ?? "Try a different photo or model."}</p>
                <button className="btn btn-primary" onClick={reset}>Try again</button>
              </div>
            ) : (
              <div className="generating" role="status">
                <span className="generating-art"><Icon name="sparkle" size={44} /></span>
                <h2>Creating your preview</h2>
                <p>This usually takes a few seconds. Keep this page open.</p>
              </div>
            )
          ) : !mode ? (
            <>
              <h2 className="sr-only">How would you like to try it on?</h2>
              <div className="method-grid">
                <button className="method" onClick={() => setMode("AI_MODEL")}>
                  <span className="method-icon"><Icon name="model" size={28} /></span>
                  <strong>Use an AI model</strong>
                  <span>Pick a model and see the piece on them. Quick, and no photo needed.</span>
                </button>
                <button className="method" onClick={() => setMode("UPLOAD")}>
                  <span className="method-icon"><Icon name="camera" size={28} /></span>
                  <strong>Upload your photo</strong>
                  <span>See it on yourself. Your photo is only used to make this preview.</span>
                </button>
              </div>
            </>
          ) : mode === "AI_MODEL" ? (
            <>
              <h2 className="sr-only">Pick a model</h2>
              {!models ? <PageLoading label="Loading models…" /> : !models.length ? (
                <EmptyState icon="model" title="No models yet" action={<button className="btn btn-primary" onClick={() => setMode("UPLOAD")}>Upload your photo instead</button>}>
                  The shop hasn't added AI models yet.
                </EmptyState>
              ) : (
                <div className="model-grid">
                  {models.map((m) => (
                    <button key={m.id} className="model-card" aria-pressed={modelId === m.id} onClick={() => setModelId(m.id)} aria-label={`Model ${m.name}`}>
                      <img src={m.imageUrl} alt="" />
                      <span className="model-card-check"><Icon name="check" size={16} /></span>
                      <span className="model-card-name">{m.name}</span>
                    </button>
                  ))}
                </div>
              )}
            </>
          ) : (
            <>
              <h2 className="sr-only">Add your photo</h2>
              {preview ? (
                <div className="photo-preview">
                  <img src={preview} alt="Your photo" />
                  <div className="stack">
                    <ul className="tips">
                      <li><Icon name="checkCircle" />Face clearly visible</li>
                      <li><Icon name="checkCircle" />Good, even lighting</li>
                      <li><Icon name="checkCircle" />Facing the camera</li>
                    </ul>
                    <label className="btn btn-quiet" style={{ alignSelf: "flex-start" }}>
                      <Icon name="refresh" size={18} />Choose another photo
                      <input type="file" accept="image/jpeg,image/png,image/webp" className="sr-only" onChange={(e) => pickFile(e.target.files?.[0])} />
                    </label>
                  </div>
                </div>
              ) : (
                <label className={`dropzone ${over ? "is-over" : ""}`} onDragOver={(e) => { e.preventDefault(); setOver(true); }} onDragLeave={() => setOver(false)} onDrop={onDrop}>
                  <span className="dropzone-icon"><Icon name="upload" size={26} /></span>
                  <strong>Choose a photo or drop it here</strong>
                  <span>JPG, PNG or WebP, up to {MAX_MB} MB. A clear, front-facing photo works best.</span>
                  <input type="file" accept="image/jpeg,image/png,image/webp" capture="user" className="sr-only" onChange={(e) => pickFile(e.target.files?.[0])} />
                </label>
              )}
            </>
          )}

          {err && <p className="form-error" role="alert" style={{ marginTop: 16 }}>{err}</p>}

          {!job && mode && (
            <div className="tryon-actions">
              <button className="btn btn-quiet" onClick={() => { setMode(null); setErr(""); }}><Icon name="arrowLeft" size={18} />Back</button>
              <button className="btn btn-primary" disabled={!ready} onClick={generate}><Icon name="sparkle" size={18} />Create preview</button>
            </div>
          )}
        </div>

        <aside className="tryon-side" aria-label="Pieces you're trying on">
          <h2>Trying on</h2>
          {items.map((p) => (
            <div key={p.id} className="mini-item">
              <span className="mini-item-img"><ProductImage url={p.images[0]?.url} alt="" type={p.jewelleryType} iconSize={30} /></span>
              <span>
                <Link to={`/product/${p.slug}`} className="mini-item-name">{p.name}</Link><br />
                <Price price={p.price} pricing={p} />
              </span>
            </div>
          ))}
          {items.length > 1 && <div className="tray-total"><span>Total</span><span>{lkr(total)}</span></div>}
        </aside>
      </div>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\admin\AdminLayout.tsx' @'
import { useEffect, useState } from "react";
import { Link, NavLink, Outlet, useLocation, useNavigate } from "react-router-dom";
import { api } from "../../api/client";
import { useAuth } from "../../context/AuthContext";
import { useSettings } from "../../context/SettingsContext";
import Icon, { IconName } from "../../components/Icon";

const links: { to: string; label: string; icon: IconName; end?: boolean }[] = [
  { to: "/admin", label: "Dashboard", icon: "dashboard", end: true },
  { to: "/admin/orders", label: "Orders", icon: "orders" },
  { to: "/admin/products", label: "Products", icon: "products" },
  { to: "/admin/categories", label: "Categories", icon: "categories" },
  { to: "/admin/customers", label: "Customers", icon: "customers" },
  { to: "/admin/ai-models", label: "AI models", icon: "model" },
  { to: "/admin/offers", label: "Offers", icon: "offers" },
  { to: "/admin/reports", label: "Reports", icon: "reports" },
  { to: "/admin/settings", label: "Settings", icon: "settings" },
];

export default function AdminLayout() {
  const { user, logout } = useAuth();
  const s = useSettings();
  const nav = useNavigate();
  const loc = useLocation();
  const [open, setOpen] = useState(false);
  const [pending, setPending] = useState(0);

  useEffect(() => {
    setOpen(false);
    api.admin.orders({ status: "PENDING" }).then((r) => setPending(r.total)).catch(() => undefined);
  }, [loc.pathname]);

  const signOut = () => { logout(); nav("/admin/login", { replace: true }); };

  return (
    <div className="admin-shell">
      <aside className={`admin-side ${open ? "is-open" : ""}`} aria-label="Admin menu">
        <Link to="/admin" className="admin-logo">{s.shopName}</Link>
        <nav className="admin-nav" aria-label="Admin">
          {links.map((l) => (
            <NavLink key={l.to} to={l.to} end={l.end}>
              <Icon name={l.icon} />{l.label}
              {l.to === "/admin/orders" && pending > 0 && <span className="admin-nav-count" aria-label={`${pending} pending`}>{pending}</span>}
            </NavLink>
          ))}
        </nav>
        <div className="admin-side-foot">
          <Link to="/" className="admin-side-link" target="_blank"><Icon name="store" />View shop</Link>
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

Write-ProjectFile 'frontend\src\pages\admin\AdminLogin.tsx' @'
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

Write-ProjectFile 'frontend\src\pages\admin\AiModels.tsx' @'
import { FormEvent, useEffect, useState } from "react";
import { api } from "../../api/client";
import type { AiModel } from "../../api/types";
import { useToast } from "../../context/ToastContext";
import Icon from "../../components/Icon";
import { ConfirmDialog, EmptyState, ErrorState, Modal, PageLoading } from "../../components/ui";

export default function AiModels() {
  const { show } = useToast();
  const [models, setModels] = useState<AiModel[] | null>(null);
  const [err, setErr] = useState("");
  const [adding, setAdding] = useState(false);
  const [preview, setPreview] = useState<string>();
  const [formErr, setFormErr] = useState("");
  const [busy, setBusy] = useState(false);
  const [deleting, setDeleting] = useState<AiModel | null>(null);

  const load = () => { setErr(""); api.admin.aiModels().then(setModels).catch((e) => setErr((e as Error).message)); };
  useEffect(load, []);

  const add = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);
    if (!(fd.get("image") as File)?.size) { setFormErr("Choose a photo of the model."); return; }
    setBusy(true); setFormErr("");
    try { await api.admin.addAiModel(fd); show("Model added"); setAdding(false); setPreview(undefined); load(); }
    catch (e) { setFormErr((e as Error).message); } finally { setBusy(false); }
  };
  const toggle = async (m: AiModel) => {
    try { await api.admin.updateAiModel(m.id, { isActive: !m.isActive }); show(m.isActive ? `${m.name} is hidden from customers` : `${m.name} is available`); load(); }
    catch (e) { show((e as Error).message, { kind: "error" }); }
  };
  const remove = async () => {
    setBusy(true);
    try {
      const r = await api.admin.deleteAiModel(deleting!.id);
      show(r?.hidden ? `${deleting!.name} has past try-ons, so it was hidden instead of deleted` : "Model deleted");
      setDeleting(null); load();
    } catch (e) { show((e as Error).message, { kind: "error" }); } finally { setBusy(false); }
  };

  return (
    <div className="admin-page">
      <div className="admin-head">
        <div><h1>AI models</h1><p>Customers who don't upload their own photo choose one of these models for their try-on.</p></div>
        <button className="btn btn-primary" onClick={() => { setAdding(true); setFormErr(""); }}><Icon name="plus" size={18} />Add model</button>
      </div>

      {err ? <ErrorState message={err} onRetry={load} /> : !models ? <PageLoading /> : !models.length ? (
        <div className="panel">
          <EmptyState icon="model" title="No models yet" action={<button className="btn btn-primary" onClick={() => setAdding(true)}>Add your first model</button>}>
            Add a few front-facing portrait photos with the ears, neck and wrists visible. Use photos you have the rights to.
          </EmptyState>
        </div>
      ) : (
        <div className="gallery-admin">
          {models.map((m) => (
            <article key={m.id} className={`model-admin ${m.isActive ? "" : "is-off"}`}>
              <img src={m.imageUrl} alt={`Model ${m.name}`} />
              <div className="model-admin-body">
                <span><strong>{m.name}</strong><span className="muted" style={{ display: "block", fontSize: 13 }}>{m._count?.tryOns ?? 0} try-ons</span></span>
                <span className={`pill ${m.isActive ? "pill-on" : "pill-off"}`}>{m.isActive ? "Shown" : "Hidden"}</span>
              </div>
              <div className="model-admin-actions">
                <button className="btn btn-quiet btn-sm" style={{ flex: 1 }} onClick={() => toggle(m)}>{m.isActive ? "Hide" : "Show"}</button>
                <button className="icon-btn" aria-label={`Delete ${m.name}`} onClick={() => setDeleting(m)}><Icon name="trash" size={18} /></button>
              </div>
            </article>
          ))}
        </div>
      )}

      <Modal open={adding} title="Add model" onClose={() => { setAdding(false); setPreview(undefined); }}>
        <form className="form" onSubmit={add}>
          <label className="field"><span className="field-label">Name</span><input name="name" required maxLength={40} placeholder="Model 1" autoFocus /><span className="field-hint">Customers see this name</span></label>
          <div className="field">
            <span className="field-label">Photo</span>
            {preview && <img src={preview} alt="Preview" style={{ width: 140, aspectRatio: "3 / 4", objectFit: "cover", borderRadius: 12 }} />}
            <label className="btn btn-quiet btn-sm" style={{ alignSelf: "flex-start" }}><Icon name="upload" size={16} />{preview ? "Choose another" : "Choose photo"}
              <input name="image" type="file" accept="image/jpeg,image/png,image/webp" className="sr-only" onChange={(e) => { const f = e.target.files?.[0]; setPreview(f ? URL.createObjectURL(f) : undefined); }} />
            </label>
            <span className="field-hint">Front-facing, good light, ears, neck and wrists visible.</span>
          </div>
          {formErr && <p className="form-error" role="alert">{formErr}</p>}
          <div className="modal-foot" style={{ margin: "4px -24px -24px" }}>
            <button type="button" className="btn btn-secondary" onClick={() => setAdding(false)}>Cancel</button>
            <button className="btn btn-primary" disabled={busy}>{busy ? "Uploading…" : "Add model"}</button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog open={!!deleting} danger title="Delete this model?" confirmLabel="Delete model" busy={busy} onConfirm={remove} onClose={() => setDeleting(null)}
        body={deleting?._count?.tryOns ? <>{deleting.name} was used in {deleting._count.tryOns} try-ons, so it will be hidden instead of deleted.</> : <>{deleting?.name} will be removed.</>} />
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\admin\Categories.tsx' @'
import { FormEvent, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../../api/client";
import type { Category } from "../../api/types";
import { useToast } from "../../context/ToastContext";
import Icon from "../../components/Icon";
import { ConfirmDialog, ErrorState, Modal, PageLoading } from "../../components/ui";

export default function Categories() {
  const { show } = useToast();
  const [cats, setCats] = useState<Category[] | null>(null);
  const [err, setErr] = useState("");
  const [editing, setEditing] = useState<Category | "new" | null>(null);
  const [deleting, setDeleting] = useState<Category | null>(null);
  const [formErr, setFormErr] = useState("");
  const [busy, setBusy] = useState(false);
  const [preview, setPreview] = useState<string>();

  const load = () => { setErr(""); api.categories().then(setCats).catch((e) => setErr((e as Error).message)); };
  useEffect(load, []);

  const open = (c: Category | "new") => { setFormErr(""); setPreview(undefined); setEditing(c); };

  const save = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);
    if (!(fd.get("image") as File)?.size) fd.delete("image");
    setBusy(true); setFormErr("");
    try {
      await api.admin.saveCategory(fd, editing === "new" ? undefined : editing!.id);
      show(editing === "new" ? "Category added" : "Category saved");
      setEditing(null); load();
    } catch (e) { setFormErr((e as Error).message); } finally { setBusy(false); }
  };

  const remove = async () => {
    setBusy(true);
    try { await api.admin.deleteCategory(deleting!.id); show("Category deleted"); setDeleting(null); load(); }
    catch (e) { show((e as Error).message, { kind: "error" }); setDeleting(null); }
    finally { setBusy(false); }
  };

  const current = editing && editing !== "new" ? editing : null;

  return (
    <div className="admin-page">
      <div className="admin-head">
        <div><h1>Categories</h1><p>Shown on the home page and as filters in the shop, in this order.</p></div>
        <button className="btn btn-primary" onClick={() => open("new")}><Icon name="plus" size={18} />Add category</button>
      </div>

      {err ? <ErrorState message={err} onRetry={load} /> : !cats ? <PageLoading /> : (
        <div className="panel panel-flush">
          <div className="table-scroll">
            <table className="table">
              <thead><tr><th>Category</th><th className="num">Order</th><th className="num">Products</th><th><span className="sr-only">Actions</span></th></tr></thead>
              <tbody>
                {cats.map((c) => (
                  <tr key={c.id}>
                    <td><div className="cell-product"><span className="cat-row-img">{c.imageUrl ? <img src={c.imageUrl} alt="" /> : <span aria-hidden="true">{c.name.charAt(0)}</span>}</span><strong>{c.name}</strong></div></td>
                    <td className="num">{c.sort}</td>
                    <td className="num"><Link to={`/admin/products?category=${c.id}`}>{c._count?.products ?? 0}</Link></td>
                    <td>
                      <div className="row-actions">
                        <button className="icon-btn" aria-label={`Edit ${c.name}`} onClick={() => open(c)}><Icon name="edit" size={18} /></button>
                        <button className="icon-btn" aria-label={`Delete ${c.name}`} onClick={() => setDeleting(c)}><Icon name="trash" size={18} /></button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      <Modal open={!!editing} title={editing === "new" ? "Add category" : "Edit category"} onClose={() => setEditing(null)}>
        {editing && (
          <form className="form" onSubmit={save} id="cat-form">
            <label className="field"><span className="field-label">Name</span><input name="name" required maxLength={60} defaultValue={current?.name} autoFocus /></label>
            <label className="field"><span className="field-label">Order</span><input name="sort" type="number" step={1} defaultValue={current?.sort ?? (cats?.length ?? 0)} /><span className="field-hint">Lower numbers show first</span></label>
            <div className="field">
              <span className="field-label">Image <span className="optional">(optional)</span></span>
              <div className="asset-row">
                <span className="cat-row-img" style={{ width: 72, height: 72 }}>{preview || current?.imageUrl ? <img src={preview ?? current!.imageUrl!} alt="" /> : <Icon name="image" size={28} />}</span>
                <label className="btn btn-quiet btn-sm"><Icon name="upload" size={16} />Choose image
                  <input name="image" type="file" accept="image/jpeg,image/png,image/webp" className="sr-only" onChange={(e) => { const f = e.target.files?.[0]; setPreview(f ? URL.createObjectURL(f) : undefined); }} />
                </label>
              </div>
              <span className="field-hint">Without an image, the first letter of the name is shown.</span>
            </div>
            {formErr && <p className="form-error" role="alert">{formErr}</p>}
            <div className="modal-foot" style={{ margin: "4px -24px -24px" }}>
              <button type="button" className="btn btn-secondary" onClick={() => setEditing(null)}>Cancel</button>
              <button className="btn btn-primary" disabled={busy}>{busy ? "Saving…" : "Save category"}</button>
            </div>
          </form>
        )}
      </Modal>

      <ConfirmDialog open={!!deleting} danger title="Delete this category?" confirmLabel="Delete category" busy={busy} onConfirm={remove} onClose={() => setDeleting(null)}
        body={deleting?._count?.products ? <>{deleting.name} still has {deleting._count.products} products. Move them to another category first.</> : <>{deleting?.name} will be removed from the shop.</>} />
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\admin\Customers.tsx' @'
import { FormEvent, useEffect, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { api } from "../../api/client";
import type { Customer, CustomerDetail, Paged } from "../../api/types";
import { lkr, phoneLink, shortDate, whatsappLink } from "../../api/format";
import Icon from "../../components/Icon";
import { EmptyState, ErrorState, Modal, PageLoading, Pagination, StatusPill } from "../../components/ui";

export default function Customers() {
  const [sp, setSp] = useSearchParams();
  const [data, setData] = useState<Paged<Customer> | null>(null);
  const [err, setErr] = useState("");
  const [detail, setDetail] = useState<CustomerDetail | null>(null);

  const load = () => { setErr(""); api.admin.customers({ q: sp.get("q"), page: sp.get("page") ?? 1 }).then(setData).catch((e) => setErr((e as Error).message)); };
  useEffect(load, [sp]); // eslint-disable-line react-hooks/exhaustive-deps

  const search = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const q = String(new FormData(e.currentTarget).get("q") || "");
    setSp(q ? { q } : {});
  };
  const openCustomer = (id: string) => api.admin.customer(id).then(setDetail).catch(() => undefined);

  return (
    <div className="admin-page">
      <div className="admin-head"><div><h1>Customers</h1><p>People who created an account. Guest orders appear under Orders.</p></div></div>
      <div className="toolbar">
        <form className="search" role="search" onSubmit={search}>
          <Icon name="search" size={18} />
          <label htmlFor="c-search" className="sr-only">Search customers</label>
          <input id="c-search" name="q" type="search" placeholder="Name, email or mobile" defaultValue={sp.get("q") ?? ""} />
        </form>
      </div>

      {err ? <ErrorState message={err} onRetry={load} /> : !data ? <PageLoading /> : !data.items.length ? (
        <div className="panel"><EmptyState icon="customers" title={sp.get("q") ? "No customers match" : "No customers yet"}>{sp.get("q") ? "Try another name, email or number." : "Customers appear here when they create an account."}</EmptyState></div>
      ) : (
        <>
          <div className="panel panel-flush">
            <div className="table-scroll">
              <table className="table">
                <thead><tr><th>Customer</th><th>Mobile</th><th className="num">Orders</th><th className="num">Spent</th><th>Joined</th></tr></thead>
                <tbody>
                  {data.items.map((c) => (
                    <tr key={c.id}>
                      <td><button className="btn-link" style={{ minHeight: 0, textAlign: "left" }} onClick={() => openCustomer(c.id)}>{c.name}</button><span className="muted" style={{ display: "block", fontSize: 13 }}>{c.email}</span></td>
                      <td>{c.phone || <span className="muted">Not given</span>}</td>
                      <td className="num">{c._count.orders}</td>
                      <td className="num">{lkr(c.totalSpent)}</td>
                      <td className="muted">{shortDate(c.createdAt)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
          <Pagination page={data.page} pages={data.pages} onPage={(p) => { const n = new URLSearchParams(sp); n.set("page", String(p)); setSp(n); }} />
        </>
      )}

      <Modal open={!!detail} title={detail?.name ?? ""} onClose={() => setDetail(null)} wide>
        {detail && (
          <div className="stack">
            <dl className="kv">
              <dt>Email</dt><dd><a href={`mailto:${detail.email}`}>{detail.email}</a></dd>
              <dt>Mobile</dt><dd>{detail.phone || "Not given"}</dd>
              <dt>Joined</dt><dd>{shortDate(detail.createdAt)}</dd>
            </dl>
            {detail.phone && (
              <div className="contact-actions" style={{ marginTop: 0 }}>
                <a href={phoneLink(detail.phone)} className="btn btn-quiet btn-sm"><Icon name="phone" size={16} />Call</a>
                <a href={whatsappLink(detail.phone)} target="_blank" rel="noreferrer" className="btn btn-quiet btn-sm"><Icon name="chat" size={16} />WhatsApp</a>
              </div>
            )}
            <h3 style={{ fontSize: 16 }}>Orders ({detail.orders.length})</h3>
            {detail.orders.length ? (
              <div className="table-scroll">
                <table className="table">
                  <thead><tr><th>Order</th><th className="num">Total</th><th>Status</th><th>Placed</th></tr></thead>
                  <tbody>{detail.orders.map((o) => <tr key={o.id}><td><Link to={`/admin/orders/${o.id}`}>{o.orderNo}</Link></td><td className="num">{lkr(o.total)}</td><td><StatusPill status={o.status} /></td><td className="muted">{shortDate(o.createdAt)}</td></tr>)}</tbody>
                </table>
              </div>
            ) : <p className="muted">No orders yet.</p>}
          </div>
        )}
      </Modal>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\admin\Dashboard.tsx' @'
import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../../api/client";
import type { DashboardData } from "../../api/types";
import { dateTime, lkr } from "../../api/format";
import Icon from "../../components/Icon";
import BarChart from "../../components/BarChart";
import { ErrorState, PageLoading, StatusPill } from "../../components/ui";

export default function Dashboard() {
  const [d, setD] = useState<DashboardData | null>(null);
  const [err, setErr] = useState("");

  const load = () => { setErr(""); api.admin.dashboard().then(setD).catch((e) => setErr((e as Error).message)); };
  useEffect(load, []);

  if (err) return <ErrorState message={err} onRetry={load} />;
  if (!d) return <PageLoading label="Loading dashboard…" />;

  const today = new Date().toLocaleDateString("en-GB", { weekday: "long", day: "numeric", month: "long" });
  const weekTotal = d.last7Days.reduce((s, x) => s + x.sales, 0);
  const bars = d.last7Days.map((x, i) => {
    const date = new Date(`${x.date}T00:00:00`);
    return {
      key: x.date,
      label: i === d.last7Days.length - 1 ? "Today" : date.toLocaleDateString("en-GB", { weekday: "short" }),
      fullLabel: date.toLocaleDateString("en-GB", { weekday: "long", day: "numeric", month: "short" }),
      value: x.sales, orders: x.orders, highlight: i === d.last7Days.length - 1,
    };
  });

  return (
    <div className="admin-page">
      <div className="admin-head">
        <div><h1>Dashboard</h1><p>{today}</p></div>
        <div className="admin-head-actions">
          <Link to="/admin/orders" className="btn btn-quiet">View orders</Link>
          <Link to="/admin/products/new" className="btn btn-primary"><Icon name="plus" size={18} />Add product</Link>
        </div>
      </div>

      <section className="stats" aria-label="Today">
        <div className="stat stat-hero">
          <span className="stat-label">Today's sales</span>
          <span className="stat-value">{lkr(d.todaySales)}</span>
          <span className="stat-note">{d.todayOrders} {d.todayOrders === 1 ? "order" : "orders"} today</span>
        </div>
        <Link to="/admin/orders?status=PENDING" className="stat stat-link">
          <span className="stat-label">Waiting to confirm</span>
          <span className="stat-value">{d.pending}</span>
          <span className="stat-note">{d.pending ? "Review pending orders" : "All caught up"}</span>
        </Link>
        <Link to="/admin/orders?status=PROCESSING" className="stat">
          <span className="stat-label">In progress</span>
          <span className="stat-value">{d.processing}</span>
          <span className="stat-note">Confirmed to dispatched</span>
        </Link>
        <div className="stat">
          <span className="stat-label">Delivered today</span>
          <span className="stat-value">{d.completed}</span>
          <span className="stat-note">Completed orders</span>
        </div>
      </section>

      <div className="dash-grid">
        <section className="panel">
          <div className="panel-head"><h2>Sales, last 7 days</h2><span className="panel-meta">{lkr(weekTotal)} total</span></div>
          <BarChart bars={bars} caption="Daily sales for the last 7 days" />
        </section>

        <section className="panel">
          <div className="panel-head"><h2>Low stock</h2><Link to="/admin/products?show=low" className="panel-link">Manage stock</Link></div>
          {d.lowStock.length ? (
            <ul className="stock-list">
              {d.lowStock.map((p) => (
                <li key={p.id}>
                  <Link to={`/admin/products/${p.id}`} className="stock-name" style={{ color: "var(--ink)", textDecoration: "none" }}>{p.name}<span className="muted">{p.code}</span></Link>
                  <span className={`stock-count ${p.stock === 0 ? "is-out" : ""}`}>{p.stock === 0 ? <><Icon name="alert" size={14} />Sold out</> : `${p.stock} left`}</span>
                </li>
              ))}
            </ul>
          ) : <p className="empty-note">Every product has more than 3 in stock.</p>}
        </section>

        <section className="panel panel-wide panel-flush">
          <div className="panel-head" style={{ padding: "22px 22px 0" }}><h2>Recent orders</h2><Link to="/admin/orders" className="panel-link">All orders</Link></div>
          {d.recentOrders.length ? (
            <div className="table-scroll">
              <table className="table">
                <thead><tr><th>Order</th><th>Customer</th><th className="num">Total</th><th>Status</th><th>Placed</th></tr></thead>
                <tbody>
                  {d.recentOrders.map((o) => (
                    <tr key={o.id}>
                      <td><Link to={`/admin/orders/${o.id}`}>{o.orderNo}</Link></td>
                      <td>{o.fullName}</td>
                      <td className="num">{lkr(o.total)}</td>
                      <td><StatusPill status={o.status} /></td>
                      <td className="muted">{dateTime(o.createdAt)}</td>
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

Write-ProjectFile 'frontend\src\pages\admin\Offers.tsx' @'
import { FormEvent, useEffect, useState } from "react";
import { api } from "../../api/client";
import type { Category, Offer, Product } from "../../api/types";
import { shortDate } from "../../api/format";
import { useToast } from "../../context/ToastContext";
import Icon from "../../components/Icon";
import { ConfirmDialog, EmptyState, ErrorState, Modal, PageLoading, Switch } from "../../components/ui";

type Scope = "shop" | "category" | "product";
const toInput = (iso?: string) => (iso ? new Date(iso).toISOString().slice(0, 10) : "");
const today = () => new Date().toISOString().slice(0, 10);
const plus = (days: number) => { const d = new Date(); d.setDate(d.getDate() + days); return d.toISOString().slice(0, 10); };

function offerState(o: Offer) {
  const now = Date.now();
  if (!o.isActive) return { label: "Off", cls: "pill-off" };
  if (new Date(o.startsAt).getTime() > now) return { label: "Scheduled", cls: "pill-confirmed" };
  if (new Date(o.endsAt).getTime() < now) return { label: "Ended", cls: "pill-off" };
  return { label: "Live", cls: "pill-on" };
}

export default function Offers() {
  const { show } = useToast();
  const [offers, setOffers] = useState<Offer[] | null>(null);
  const [cats, setCats] = useState<Category[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [err, setErr] = useState("");
  const [editing, setEditing] = useState<Offer | "new" | null>(null);
  const [scope, setScope] = useState<Scope>("shop");
  const [formErr, setFormErr] = useState("");
  const [busy, setBusy] = useState(false);
  const [deleting, setDeleting] = useState<Offer | null>(null);

  const load = () => { setErr(""); api.admin.offers().then(setOffers).catch((e) => setErr((e as Error).message)); };
  useEffect(() => {
    load();
    api.categories().then(setCats).catch(() => undefined);
    api.admin.products({ show: "active" }).then(async (first) => {
      const rest = await Promise.all(Array.from({ length: Math.min(first.pages, 10) - 1 }, (_, i) => api.admin.products({ show: "active", page: i + 2 })));
      setProducts([...first.items, ...rest.flatMap((r) => r.items)]);
    }).catch(() => undefined);
  }, []);

  const open = (o: Offer | "new") => {
    setFormErr("");
    setScope(o !== "new" && o.productId ? "product" : o !== "new" && o.categoryId ? "category" : "shop");
    setEditing(o);
  };

  const save = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    const body = {
      title: f.get("title"), percentOff: Number(f.get("percentOff")),
      startsAt: new Date(`${f.get("startsAt")}T00:00:00`).toISOString(),
      endsAt: new Date(`${f.get("endsAt")}T23:59:59`).toISOString(),
      isActive: !!f.get("isActive"),
      productId: scope === "product" ? f.get("productId") : null,
      categoryId: scope === "category" ? f.get("categoryId") : null,
    };
    setBusy(true); setFormErr("");
    try { await api.admin.saveOffer(body, editing === "new" ? undefined : editing!.id); show("Offer saved"); setEditing(null); load(); }
    catch (e) { setFormErr((e as Error).message); } finally { setBusy(false); }
  };
  const remove = async () => {
    setBusy(true);
    try { await api.admin.deleteOffer(deleting!.id); show("Offer deleted"); setDeleting(null); load(); }
    catch (e) { show((e as Error).message, { kind: "error" }); } finally { setBusy(false); }
  };

  const cur = editing && editing !== "new" ? editing : null;

  return (
    <div className="admin-page">
      <div className="admin-head">
        <div><h1>Offers</h1><p>Discounts show on product cards and are applied in the cart. If two offers cover a piece, the bigger one wins.</p></div>
        <button className="btn btn-primary" onClick={() => open("new")}><Icon name="plus" size={18} />Create offer</button>
      </div>

      {err ? <ErrorState message={err} onRetry={load} /> : !offers ? <PageLoading /> : !offers.length ? (
        <div className="panel"><EmptyState icon="offers" title="No offers yet" action={<button className="btn btn-primary" onClick={() => open("new")}>Create an offer</button>}>Run a sale on one piece, a whole category or the entire shop.</EmptyState></div>
      ) : (
        <div className="panel panel-flush">
          <div className="table-scroll">
            <table className="table">
              <thead><tr><th>Offer</th><th className="num">Discount</th><th>Applies to</th><th>Dates</th><th>Status</th><th><span className="sr-only">Actions</span></th></tr></thead>
              <tbody>
                {offers.map((o) => {
                  const st = offerState(o);
                  return (
                    <tr key={o.id}>
                      <td><strong>{o.title}</strong></td>
                      <td className="num">{o.percentOff}%</td>
                      <td>{o.product ? `${o.product.name} (${o.product.code})` : o.category ? `All ${o.category.name.toLowerCase()}` : "Whole shop"}</td>
                      <td className="muted">{shortDate(o.startsAt)} to {shortDate(o.endsAt)}</td>
                      <td><span className={`pill ${st.cls}`}>{st.label}</span></td>
                      <td><div className="row-actions">
                        <button className="icon-btn" aria-label={`Edit ${o.title}`} onClick={() => open(o)}><Icon name="edit" size={18} /></button>
                        <button className="icon-btn" aria-label={`Delete ${o.title}`} onClick={() => setDeleting(o)}><Icon name="trash" size={18} /></button>
                      </div></td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      <Modal open={!!editing} title={editing === "new" ? "Create offer" : "Edit offer"} onClose={() => setEditing(null)}>
        {editing && (
          <form className="form" onSubmit={save}>
            <label className="field"><span className="field-label">Title</span><input name="title" required maxLength={80} defaultValue={cur?.title} placeholder="Avurudu sale" autoFocus /><span className="field-hint">Shown on the product page</span></label>
            <label className="field"><span className="field-label">Discount (%)</span><input name="percentOff" type="number" required min={1} max={90} defaultValue={cur?.percentOff ?? 10} /></label>
            <fieldset className="fieldset">
              <legend>Applies to</legend>
              <div className="chips">
                {(["shop", "category", "product"] as Scope[]).map((s) => (
                  <button key={s} type="button" className="chip" aria-pressed={scope === s} onClick={() => setScope(s)}>{s === "shop" ? "Whole shop" : s === "category" ? "A category" : "One product"}</button>
                ))}
              </div>
              {scope === "category" && (
                <label className="field"><span className="sr-only">Category</span>
                  <select name="categoryId" required defaultValue={cur?.categoryId ?? ""}><option value="" disabled>Choose a category</option>{cats.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}</select>
                </label>
              )}
              {scope === "product" && (
                <label className="field"><span className="sr-only">Product</span>
                  <select name="productId" required defaultValue={cur?.productId ?? ""}><option value="" disabled>Choose a product</option>{products.map((p) => <option key={p.id} value={p.id}>{p.name} ({p.code})</option>)}</select>
                </label>
              )}
            </fieldset>
            <div className="form-grid">
              <label className="field"><span className="field-label">Starts</span><input name="startsAt" type="date" required defaultValue={toInput(cur?.startsAt) || today()} /></label>
              <label className="field"><span className="field-label">Ends</span><input name="endsAt" type="date" required defaultValue={toInput(cur?.endsAt) || plus(14)} /></label>
            </div>
            <Switch name="isActive" label="Offer is on" hint="Turn off to pause it without deleting" defaultChecked={cur?.isActive ?? true} />
            {formErr && <p className="form-error" role="alert">{formErr}</p>}
            <div className="modal-foot" style={{ margin: "4px -24px -24px" }}>
              <button type="button" className="btn btn-secondary" onClick={() => setEditing(null)}>Cancel</button>
              <button className="btn btn-primary" disabled={busy}>{busy ? "Saving…" : "Save offer"}</button>
            </div>
          </form>
        )}
      </Modal>

      <ConfirmDialog open={!!deleting} danger title="Delete this offer?" confirmLabel="Delete offer" busy={busy} onConfirm={remove} onClose={() => setDeleting(null)}
        body={<>{deleting?.title} will stop applying straight away. Past orders keep the price they were charged.</>} />
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\admin\OrderDetail.tsx' @'
import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { api } from "../../api/client";
import type { Order, OrderStatus, PaymentStatus } from "../../api/types";
import { dateTime, deliveryLabel, lkr, paymentLabel, paymentStatusLabel, phoneLink, statusLabel, whatsappLink } from "../../api/format";
import { useSettings } from "../../context/SettingsContext";
import { useToast } from "../../context/ToastContext";
import Icon from "../../components/Icon";
import { ConfirmDialog, ErrorState, PageLoading, ProductImage, StatusPill } from "../../components/ui";

const actionLabel: Record<OrderStatus, string> = {
  PENDING: "Pending", CONFIRMED: "Confirm order", PROCESSING: "Start processing", READY: "Mark ready",
  DISPATCHED: "Mark dispatched", DELIVERED: "Mark delivered", CANCELLED: "Cancel order",
};

export default function AdminOrderDetail() {
  const { id } = useParams();
  const s = useSettings();
  const { show } = useToast();
  const [o, setO] = useState<Order | null>(null);
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);
  const [cancelling, setCancelling] = useState(false);

  const load = () => { setErr(""); api.admin.order(id!).then(setO).catch((e) => setErr((e as Error).message)); };
  useEffect(load, [id]); // eslint-disable-line react-hooks/exhaustive-deps

  if (err && !o) return <ErrorState message={err} onRetry={load} />;
  if (!o) return <PageLoading />;

  const move = async (to: OrderStatus) => {
    setBusy(true);
    try { await api.admin.setStatus(o.id, to); show(`Order ${statusLabel[to].toLowerCase()}`); setCancelling(false); load(); }
    catch (e) { show((e as Error).message, { kind: "error" }); }
    finally { setBusy(false); }
  };
  const pay = async (ps: PaymentStatus) => {
    try { await api.admin.setPayment(o.id, ps); show(`Payment marked ${paymentStatusLabel[ps].toLowerCase()}`); load(); }
    catch (e) { show((e as Error).message, { kind: "error" }); }
  };

  const actions = (o.nextStatuses ?? []).filter((st) => st !== "CANCELLED");
  const labelFor = (st: OrderStatus) => (st === "DELIVERED" && o.deliveryMethod === "PICKUP" ? "Mark collected" : actionLabel[st]);
  const canCancel = o.nextStatuses?.includes("CANCELLED");
  const msg = `Hi ${o.fullName.split(" ")[0]}, this is ${s.shopName.replace(/^\[|\]$/g, "")} about your order ${o.orderNo}.`;
  const history = o.history ?? [];

  return (
    <div className="admin-page">
      <div className="admin-head">
        <div>
          <Link to="/admin/orders" className="back-link no-print"><Icon name="arrowLeft" size={16} />Orders</Link>
          <h1 style={{ display: "flex", gap: 14, alignItems: "center", flexWrap: "wrap" }}>{o.orderNo} <StatusPill status={o.status} /></h1>
          <p>Placed {dateTime(o.createdAt)}</p>
        </div>
        <div className="admin-head-actions no-print">
          <button className="btn btn-quiet" onClick={() => window.print()}><Icon name="print" size={18} />Print packing slip</button>
        </div>
      </div>

      <div className="print-only"><strong>{s.shopName}</strong>{s.phone && <><br />{s.phone}</>}{s.address && <><br />{s.address}</>}</div>

      <div className="detail-grid">
        <div className="stack">
          <section className="panel">
            <div className="panel-head"><h2>Items</h2><span className="panel-meta">{o.items.reduce((n, i) => n + i.qty, 0)} pieces</span></div>
            <div className="order-lines">
              {o.items.map((i) => (
                <div key={i.id} className="order-line">
                  <span className="order-line-img"><ProductImage url={i.product?.images[0]?.url} alt="" /></span>
                  <span>
                    <strong>{i.name}</strong> <span className="muted">× {i.qty}</span>
                    <span className="muted" style={{ display: "block", fontSize: 13 }}>{i.product?.code ? `Code ${i.product.code} · ` : ""}{lkr(i.price)} each</span>
                  </span>
                  <span className="num">{lkr(i.price * i.qty)}</span>
                </div>
              ))}
            </div>
            <div className="order-totals">
              <div className="summary-row"><span>Subtotal</span><span>{lkr(o.subtotal)}</span></div>
              <div className="summary-row"><span>{deliveryLabel[o.deliveryMethod]}</span><span>{o.deliveryFee ? lkr(o.deliveryFee) : "Free"}</span></div>
              <div className="summary-row summary-total"><span>Total</span><span>{lkr(o.total)}</span></div>
            </div>
          </section>

          {o.note && (
            <section className="panel"><h2 style={{ fontSize: 22, marginBottom: 10 }}>Customer note</h2><p style={{ whiteSpace: "pre-line" }}>{o.note}</p></section>
          )}

          <section className="panel no-print">
            <h2 style={{ fontSize: 22, marginBottom: 16 }}>History</h2>
            <ol className="timeline">
              {history.map((h, i) => (
                <li key={h.id} className={`tl-step ${i === history.length - 1 ? "is-current" : "is-done"}`}>
                  <span className="tl-dot">{i < history.length - 1 && <Icon name="check" size={16} />}</span>
                  <span className="tl-text"><strong>{statusLabel[h.status]}</strong><span>{dateTime(h.createdAt)}</span></span>
                </li>
              ))}
            </ol>
          </section>
        </div>

        <div className="detail-side">
          {(actions.length > 0 || canCancel) && (
            <section className="panel no-print">
              <h2 style={{ fontSize: 22, marginBottom: 14 }}>Next step</h2>
              <div className="status-actions">
                {actions.map((st, i) => (
                  <button key={st} className={`btn ${i === 0 ? "btn-primary" : "btn-secondary"} btn-block`} disabled={busy} onClick={() => move(st)}>{labelFor(st)}</button>
                ))}
                {canCancel && <button className="btn-link" style={{ color: "var(--error)" }} onClick={() => setCancelling(true)}>Cancel order</button>}
              </div>
            </section>
          )}

          <section className="panel">
            <h2 style={{ fontSize: 22, marginBottom: 14 }}>Customer</h2>
            <dl className="kv">
              <dt>Name</dt><dd>{o.fullName}</dd>
              <dt>Mobile</dt><dd>{o.mobile}</dd>
              {o.whatsapp && <><dt>WhatsApp</dt><dd>{o.whatsapp}</dd></>}
              {o.email && <><dt>Email</dt><dd>{o.email}</dd></>}
              <dt>Account</dt><dd>{o.user ? <Link to={`/admin/customers?q=${encodeURIComponent(o.user.email)}`}>{o.user.email}</Link> : "Guest"}</dd>
            </dl>
            <div className="contact-actions no-print">
              <a href={phoneLink(o.mobile)} className="btn btn-quiet btn-sm"><Icon name="phone" size={16} />Call</a>
              <a href={whatsappLink(o.whatsapp || o.mobile, msg)} target="_blank" rel="noreferrer" className="btn btn-quiet btn-sm"><Icon name="chat" size={16} />WhatsApp</a>
            </div>
          </section>

          <section className="panel">
            <h2 style={{ fontSize: 22, marginBottom: 14 }}>Delivery</h2>
            <dl className="kv">
              <dt>Method</dt><dd>{deliveryLabel[o.deliveryMethod]}</dd>
              {o.deliveryMethod === "DELIVERY" && <><dt>Address</dt><dd style={{ whiteSpace: "pre-line" }}>{[o.address, o.city, o.postalCode].filter(Boolean).join("\n")}</dd></>}
            </dl>
          </section>

          <section className="panel">
            <h2 style={{ fontSize: 22, marginBottom: 14 }}>Payment</h2>
            <dl className="kv">
              <dt>Method</dt><dd>{paymentLabel[o.paymentMethod]}</dd>
              <dt>Status</dt><dd><span className={`pill pill-${o.paymentStatus.toLowerCase()}`}>{paymentStatusLabel[o.paymentStatus]}</span></dd>
            </dl>
            <div className="contact-actions no-print">
              {o.paymentStatus !== "PAID" && <button className="btn btn-secondary btn-sm" onClick={() => pay("PAID")}><Icon name="check" size={16} />Mark as paid</button>}
              {o.paymentStatus === "PAID" && <button className="btn btn-quiet btn-sm" onClick={() => pay("UNPAID")}>Mark as not paid</button>}
              {o.paymentStatus === "PAID" && o.status === "CANCELLED" && <button className="btn btn-quiet btn-sm" onClick={() => pay("REFUNDED")}>Mark refunded</button>}
            </div>
          </section>
        </div>
      </div>

      <ConfirmDialog open={cancelling} danger title="Cancel this order?" confirmLabel="Cancel order" busy={busy} onConfirm={() => move("CANCELLED")} onClose={() => setCancelling(false)}
        body={<>The items go back into stock and the customer is told the order is cancelled.{o.paymentStatus === "PAID" && " This order is marked as paid, so arrange a refund."}</>} />
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\admin\Orders.tsx' @'
import { FormEvent, useEffect, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { api } from "../../api/client";
import type { OrderStatus, OrdersPage } from "../../api/types";
import { dateTime, deliveryLabel, lkr, paymentLabel, statusLabel } from "../../api/format";
import Icon from "../../components/Icon";
import { EmptyState, ErrorState, PageLoading, Pagination, StatusPill } from "../../components/ui";

const tabs: (OrderStatus | "")[] = ["", "PENDING", "CONFIRMED", "PROCESSING", "READY", "DISPATCHED", "DELIVERED", "CANCELLED"];

export default function AdminOrders() {
  const [sp, setSp] = useSearchParams();
  const [data, setData] = useState<OrdersPage | null>(null);
  const [err, setErr] = useState("");
  const status = (sp.get("status") ?? "") as OrderStatus | "";

  const load = () => {
    setErr("");
    api.admin.orders({ status: status || undefined, q: sp.get("q"), page: sp.get("page") ?? 1 }).then(setData).catch((e) => setErr((e as Error).message));
  };
  useEffect(load, [sp]); // eslint-disable-line react-hooks/exhaustive-deps

  const set = (k: string, v: string | null) => {
    const n = new URLSearchParams(sp);
    v ? n.set(k, v) : n.delete(k);
    if (k !== "page") n.delete("page");
    setSp(n);
  };
  const search = (e: FormEvent<HTMLFormElement>) => { e.preventDefault(); set("q", String(new FormData(e.currentTarget).get("q") || "") || null); };
  const all = data ? Object.values(data.byStatus).reduce((s, n) => s + (n ?? 0), 0) : 0;

  return (
    <div className="admin-page">
      <div className="admin-head"><div><h1>Orders</h1><p>{data ? `${data.total} ${status ? statusLabel[status].toLowerCase() : ""} ${data.total === 1 ? "order" : "orders"}` : " "}</p></div></div>

      <div className="tabs" role="group" aria-label="Filter by status">
        {tabs.map((t) => (
          <button key={t || "all"} className="tab" aria-pressed={status === t} onClick={() => set("status", t || null)}>
            {t ? statusLabel[t] : "All"}
            {data && <span className="tab-count">{t ? data.byStatus[t] ?? 0 : all}</span>}
          </button>
        ))}
      </div>
      <div className="toolbar">
        <form className="search" role="search" onSubmit={search}>
          <Icon name="search" size={18} />
          <label htmlFor="o-search" className="sr-only">Search orders</label>
          <input id="o-search" name="q" type="search" placeholder="Order number, name or mobile" defaultValue={sp.get("q") ?? ""} />
        </form>
        {sp.get("q") && <button className="btn-link" onClick={() => set("q", null)} style={{ fontSize: 14 }}>Clear search</button>}
      </div>

      {err ? <ErrorState message={err} onRetry={load} /> : !data ? <PageLoading /> : !data.items.length ? (
        <div className="panel"><EmptyState icon="orders" title={sp.get("q") ? "No orders match" : status ? `No ${statusLabel[status].toLowerCase()} orders` : "No orders yet"}>{sp.get("q") ? "Check the order number or mobile number." : "Orders from the shop appear here."}</EmptyState></div>
      ) : (
        <>
          <div className="panel panel-flush">
            <div className="table-scroll">
              <table className="table">
                <thead><tr><th>Order</th><th>Customer</th><th>Items</th><th className="num">Total</th><th>Payment</th><th>Delivery</th><th>Status</th><th>Placed</th></tr></thead>
                <tbody>
                  {data.items.map((o) => (
                    <tr key={o.id}>
                      <td><Link to={`/admin/orders/${o.id}`}>{o.orderNo}</Link></td>
                      <td>{o.fullName}<span className="muted" style={{ display: "block", fontSize: 13 }}>{o.mobile}</span></td>
                      <td>{o._count?.items ?? o.items?.length}</td>
                      <td className="num">{lkr(o.total)}</td>
                      <td>{paymentLabel[o.paymentMethod]}<span style={{ display: "block", marginTop: 4 }}><span className={`pill pill-${o.paymentStatus.toLowerCase()}`}>{o.paymentStatus === "PAID" ? "Paid" : o.paymentStatus === "REFUNDED" ? "Refunded" : "Not paid"}</span></span></td>
                      <td>{deliveryLabel[o.deliveryMethod]}{o.city && <span className="muted" style={{ display: "block", fontSize: 13 }}>{o.city}</span>}</td>
                      <td><StatusPill status={o.status} /></td>
                      <td className="muted">{dateTime(o.createdAt)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
          <Pagination page={data.page} pages={data.pages} onPage={(p) => set("page", String(p))} />
        </>
      )}
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\admin\ProductForm.tsx' @'
import { FormEvent, useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { api } from "../../api/client";
import type { Category, JewelleryType, Product, ProductImage as Img } from "../../api/types";
import { jewelleryTypes, typeLabel } from "../../api/format";
import { useToast } from "../../context/ToastContext";
import Icon from "../../components/Icon";
import { ErrorState, PageLoading, Switch } from "../../components/ui";

type NewFile = { file: File; url: string };
const okType = (f: File) => /image\/(jpeg|png|webp)/.test(f.type) && f.size <= 8 * 1024 * 1024;

export default function ProductForm() {
  const { id } = useParams();
  const isNew = !id;
  const nav = useNavigate();
  const { show } = useToast();
  const [p, setP] = useState<Product | null>(null);
  const [cats, setCats] = useState<Category[]>([]);
  const [images, setImages] = useState<Img[]>([]);
  const [files, setFiles] = useState<NewFile[]>([]);
  const [asset, setAsset] = useState<NewFile | null>(null);
  const [type, setType] = useState<JewelleryType>("EARRINGS");
  const [loadErr, setLoadErr] = useState("");
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    api.categories().then(setCats).catch(() => undefined);
    if (isNew) return;
    api.admin.product(id!).then((prod) => { setP(prod); setImages(prod.images); setType(prod.jewelleryType); }).catch((e) => setLoadErr((e as Error).message));
  }, [id, isNew]);

  useEffect(() => () => { files.forEach((f) => URL.revokeObjectURL(f.url)); if (asset) URL.revokeObjectURL(asset.url); }, []); // eslint-disable-line react-hooks/exhaustive-deps

  if (loadErr) return <ErrorState message={loadErr} />;
  if (!isNew && !p) return <PageLoading />;

  const addFiles = (list: FileList | null) => {
    if (!list) return;
    const good = Array.from(list).filter(okType);
    if (good.length < list.length) show("Some files were skipped. Use JPG, PNG or WebP up to 8 MB.", { kind: "error" });
    setFiles((prev) => [...prev, ...good.map((file) => ({ file, url: URL.createObjectURL(file) }))].slice(0, 10));
  };
  const removeNew = (i: number) => setFiles((prev) => { URL.revokeObjectURL(prev[i].url); return prev.filter((_, j) => j !== i); });

  const deleteImage = async (img: Img) => {
    try { await api.admin.deleteImage(p!.id, img.id); setImages((prev) => prev.filter((x) => x.id !== img.id)); show("Photo removed"); }
    catch (e) { show((e as Error).message, { kind: "error" }); }
  };
  const makeMain = async (img: Img) => {
    const order = [img.id, ...images.filter((x) => x.id !== img.id).map((x) => x.id)];
    try { await api.admin.orderImages(p!.id, order); setImages((prev) => [img, ...prev.filter((x) => x.id !== img.id)]); show("Main photo updated"); }
    catch (e) { show((e as Error).message, { kind: "error" }); }
  };
  const removeAsset = async () => {
    if (asset) { URL.revokeObjectURL(asset.url); setAsset(null); return; }
    try { await api.admin.removeTryOnAsset(p!.id); setP({ ...p!, tryOnAssetUrl: null }); show("Try-on image removed"); }
    catch (e) { show((e as Error).message, { kind: "error" }); }
  };

  const submit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);
    for (const k of ["isActive", "isNewArrival", "tryOnEnabled"]) fd.set(k, fd.get(k) ? "true" : "false");
    fd.delete("imagesPicker"); fd.delete("assetPicker");
    files.forEach((f) => fd.append("images", f.file));
    if (asset) fd.set("tryOnAsset", asset.file);
    setBusy(true); setErr("");
    try {
      const saved = await api.admin.saveProduct(fd, id);
      show(isNew ? `${saved.name} added to the shop` : "Changes saved");
      nav(isNew ? "/admin/products" : `/admin/products`, { replace: isNew });
    } catch (e) {
      setErr((e as Error).message);
      window.scrollTo({ top: 0, behavior: "smooth" });
    } finally { setBusy(false); }
  };

  const assetUrl = asset?.url ?? p?.tryOnAssetUrl;

  return (
    <form className="admin-page" onSubmit={submit}>
      <div className="admin-head">
        <div>
          <Link to="/admin/products" className="back-link"><Icon name="arrowLeft" size={16} />Products</Link>
          <h1>{isNew ? "Add product" : p!.name}</h1>
        </div>
        {!isNew && p!.isActive && <a href={`/product/${p!.slug}`} target="_blank" rel="noreferrer" className="btn btn-quiet"><Icon name="eye" size={18} />View in shop</a>}
      </div>
      {err && <p className="form-error" role="alert">{err}</p>}

      <div className="admin-form">
        <div className="admin-form-main">
          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>Details</h2>
            <div className="form-grid">
              <label className="field span-2"><span className="field-label">Product name</span><input name="name" required minLength={2} maxLength={120} defaultValue={p?.name} placeholder="Gold jhumka earrings" /></label>
              <label className="field"><span className="field-label">Product code</span><input name="code" required maxLength={30} defaultValue={p?.code} placeholder="ER025" autoCapitalize="characters" /></label>
              <label className="field"><span className="field-label">Category</span>
                <select name="categoryId" required defaultValue={p?.categoryId ?? ""}>
                  <option value="" disabled>Choose a category</option>
                  {cats.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
                </select>
              </label>
              <label className="field span-2"><span className="field-label">Description</span><textarea name="description" rows={5} maxLength={4000} defaultValue={p?.description ?? ""} placeholder="Materials, size, finish and how to care for it" /></label>
              <label className="field"><span className="field-label">Style <span className="optional">(optional)</span></span><input name="style" maxLength={40} defaultValue={p?.style ?? ""} placeholder="Traditional, Modern…" /><span className="field-hint">Shown as a filter in the shop</span></label>
              <label className="field"><span className="field-label">Colour <span className="optional">(optional)</span></span><input name="colour" maxLength={40} defaultValue={p?.colour ?? ""} placeholder="Gold, Silver, Rose gold…" /></label>
            </div>
          </section>

          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>Photos</h2>
            <p className="field-hint" style={{ marginTop: -8 }}>The first photo is the main one in the shop. JPG, PNG or WebP, up to 8 MB each.</p>
            <div className="image-manager">
              {images.map((img, i) => (
                <div key={img.id} className="im-tile">
                  <img src={img.url} alt={`Photo ${i + 1}`} />
                  {i === 0 && <span className="im-tile-main">Main</span>}
                  <div className="im-tile-actions">
                    {i > 0 && <button type="button" className="icon-btn" aria-label={`Make photo ${i + 1} the main photo`} title="Make main" onClick={() => makeMain(img)}><Icon name="check" size={16} /></button>}
                    <button type="button" className="icon-btn" aria-label={`Remove photo ${i + 1}`} title="Remove" onClick={() => deleteImage(img)}><Icon name="trash" size={16} /></button>
                  </div>
                </div>
              ))}
              {files.map((f, i) => (
                <div key={f.url} className="im-tile">
                  <img src={f.url} alt={`New photo ${i + 1}`} />
                  <span className={images.length === 0 && i === 0 ? "im-tile-main" : "im-tile-new"}>{images.length === 0 && i === 0 ? "Main" : "New"}</span>
                  <div className="im-tile-actions"><button type="button" className="icon-btn" aria-label={`Remove new photo ${i + 1}`} onClick={() => removeNew(i)}><Icon name="close" size={16} /></button></div>
                </div>
              ))}
              {images.length + files.length < 10 && (
                <label className="im-add">
                  <Icon name="image" size={24} />Add photos
                  <input name="imagesPicker" type="file" accept="image/jpeg,image/png,image/webp" multiple onChange={(e) => { addFiles(e.target.files); e.target.value = ""; }} />
                </label>
              )}
            </div>
          </section>

          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>AI try-on</h2>
            <Switch name="tryOnEnabled" label="Customers can try this on with AI" defaultChecked={p?.tryOnEnabled ?? true} />
            <label className="field"><span className="field-label">Jewellery type</span>
              <select name="jewelleryType" value={type} onChange={(e) => setType(e.target.value as JewelleryType)}>
                {jewelleryTypes.map((t) => <option key={t} value={t}>{typeLabel[t]}</option>)}
              </select>
              <span className="field-hint">Tells the AI where the piece is worn, for example earrings on the earlobes.</span>
            </label>
            <div className="field">
              <span className="field-label">Try-on image <span className="optional">(optional)</span></span>
              <div className="asset-row">
                <span className="asset-preview">{assetUrl ? <img src={assetUrl} alt="Try-on image" /> : <Icon name="image" size={28} />}</span>
                <div className="stack" style={{ gap: 8 }}>
                  <span className="field-hint">A PNG of just the piece on a transparent background gives the best results. Without one, the main photo is used.</span>
                  <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                    <label className="btn btn-quiet btn-sm">
                      <Icon name="upload" size={16} />{assetUrl ? "Replace" : "Upload PNG"}
                      <input name="assetPicker" type="file" accept="image/png,image/webp" className="sr-only" onChange={(e) => { const f = e.target.files?.[0]; if (f && okType(f)) setAsset({ file: f, url: URL.createObjectURL(f) }); e.target.value = ""; }} />
                    </label>
                    {assetUrl && <button type="button" className="btn btn-quiet btn-sm" onClick={removeAsset}>Remove</button>}
                  </div>
                </div>
              </div>
            </div>
          </section>
        </div>

        <div className="admin-form-side">
          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>Price and stock</h2>
            <label className="field"><span className="field-label">Price (LKR)</span><input name="price" type="number" required min={1} step={1} inputMode="numeric" defaultValue={p?.price} /></label>
            <label className="field"><span className="field-label">Stock</span><input name="stock" type="number" required min={0} step={1} inputMode="numeric" defaultValue={p?.stock ?? 1} /><span className="field-hint">Shows as sold out at 0</span></label>
          </section>
          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>Visibility</h2>
            <Switch name="isActive" label="Show in the shop" defaultChecked={p?.isActive ?? true} />
            <Switch name="isNewArrival" label="Show in New arrivals" defaultChecked={p?.isNewArrival ?? true} />
          </section>
        </div>
      </div>

      <div className="save-bar">
        <Link to="/admin/products" className="btn btn-quiet">Cancel</Link>
        <button className="btn btn-primary" disabled={busy}>{busy ? "Saving…" : isNew ? "Add product" : "Save changes"}</button>
      </div>
    </form>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\admin\Products.tsx' @'
import { FormEvent, useEffect, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { api } from "../../api/client";
import type { Category, Paged, Product } from "../../api/types";
import { lkr } from "../../api/format";
import { useToast } from "../../context/ToastContext";
import Icon from "../../components/Icon";
import { ConfirmDialog, EmptyState, ErrorState, PageLoading, Pagination, ProductImage } from "../../components/ui";

const shows = [
  { v: "all", label: "All" },
  { v: "active", label: "In the shop" },
  { v: "low", label: "Low stock" },
  { v: "hidden", label: "Hidden" },
];

export default function AdminProducts() {
  const [sp, setSp] = useSearchParams();
  const { show } = useToast();
  const [data, setData] = useState<Paged<Product> | null>(null);
  const [cats, setCats] = useState<Category[]>([]);
  const [err, setErr] = useState("");
  const [hiding, setHiding] = useState<Product | null>(null);
  const [busy, setBusy] = useState(false);

  const load = () => {
    setErr("");
    api.admin.products({ q: sp.get("q"), categoryId: sp.get("category"), show: sp.get("show") ?? "all", page: sp.get("page") ?? 1 })
      .then(setData).catch((e) => setErr((e as Error).message));
  };
  useEffect(load, [sp]);
  useEffect(() => { api.categories().then(setCats).catch(() => undefined); }, []);

  const set = (k: string, v: string | null) => {
    const n = new URLSearchParams(sp);
    v ? n.set(k, v) : n.delete(k);
    if (k !== "page") n.delete("page");
    setSp(n);
  };
  const search = (e: FormEvent<HTMLFormElement>) => { e.preventDefault(); set("q", String(new FormData(e.currentTarget).get("q") || "") || null); };

  const hide = async () => {
    if (!hiding) return;
    setBusy(true);
    try { await api.admin.hideProduct(hiding.id); show(`${hiding.name} is hidden from the shop`); setHiding(null); load(); }
    catch (e) { show((e as Error).message, { kind: "error" }); }
    finally { setBusy(false); }
  };

  return (
    <div className="admin-page">
      <div className="admin-head">
        <div><h1>Products</h1><p>{data ? `${data.total} ${data.total === 1 ? "product" : "products"}` : " "}</p></div>
        <Link to="/admin/products/new" className="btn btn-primary"><Icon name="plus" size={18} />Add product</Link>
      </div>

      <div className="toolbar">
        <form className="search" role="search" onSubmit={search}>
          <Icon name="search" size={18} />
          <label htmlFor="p-search" className="sr-only">Search products</label>
          <input id="p-search" name="q" type="search" placeholder="Name or code" defaultValue={sp.get("q") ?? ""} />
        </form>
        <label><span className="sr-only">Category</span>
          <select value={sp.get("category") ?? ""} onChange={(e) => set("category", e.target.value || null)}>
            <option value="">All categories</option>
            {cats.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
          </select>
        </label>
        <div className="tabs" role="group" aria-label="Show">
          {shows.map((s) => <button key={s.v} className="tab" aria-pressed={(sp.get("show") ?? "all") === s.v} onClick={() => set("show", s.v === "all" ? null : s.v)}>{s.label}</button>)}
        </div>
      </div>

      {err ? <ErrorState message={err} onRetry={load} /> : !data ? <PageLoading /> : !data.items.length ? (
        <div className="panel">
          <EmptyState icon="products" title={sp.toString() ? "No products match" : "No products yet"} action={<Link to="/admin/products/new" className="btn btn-primary">Add your first product</Link>}>
            {sp.toString() ? "Try another search or filter." : "Products you add appear in the shop straight away."}
          </EmptyState>
        </div>
      ) : (
        <>
          <div className="panel panel-flush">
            <div className="table-scroll">
              <table className="table">
                <thead><tr><th>Product</th><th>Category</th><th className="num">Price</th><th className="num">Stock</th><th>Try-on</th><th>Status</th><th><span className="sr-only">Actions</span></th></tr></thead>
                <tbody>
                  {data.items.map((p) => (
                    <tr key={p.id} className={p.isActive ? "" : "is-hidden-row"}>
                      <td>
                        <div className="cell-product">
                          <span className="table-thumb"><ProductImage url={p.images[0]?.url} alt="" type={p.jewelleryType} iconSize={24} /></span>
                          <span><Link to={`/admin/products/${p.id}`}>{p.name}</Link><span className="muted" style={{ display: "block" }}>{p.code}</span></span>
                        </div>
                      </td>
                      <td>{p.category?.name}</td>
                      <td className="num">{lkr(p.price)}</td>
                      <td className="num"><span className={p.stock === 0 ? "stock-num-out" : p.stock <= 3 ? "stock-num-low" : ""}>{p.stock}</span></td>
                      <td>{p.tryOnEnabled ? <span className="pill pill-on">On</span> : <span className="pill pill-off">Off</span>}</td>
                      <td>{p.isActive ? <span className="pill pill-on">In shop</span> : <span className="pill pill-off">Hidden</span>}</td>
                      <td>
                        <div className="row-actions">
                          <Link to={`/admin/products/${p.id}`} className="icon-btn" aria-label={`Edit ${p.name}`}><Icon name="edit" size={18} /></Link>
                          {p.isActive && <a href={`/product/${p.slug}`} target="_blank" rel="noreferrer" className="icon-btn" aria-label={`View ${p.name} in the shop`}><Icon name="eye" size={18} /></a>}
                          {p.isActive && <button className="icon-btn" aria-label={`Hide ${p.name}`} onClick={() => setHiding(p)}><Icon name="eyeOff" size={18} /></button>}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
          <Pagination page={data.page} pages={data.pages} onPage={(p) => set("page", String(p))} />
        </>
      )}

      <ConfirmDialog open={!!hiding} title="Hide this product?" confirmLabel="Hide product" busy={busy} onConfirm={hide} onClose={() => setHiding(null)}
        body={<>{hiding?.name} will be removed from the shop. Past orders keep it, and you can show it again from its edit page.</>} />
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\admin\Reports.tsx' @'
import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../../api/client";
import type { OrderStatus, ProductReport, SalesRow } from "../../api/types";
import { lkr, shortDate, statusLabel } from "../../api/format";
import BarChart from "../../components/BarChart";
import { ErrorState, PageLoading } from "../../components/ui";

type Range = "daily" | "weekly" | "monthly";
const ranges: { v: Range; label: string }[] = [{ v: "daily", label: "Daily" }, { v: "weekly", label: "Weekly" }, { v: "monthly", label: "Monthly" }];

function periodLabels(iso: string, range: Range) {
  const d = new Date(iso);
  if (range === "monthly") return { label: d.toLocaleDateString("en-GB", { month: "short" }), full: d.toLocaleDateString("en-GB", { month: "long", year: "numeric" }) };
  if (range === "weekly") return { label: d.toLocaleDateString("en-GB", { day: "numeric", month: "short" }), full: `Week of ${d.toLocaleDateString("en-GB", { day: "numeric", month: "long" })}` };
  return { label: d.toLocaleDateString("en-GB", { day: "numeric" }), full: d.toLocaleDateString("en-GB", { weekday: "short", day: "numeric", month: "short" }) };
}

export default function Reports() {
  const [range, setRange] = useState<Range>("daily");
  const [sales, setSales] = useState<SalesRow[] | null>(null);
  const [byStatus, setByStatus] = useState<{ status: OrderStatus; count: number }[] | null>(null);
  const [prod, setProd] = useState<ProductReport | null>(null);
  const [err, setErr] = useState("");

  useEffect(() => { setSales(null); api.admin.salesReport(range).then(setSales).catch((e) => setErr((e as Error).message)); }, [range]);
  useEffect(() => {
    api.admin.ordersReport().then(setByStatus).catch((e) => setErr((e as Error).message));
    api.admin.productsReport().then(setProd).catch((e) => setErr((e as Error).message));
  }, []);

  if (err) return <ErrorState message={err} />;

  const total = sales?.reduce((s, r) => s + r.sales, 0) ?? 0;
  const orders = sales?.reduce((s, r) => s + r.orders, 0) ?? 0;
  const maxStatus = Math.max(1, ...(byStatus ?? []).map((s) => s.count));

  return (
    <div className="admin-page">
      <div className="admin-head"><div><h1>Reports</h1><p>Cancelled orders are left out of sales.</p></div></div>

      <section className="panel">
        <div className="panel-head">
          <h2>Sales</h2>
          <div className="tabs" role="group" aria-label="Period">
            {ranges.map((r) => <button key={r.v} className="tab" aria-pressed={range === r.v} onClick={() => setRange(r.v)}>{r.label}</button>)}
          </div>
        </div>
        {!sales ? <PageLoading /> : !sales.length ? <p className="empty-note">No sales yet.</p> : (
          <>
            <p className="panel-meta" style={{ marginBottom: 16 }}>{lkr(total)} from {orders} orders · average {lkr(orders ? total / orders : 0)} per order</p>
            <BarChart caption={`${ranges.find((r) => r.v === range)!.label} sales`} height={260}
              bars={sales.map((r, i) => { const l = periodLabels(r.period, range); return { key: r.period, label: l.label, fullLabel: l.full, value: r.sales, orders: r.orders, highlight: i === sales.length - 1 }; })} />
          </>
        )}
      </section>

      <div className="report-grid">
        <section className="panel">
          <div className="panel-head"><h2>Orders by status</h2><Link to="/admin/orders" className="panel-link">All orders</Link></div>
          {!byStatus ? <PageLoading /> : (
            <div className="hbars">
              {byStatus.map((s) => (
                <Link key={s.status} to={`/admin/orders?status=${s.status}`} className="hbar" style={{ color: "var(--ink)", textDecoration: "none" }}>
                  <span>{statusLabel[s.status]}</span>
                  <span className="hbar-track" aria-hidden="true"><span className="hbar-fill" style={{ display: "block", width: `${(s.count / maxStatus) * 100}%` }} /></span>
                  <span className="hbar-value">{s.count}</span>
                </Link>
              ))}
            </div>
          )}
        </section>

        <section className="panel">
          <div className="panel-head"><h2>Best sellers</h2><span className="panel-meta">Pieces sold</span></div>
          {!prod ? <PageLoading /> : prod.top.length ? (
            <ol className="rank-list">{prod.top.map((t) => <li key={t.productId}><Link to={`/admin/products/${t.productId}`}>{t.name}</Link><strong>{t.qty}</strong></li>)}</ol>
          ) : <p className="empty-note">No sales yet.</p>}
        </section>

        <section className="panel">
          <div className="panel-head"><h2>Most tried on</h2><span className="panel-meta">AI try-ons</span></div>
          {!prod ? <PageLoading /> : prod.mostTried.length ? (
            <ol className="rank-list">{prod.mostTried.map((t, i) => <li key={t.id ?? i}>{t.id ? <Link to={`/admin/products/${t.id}`}>{t.name}</Link> : <span className="muted">Deleted product</span>}<strong>{t.tries}</strong></li>)}</ol>
          ) : <p className="empty-note">No try-ons yet.</p>}
        </section>

        <section className="panel">
          <div className="panel-head"><h2>Sold out</h2><Link to="/admin/products?show=low" className="panel-link">Update stock</Link></div>
          {!prod ? <PageLoading /> : prod.outOfStock.length ? (
            <ul className="stock-list">{prod.outOfStock.map((p) => <li key={p.id}><Link to={`/admin/products/${p.id}`} className="stock-name">{p.name}<span className="muted">{p.code}</span></Link><span className="stock-count is-out">Sold out</span></li>)}</ul>
          ) : <p className="empty-note">Nothing is sold out.</p>}
        </section>

        <section className="panel panel-wide" style={{ gridColumn: "1 / -1" }}>
          <div className="panel-head"><h2>Newest products</h2><Link to="/admin/products" className="panel-link">All products</Link></div>
          {!prod ? <PageLoading /> : prod.newest.length ? (
            <ul className="stock-list">{prod.newest.map((p) => <li key={p.id}><Link to={`/admin/products/${p.id}`} className="stock-name">{p.name}<span className="muted">{p.code}</span></Link><span className="muted" style={{ fontSize: 14 }}>Added {shortDate(p.createdAt)}</span></li>)}</ul>
          ) : <p className="empty-note">No products yet.</p>}
        </section>
      </div>
    </div>
  );
}
'@

Write-ProjectFile 'frontend\src\pages\admin\Settings.tsx' @'
import { FormEvent, useState } from "react";
import { api } from "../../api/client";
import { useReloadSettings, useSettings } from "../../context/SettingsContext";
import { useToast } from "../../context/ToastContext";
import { Switch } from "../../components/ui";

export default function SettingsPage() {
  const s = useSettings();
  const reload = useReloadSettings();
  const { show } = useToast();
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  const save = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    const text = (k: string) => String(f.get(k) ?? "").trim();
    const body = {
      shopName: text("shopName"), tagline: text("tagline"), phone: text("phone"), whatsapp: text("whatsapp"),
      email: text("email"), address: text("address"), bankDetails: text("bankDetails"),
      deliveryFee: Number(f.get("deliveryFee") || 0),
      freeDeliveryOver: f.get("freeDeliveryOver") ? Number(f.get("freeDeliveryOver")) : null,
      codEnabled: !!f.get("codEnabled"), bankEnabled: !!f.get("bankEnabled"), onlineEnabled: !!f.get("onlineEnabled"), pickupEnabled: !!f.get("pickupEnabled"),
    };
    if (!body.codEnabled && !body.bankEnabled && !body.onlineEnabled) { setErr("Turn on at least one payment method so customers can order."); return; }
    setBusy(true); setErr("");
    try { await api.admin.saveSettings(body); await reload(); show("Settings saved"); }
    catch (e) { setErr((e as Error).message); } finally { setBusy(false); }
  };

  return (
    <form className="admin-page" onSubmit={save} key={s.shopName + s.phone}>
      <div className="admin-head"><div><h1>Settings</h1><p>These details appear across the shop, at checkout and in messages to customers.</p></div></div>
      {err && <p className="form-error" role="alert">{err}</p>}

      <div className="admin-form">
        <div className="admin-form-main">
          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>Shop</h2>
            <div className="form-grid">
              <label className="field"><span className="field-label">Shop name</span><input name="shopName" required maxLength={80} defaultValue={s.shopName} /></label>
              <label className="field"><span className="field-label">Tagline</span><input name="tagline" maxLength={200} defaultValue={s.tagline} /></label>
              <label className="field span-2"><span className="field-label">Address</span><textarea name="address" rows={2} maxLength={300} defaultValue={s.address} /><span className="field-hint">Shown for store pickup and on the contact page</span></label>
            </div>
          </section>
          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>Contact</h2>
            <div className="form-grid">
              <label className="field"><span className="field-label">Phone</span><input name="phone" type="tel" maxLength={30} defaultValue={s.phone} placeholder="0XX XXX XXXX" /></label>
              <label className="field"><span className="field-label">WhatsApp</span><input name="whatsapp" type="tel" maxLength={30} defaultValue={s.whatsapp} placeholder="07XXXXXXXX" /><span className="field-hint">Used for WhatsApp buttons and new-order alerts</span></label>
              <label className="field span-2"><span className="field-label">Email</span><input name="email" type="email" maxLength={120} defaultValue={s.email} /></label>
            </div>
          </section>
          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>Payment</h2>
            <Switch name="codEnabled" label="Cash on delivery" defaultChecked={s.codEnabled} />
            <Switch name="bankEnabled" label="Bank transfer" defaultChecked={s.bankEnabled} />
            <label className="field"><span className="field-label">Bank details</span><textarea name="bankDetails" rows={4} maxLength={1000} defaultValue={s.bankDetails} placeholder={"Bank: \nBranch: \nAccount name: \nAccount number: "} /><span className="field-hint">Shown to customers who choose bank transfer</span></label>
            <Switch name="onlineEnabled" label="Online card payment" hint="Needs a payment gateway such as PayHere to be connected first" defaultChecked={s.onlineEnabled} />
          </section>
        </div>
        <div className="admin-form-side">
          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>Delivery</h2>
            <label className="field"><span className="field-label">Delivery fee (LKR)</span><input name="deliveryFee" type="number" min={0} step={1} required defaultValue={s.deliveryFee} /></label>
            <label className="field"><span className="field-label">Free delivery over (LKR) <span className="optional">(optional)</span></span><input name="freeDeliveryOver" type="number" min={0} step={1} defaultValue={s.freeDeliveryOver ?? ""} /><span className="field-hint">Leave empty to always charge</span></label>
            <Switch name="pickupEnabled" label="Store pickup" hint="Free for the customer" defaultChecked={s.pickupEnabled} />
          </section>
        </div>
      </div>

      <div className="save-bar"><button className="btn btn-primary" disabled={busy}>{busy ? "Saving…" : "Save settings"}</button></div>
    </form>
  );
}
'@

Write-ProjectFile 'frontend\src\context\AuthContext.tsx' @'
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
  setUser: (u: User) => void;
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
    if (u.role === "CUSTOMER") await api.mergeCart().catch(() => undefined);
    await refresh().catch(() => undefined);
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
    setUser,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export const useAuth = () => useContext(AuthContext);
'@

Write-ProjectFile 'frontend\src\context\CartContext.tsx' @'
import { createContext, useContext, useEffect, useState, ReactNode } from "react";
import { api } from "../api/client";
import type { Cart } from "../api/types";
import { useToast } from "./ToastContext";

type Ctx = {
  cart: Cart | null;
  count: number;
  add: (items: { productId: string; qty: number }[], message?: string) => Promise<boolean>;
  setQty: (productId: string, qty: number) => Promise<void>;
  remove: (productId: string) => Promise<void>;
  refresh: () => Promise<void>;
};
const CartContext = createContext<Ctx>(null!);

export function CartProvider({ children }: { children: ReactNode }) {
  const { show } = useToast();
  const [cart, setCart] = useState<Cart | null>(null);
  const refresh = async () => setCart(await api.cart());
  useEffect(() => { refresh().catch(() => undefined); }, []);

  const value: Ctx = {
    cart,
    count: cart?.items.reduce((s, i) => s + i.qty, 0) ?? 0,
    add: async (items, message) => {
      try {
        setCart(await api.addToCart(items));
        show(message ?? "Added to cart", { link: { to: "/cart", label: "View cart" } });
        return true;
      } catch (e) {
        show((e as Error).message, { kind: "error" });
        return false;
      }
    },
    setQty: async (id, qty) => {
      try { setCart(await api.setQty(id, qty)); } catch (e) { show((e as Error).message, { kind: "error" }); }
    },
    remove: async (id) => {
      try { setCart(await api.removeItem(id)); show("Removed from cart"); } catch (e) { show((e as Error).message, { kind: "error" }); }
    },
    refresh,
  };
  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}
export const useCart = () => useContext(CartContext);
'@

Write-ProjectFile 'frontend\src\context\SettingsContext.tsx' @'
import { createContext, useContext, useEffect, useState, ReactNode } from "react";
import { api } from "../api/client";
import type { Settings } from "../api/types";

const defaults: Settings = {
  shopName: "[Shop name]", tagline: "Jewellery for every day and every occasion.",
  phone: "", whatsapp: "", email: "", address: "",
  deliveryFee: 450, freeDeliveryOver: null, bankDetails: "",
  codEnabled: true, bankEnabled: true, onlineEnabled: false, pickupEnabled: true,
};

type Ctx = { settings: Settings; reload: () => Promise<void> };
const SettingsContext = createContext<Ctx>({ settings: defaults, reload: async () => undefined });

export function SettingsProvider({ children }: { children: ReactNode }) {
  const [settings, setSettings] = useState<Settings>(defaults);
  const reload = async () => {
    const data = await api.settings();
    // Keep defaults for anything the server doesn't send (for example an older backend).
    if (data && typeof data === "object" && !Array.isArray(data)) setSettings({ ...defaults, ...data });
  };

  useEffect(() => { reload().catch(() => undefined); }, []);
  useEffect(() => { document.title = settings.shopName.replace(/^\[|\]$/g, "") || "Jewellery"; }, [settings.shopName]);

  return <SettingsContext.Provider value={{ settings, reload }}>{children}</SettingsContext.Provider>;
}

export const useSettings = () => useContext(SettingsContext).settings;
export const useReloadSettings = () => useContext(SettingsContext).reload;
'@

Write-ProjectFile 'frontend\src\context\ToastContext.tsx' @'
import { createContext, useCallback, useContext, useRef, useState, ReactNode } from "react";
import { Link } from "react-router-dom";
import Icon from "../components/Icon";

type Toast = { id: number; text: string; kind: "ok" | "error"; link?: { to: string; label: string } };
type Ctx = { show: (text: string, opts?: { kind?: "ok" | "error"; link?: { to: string; label: string } }) => void };

const ToastContext = createContext<Ctx>({ show: () => undefined });

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);
  const nextId = useRef(1);

  const dismiss = (id: number) => setToasts((t) => t.filter((x) => x.id !== id));
  const show = useCallback<Ctx["show"]>((text, opts = {}) => {
    const id = nextId.current++;
    setToasts((t) => [...t.slice(-2), { id, text, kind: opts.kind ?? "ok", link: opts.link }]);
    window.setTimeout(() => dismiss(id), opts.kind === "error" ? 6000 : 3500);
  }, []);

  return (
    <ToastContext.Provider value={{ show }}>
      {children}
      <div className="toasts" role="status" aria-live="polite">
        {toasts.map((t) => (
          <div key={t.id} className={`toast toast-${t.kind}`}>
            <Icon name={t.kind === "ok" ? "check" : "alert"} size={18} />
            <span className="toast-text">{t.text}</span>
            {t.link && <Link to={t.link.to} className="toast-link" onClick={() => dismiss(t.id)}>{t.link.label}</Link>}
            <button className="icon-btn icon-btn-sm" aria-label="Dismiss" onClick={() => dismiss(t.id)}><Icon name="close" size={16} /></button>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export const useToast = () => useContext(ToastContext);
'@

Write-ProjectFile 'frontend\src\context\WishlistContext.tsx' @'
import { createContext, useContext, useEffect, useState, ReactNode } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { api } from "../api/client";
import { useAuth } from "./AuthContext";
import { useToast } from "./ToastContext";

type Ctx = { ids: Set<string>; has: (id: string) => boolean; toggle: (id: string, name?: string) => Promise<void> };
const WishlistContext = createContext<Ctx>({ ids: new Set(), has: () => false, toggle: async () => undefined });

export function WishlistProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();
  const { show } = useToast();
  const nav = useNavigate();
  const loc = useLocation();
  const [ids, setIds] = useState<Set<string>>(new Set());

  useEffect(() => {
    if (user?.role !== "CUSTOMER") { setIds(new Set()); return; }
    api.wishlistIds().then((list) => setIds(new Set(list))).catch(() => undefined);
  }, [user]);

  const toggle = async (id: string, name?: string) => {
    if (!user) {
      show("Sign in to save pieces to your wishlist");
      nav("/login", { state: { from: loc.pathname + loc.search } });
      return;
    }
    const had = ids.has(id);
    const next = new Set(ids);
    had ? next.delete(id) : next.add(id);
    setIds(next);
    try {
      had ? await api.removeWish(id) : await api.addWish(id);
      show(had ? "Removed from wishlist" : `${name ?? "Saved"} added to your wishlist`, had ? {} : { link: { to: "/account/wishlist", label: "View" } });
    } catch (e) {
      setIds(ids);
      show((e as Error).message, { kind: "error" });
    }
  };

  return <WishlistContext.Provider value={{ ids, has: (id) => ids.has(id), toggle }}>{children}</WishlistContext.Provider>;
}

export const useWishlist = () => useContext(WishlistContext);
'@

Write-ProjectFile 'backend\src\middleware\auth.ts' @'
import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { env } from "../config/env";
import { db } from "../config/db";

export type AuthUser = { id: string; role: "CUSTOMER" | "ADMIN" };
declare global { namespace Express { interface Request { user?: AuthUser } } }

export const signToken = (u: AuthUser) => jwt.sign(u, env.jwtSecret, { expiresIn: "7d" });

// Reads the login token if there is one. A token for a user that no longer exists
// (for example after the database was reset) is ignored, so the request continues as a guest.
export async function optionalAuth(req: Request, _res: Response, next: NextFunction) {
  const t = req.headers.authorization?.replace("Bearer ", "");
  if (t) {
    try {
      const payload = jwt.verify(t, env.jwtSecret) as AuthUser;
      const u = await db.user.findUnique({ where: { id: payload.id }, select: { id: true, role: true } });
      if (u) req.user = { id: u.id, role: u.role };
    } catch { /* bad or expired token: treat as guest */ }
  }
  next();
}

export function requireAuth(req: Request, res: Response, next: NextFunction) {
  optionalAuth(req, res, () => (req.user ? next() : res.status(401).json({ error: "Sign in required" })));
}

export function requireAdmin(req: Request, res: Response, next: NextFunction) {
  requireAuth(req, res, () => (req.user?.role === "ADMIN" ? next() : res.status(403).json({ error: "Admin only" })));
}
'@

Write-ProjectFile 'backend\prisma\seed-demo.ts' @'
// Demo products with real photos so the shop looks complete while you set it up.
//   npm run seed:demo            add (or refresh) the demo products, model photos and category images
//   npm run seed:demo -- --remove   take all demo content out again
//
// Photos are free Unsplash photos (https://unsplash.com/license), loaded straight from Unsplash.
// They show jewellery you may not stock, so replace them with your own pieces before you open the shop.
import { PrismaClient, JewelleryType } from "@prisma/client";
const db = new PrismaClient();

const img = (id: string, w = 900) => `https://images.unsplash.com/photo-${id}?w=${w}&q=80&auto=format&fit=crop`;
const PREFIX = "DEMO-";

type Demo = { code: string; name: string; cat: string; type: JewelleryType; price: number; stock: number; style: string; colour: string; photos: string[]; isNew?: boolean; description: string };

const products: Demo[] = [
  { code: "ER01", name: "Temple jhumka earrings", cat: "earrings", type: "EARRINGS", price: 2800, stock: 8, style: "Traditional", colour: "Gold", photos: ["1762686130435-897de4b26aac"], isNew: true, description: "Bell-shaped jhumkas with fine filigree and tiny hanging beads. Lightweight for all-day wear." },
  { code: "ER02", name: "Classic gold drop earrings", cat: "earrings", type: "EARRINGS", price: 3200, stock: 6, style: "Modern", colour: "Gold", photos: ["1727990865600-91f8cb8b0168"], isNew: true, description: "Simple gold-finish drops that work with office wear and sarees alike." },
  { code: "ER03", name: "Ruby kundan earrings", cat: "earrings", type: "EARRINGS", price: 3900, stock: 4, style: "Traditional", colour: "Red", photos: ["1653227907864-560dce4c252d"], isNew: true, description: "Kundan-style studs with deep red stones and a gold frame." },
  { code: "ER04", name: "Two-tone statement earrings", cat: "earrings", type: "EARRINGS", price: 2400, stock: 10, style: "Modern", colour: "Silver", photos: ["1714733831162-0a6e849141be"], description: "Silver and gold tones together for an easy everyday sparkle." },
  { code: "ER05", name: "Pearl drop earrings", cat: "earrings", type: "EARRINGS", price: 2100, stock: 12, style: "Modern", colour: "Gold", photos: ["1701777892740-88419a701472"], description: "Soft pearl drops on a slim gold hook." },
  { code: "BG01", name: "Antique bangle stack", cat: "bangles", type: "BANGLE", price: 4500, stock: 5, style: "Traditional", colour: "Gold", photos: ["1758995116383-f51775896add"], isNew: true, description: "A set of ornate gold-finish bangles to wear together or split." },
  { code: "BG02", name: "Polished gold bangle pair", cat: "bangles", type: "BANGLE", price: 3500, stock: 7, style: "Modern", colour: "Gold", photos: ["1690175867343-2af70ea57537"], description: "A smooth, high-shine pair for everyday wear." },
  { code: "BG03", name: "Textured inlay bangles", cat: "bangles", type: "BANGLE", price: 3800, stock: 3, style: "Modern", colour: "Gold", photos: ["1787769499046-8a94b2de1f62"], description: "Hammered gold bangles with dark oval inlays." },
  { code: "BR01", name: "Stone-set tennis bracelet", cat: "bracelets", type: "BRACELET", price: 5200, stock: 4, style: "Modern", colour: "Gold", photos: ["1611598935678-c88dca238fce"], isNew: true, description: "A line of sparkling stones set in gold for special occasions." },
  { code: "BR02", name: "Beaded charm bracelets", cat: "bracelets", type: "BRACELET", price: 1900, stock: 15, style: "Modern", colour: "Gold", photos: ["1626784215013-13322cb0e471"], description: "Mix-and-match beaded bracelets in gold and silver tones." },
  { code: "CH01", name: "Everyday gold chain", cat: "chains", type: "CHAIN", price: 4200, stock: 9, style: "Modern", colour: "Gold", photos: ["1611107683227-e9060eccd846"], isNew: true, description: "A fine gold-finish chain to wear alone or with a pendant." },
  { code: "CH02", name: "Heart pendant chain", cat: "chains", type: "CHAIN", price: 3600, stock: 6, style: "Modern", colour: "Gold", photos: ["1623321673989-830eff0fd59f"], description: "A delicate chain with a small gold heart charm." },
  { code: "NK01", name: "Amethyst bead necklace", cat: "necklaces", type: "NECKLACE", price: 6800, stock: 3, style: "Traditional", colour: "Purple", photos: ["1601121141461-9d6647bca1ed"], isNew: true, description: "Gold beads with purple stones in a classic collar shape." },
  { code: "NK02", name: "Ruby bead necklace", cat: "necklaces", type: "NECKLACE", price: 7200, stock: 4, style: "Traditional", colour: "Red", photos: ["1600862754152-80a263dd564f"], description: "Rich red beads strung with gold spacers." },
  { code: "NK03", name: "Pearl and gold necklace", cat: "necklaces", type: "NECKLACE", price: 8500, stock: 2, style: "Traditional", colour: "Gold", photos: ["1721103418312-b0057a8c31c2"], description: "Layers of pearls framed in gold for weddings and festivals." },
  { code: "NK04", name: "Gold bead collar necklace", cat: "necklaces", type: "NECKLACE", price: 5900, stock: 5, style: "Modern", colour: "Gold", photos: ["1599475211349-f4c81b3216bc"], description: "Rounded gold and white beads in a short collar length." },
  { code: "LC01", name: "Long layered chain", cat: "long-chains", type: "LONG_CHAIN", price: 7500, stock: 4, style: "Traditional", colour: "Gold", photos: ["1705326454924-f6777522b030"], description: "A long statement chain that falls to mid-chest." },
  { code: "RG01", name: "Diamond-cut cocktail ring", cat: "rings", type: "RING", price: 2600, stock: 8, style: "Modern", colour: "Gold", photos: ["1611955167811-4711904bb9f8"], description: "A bright cluster of stones on a slim gold band." },
  { code: "RG02", name: "Amethyst solitaire ring", cat: "rings", type: "RING", price: 2900, stock: 5, style: "Traditional", colour: "Purple", photos: ["1603561596973-8166e9e089d1"], description: "A single purple stone in a raised gold setting." },
  { code: "RG03", name: "Stone-studded band", cat: "rings", type: "RING", price: 2300, stock: 9, style: "Modern", colour: "Gold", photos: ["1626784213922-d9f1e050cf8f"], description: "A comfortable band set with small sparkling stones." },
  { code: "AN01", name: "Gold chain anklet", cat: "anklets", type: "ANKLET", price: 1500, stock: 12, style: "Modern", colour: "Gold", photos: ["1744722091259-ed1cf11ac97f"], description: "A fine chain anklet for everyday wear." },
  { code: "BJ01", name: "Bridal necklace and earring set", cat: "bridal-jewellery", type: "NECKLACE", price: 18500, stock: 2, style: "Traditional", colour: "Gold", photos: ["1722410180687-b05b50922362"], isNew: true, description: "A matching bridal necklace and earrings for the big day." },
  { code: "HA01", name: "Jewelled tiara", cat: "hair-accessories", type: "HAIR", price: 6500, stock: 3, style: "Traditional", colour: "Purple", photos: ["1603974372039-adc49044b6bd"], description: "A gold tiara set with purple stones for brides and special events." },
  { code: "FJ01", name: "Party jewellery trio", cat: "fancy-jewellery", type: "OTHER", price: 2200, stock: 7, style: "Modern", colour: "Gold", photos: ["1641290748359-1d944fc8359a"], description: "Three easy pieces to dress up any outfit." },
];

const categoryPhotos: Record<string, string> = {
  earrings: "1762686130435-897de4b26aac", bangles: "1758995116383-f51775896add", chains: "1611107683227-e9060eccd846",
  "long-chains": "1705326454924-f6777522b030", necklaces: "1601121141461-9d6647bca1ed", rings: "1611955167811-4711904bb9f8",
  bracelets: "1611598935678-c88dca238fce", anklets: "1744722091259-ed1cf11ac97f", "bridal-jewellery": "1722410180687-b05b50922362",
  "hair-accessories": "1603974372039-adc49044b6bd", "fancy-jewellery": "1641290748359-1d944fc8359a",
};

const models = [
  { name: "Demo model 1", photo: "1763578590148-fbac0711f3b2" },
  { name: "Demo model 2", photo: "1779475546066-742c9a580de1" },
  { name: "Demo model 3", photo: "1688382654723-a7366006519b" },
  { name: "Demo model 4", photo: "1620656798579-1984d9e87df7" },
];

const slugify = (s: string) => s.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");

async function add() {
  let added = 0, skipped = 0;
  for (const p of products) {
    const cat = await db.category.findUnique({ where: { slug: p.cat } });
    if (!cat) { console.warn(`Skipped ${p.name}: category "${p.cat}" not found. Run npm run seed first.`); skipped++; continue; }
    const code = PREFIX + p.code;
    const data = {
      name: p.name, description: p.description, price: p.price, stock: p.stock, style: p.style, colour: p.colour,
      jewelleryType: p.type, categoryId: cat.id, isActive: true, isNewArrival: !!p.isNew, tryOnEnabled: true,
    };
    const product = await db.product.upsert({ where: { code }, update: data, create: { ...data, code, slug: `${slugify(p.name)}-${slugify(code)}` } });
    await db.productImage.deleteMany({ where: { productId: product.id } });
    await db.productImage.createMany({ data: p.photos.map((id, i) => ({ productId: product.id, url: img(id), sort: i })) });
    added++;
  }

  for (const [slug, photo] of Object.entries(categoryPhotos)) {
    await db.category.updateMany({ where: { slug, imageUrl: null }, data: { imageUrl: img(photo, 300) } });
  }

  for (const m of models) {
    const existing = await db.aiModel.findFirst({ where: { name: m.name } });
    if (existing) await db.aiModel.update({ where: { id: existing.id }, data: { imageUrl: img(m.photo, 800), isActive: true } });
    else await db.aiModel.create({ data: { name: m.name, imageUrl: img(m.photo, 800) } });
  }

  const bangles = await db.category.findUnique({ where: { slug: "bangles" } });
  if (bangles && !(await db.offer.findFirst({ where: { title: "Demo offer: bangles week" } }))) {
    const now = new Date();
    await db.offer.create({ data: { title: "Demo offer: bangles week", percentOff: 15, startsAt: now, endsAt: new Date(now.getTime() + 14 * 864e5), categoryId: bangles.id } });
  }

  console.log(`Demo content ready: ${added} products${skipped ? ` (${skipped} skipped)` : ""}, ${models.length} AI models, category photos and one offer.`);
  console.log("Remove it later with: npm run seed:demo -- --remove");
}

async function remove() {
  const demo = await db.product.findMany({ where: { code: { startsWith: PREFIX } }, select: { id: true, _count: { select: { orderItems: true, tryOnItems: true } } } });
  let deleted = 0, hidden = 0;
  for (const p of demo) {
    await db.cartItem.deleteMany({ where: { productId: p.id } });
    await db.wishlistItem.deleteMany({ where: { productId: p.id } });
    if (p._count.orderItems || p._count.tryOnItems) {
      // Keep products that appear in orders or try-ons so history stays intact; just hide them.
      await db.product.update({ where: { id: p.id }, data: { isActive: false } });
      hidden++;
    } else {
      await db.offer.deleteMany({ where: { productId: p.id } });
      await db.product.delete({ where: { id: p.id } });
      deleted++;
    }
  }
  const demoCatUrls = Object.values(categoryPhotos).map((id) => img(id, 300));
  await db.category.updateMany({ where: { imageUrl: { in: demoCatUrls } }, data: { imageUrl: null } });
  for (const m of models) {
    const existing = await db.aiModel.findFirst({ where: { name: m.name }, include: { _count: { select: { tryOns: true } } } });
    if (!existing) continue;
    if (existing._count.tryOns) await db.aiModel.update({ where: { id: existing.id }, data: { isActive: false } });
    else await db.aiModel.delete({ where: { id: existing.id } });
  }
  await db.offer.deleteMany({ where: { title: "Demo offer: bangles week" } });
  console.log(`Demo content removed: ${deleted} products deleted, ${hidden} hidden because they appear in orders or try-ons.`);
}

(process.argv.includes("--remove") ? remove() : add())
  .catch((e) => { console.error("Demo seed failed:", e); process.exit(1); })
  .finally(() => db.$disconnect());
'@

Write-ProjectFile 'backend\package.json' @'
{
  "name": "jewellery-backend",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "seed": "tsx prisma/seed.ts",
    "seed:demo": "tsx prisma/seed-demo.ts"
  },
  "dependencies": {
    "@prisma/client": "^5.20.0",
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.21.0",
    "jsonwebtoken": "^9.0.2",
    "multer": "^1.4.5-lts.1",
    "zod": "^3.23.8"
  },
  "devDependencies": {
    "@types/bcryptjs": "^2.4.6",
    "@types/cors": "^2.8.17",
    "@types/express": "^4.17.21",
    "@types/jsonwebtoken": "^9.0.7",
    "@types/multer": "^1.4.12",
    "@types/node": "^22.7.0",
    "prisma": "^5.20.0",
    "tsx": "^4.19.0",
    "typescript": "^5.6.0"
  }
}
'@

$old = Join-Path $here 'frontend\src\components\JewelIcon.tsx'
if (Test-Path $old) { Remove-Item $old -Force }
Write-Host 'Done. 56 files updated.'
Write-Host 'Next: cd frontend; npm install; npm run dev   (and restart the backend)'
