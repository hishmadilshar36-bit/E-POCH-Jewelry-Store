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
