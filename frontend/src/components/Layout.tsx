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
              <Link to="/login" state={{ from: loc.pathname + loc.search }} className="header-signin">Sign in</Link>
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
            <span className="brand brand-light">{s.shopName}</span>
            <p>{s.tagline}</p>
          </div>
          <div className="footer-col">
            <h2>Shop</h2>
            <Link to="/shop">All jewellery</Link>
            <Link to="/shop?newArrivals=1">New arrivals</Link>
            <Link to="/shop?onSale=1">Offers</Link>
            <Link to="/build-look">Create your look</Link>
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
        <div className="footer-base">© {new Date().getFullYear()} {s.shopName}</div>
      </footer>
    </div>
  );
}
