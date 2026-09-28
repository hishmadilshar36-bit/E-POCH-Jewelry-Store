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
