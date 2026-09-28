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
import { OrderLines, OrderNotice, OrderTimeline } from "../components/OrderView";

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
          {o.status === "PENDING" && <OrderNotice order={o} />}
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
