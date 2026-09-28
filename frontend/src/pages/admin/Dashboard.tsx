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
