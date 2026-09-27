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
