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
                      <td>{c.phone || <span className="muted">—</span>}</td>
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
              <dt>Mobile</dt><dd>{detail.phone || "—"}</dd>
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
