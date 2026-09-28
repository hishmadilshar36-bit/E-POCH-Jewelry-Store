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
