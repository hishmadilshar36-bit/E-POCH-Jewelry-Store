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
