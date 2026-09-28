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
