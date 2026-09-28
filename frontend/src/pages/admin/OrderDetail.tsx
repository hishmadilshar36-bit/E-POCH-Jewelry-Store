import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { api } from "../../api/client";
import type { Order, OrderStatus, PaymentStatus } from "../../api/types";
import { dateTime, deliveryLabel, lkr, paymentLabel, paymentStatusLabel, phoneLink, statusLabel, whatsappLink } from "../../api/format";
import { useSettings } from "../../context/SettingsContext";
import { useToast } from "../../context/ToastContext";
import Icon from "../../components/Icon";
import { ConfirmDialog, ErrorState, PageLoading, ProductImage, StatusPill } from "../../components/ui";

const actionLabel: Record<OrderStatus, string> = {
  PENDING: "Pending", CONFIRMED: "Confirm order", PROCESSING: "Start processing", READY: "Mark ready",
  DISPATCHED: "Mark dispatched", DELIVERED: "Mark delivered", CANCELLED: "Cancel order",
};

export default function AdminOrderDetail() {
  const { id } = useParams();
  const s = useSettings();
  const { show } = useToast();
  const [o, setO] = useState<Order | null>(null);
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);
  const [cancelling, setCancelling] = useState(false);

  const load = () => { setErr(""); api.admin.order(id!).then(setO).catch((e) => setErr((e as Error).message)); };
  useEffect(load, [id]); // eslint-disable-line react-hooks/exhaustive-deps

  if (err && !o) return <ErrorState message={err} onRetry={load} />;
  if (!o) return <PageLoading />;

  const move = async (to: OrderStatus) => {
    setBusy(true);
    try { await api.admin.setStatus(o.id, to); show(`Order ${statusLabel[to].toLowerCase()}`); setCancelling(false); load(); }
    catch (e) { show((e as Error).message, { kind: "error" }); }
    finally { setBusy(false); }
  };
  const pay = async (ps: PaymentStatus) => {
    try { await api.admin.setPayment(o.id, ps); show(`Payment marked ${paymentStatusLabel[ps].toLowerCase()}`); load(); }
    catch (e) { show((e as Error).message, { kind: "error" }); }
  };

  const actions = (o.nextStatuses ?? []).filter((st) => st !== "CANCELLED");
  const labelFor = (st: OrderStatus) => (st === "DELIVERED" && o.deliveryMethod === "PICKUP" ? "Mark collected" : actionLabel[st]);
  const canCancel = o.nextStatuses?.includes("CANCELLED");
  const msg = `Hi ${o.fullName.split(" ")[0]}, this is ${s.shopName.replace(/^\[|\]$/g, "")} about your order ${o.orderNo}.`;
  const history = o.history ?? [];

  return (
    <div className="admin-page">
      <div className="admin-head">
        <div>
          <Link to="/admin/orders" className="back-link no-print"><Icon name="arrowLeft" size={16} />Orders</Link>
          <h1 style={{ display: "flex", gap: 14, alignItems: "center", flexWrap: "wrap" }}>{o.orderNo} <StatusPill status={o.status} /></h1>
          <p>Placed {dateTime(o.createdAt)}</p>
        </div>
        <div className="admin-head-actions no-print">
          <button className="btn btn-quiet" onClick={() => window.print()}><Icon name="print" size={18} />Print packing slip</button>
        </div>
      </div>

      <div className="print-only"><strong>{s.shopName}</strong>{s.phone && ` · ${s.phone}`}{s.address && ` · ${s.address}`}</div>

      <div className="detail-grid">
        <div className="stack">
          <section className="panel">
            <div className="panel-head"><h2>Items</h2><span className="panel-meta">{o.items.reduce((n, i) => n + i.qty, 0)} pieces</span></div>
            <div className="order-lines">
              {o.items.map((i) => (
                <div key={i.id} className="order-line">
                  <span className="order-line-img"><ProductImage url={i.product?.images[0]?.url} alt="" /></span>
                  <span>
                    <strong>{i.name}</strong> <span className="muted">× {i.qty}</span>
                    <span className="muted" style={{ display: "block", fontSize: 13 }}>{i.product?.code ? `Code ${i.product.code} · ` : ""}{lkr(i.price)} each</span>
                  </span>
                  <span className="num">{lkr(i.price * i.qty)}</span>
                </div>
              ))}
            </div>
            <div className="order-totals">
              <div className="summary-row"><span>Subtotal</span><span>{lkr(o.subtotal)}</span></div>
              <div className="summary-row"><span>{deliveryLabel[o.deliveryMethod]}</span><span>{o.deliveryFee ? lkr(o.deliveryFee) : "Free"}</span></div>
              <div className="summary-row summary-total"><span>Total</span><span>{lkr(o.total)}</span></div>
            </div>
          </section>

          {o.note && (
            <section className="panel"><h2 style={{ fontSize: 22, marginBottom: 10 }}>Customer note</h2><p style={{ whiteSpace: "pre-line" }}>{o.note}</p></section>
          )}

          <section className="panel no-print">
            <h2 style={{ fontSize: 22, marginBottom: 16 }}>History</h2>
            <ol className="timeline">
              {history.map((h, i) => (
                <li key={h.id} className={`tl-step ${i === history.length - 1 ? "is-current" : "is-done"}`}>
                  <span className="tl-dot">{i < history.length - 1 && <Icon name="check" size={16} />}</span>
                  <span className="tl-text"><strong>{statusLabel[h.status]}</strong><span>{dateTime(h.createdAt)}</span></span>
                </li>
              ))}
            </ol>
          </section>
        </div>

        <div className="detail-side">
          {(actions.length > 0 || canCancel) && (
            <section className="panel no-print">
              <h2 style={{ fontSize: 22, marginBottom: 14 }}>Next step</h2>
              <div className="status-actions">
                {actions.map((st, i) => (
                  <button key={st} className={`btn ${i === 0 ? "btn-primary" : "btn-secondary"} btn-block`} disabled={busy} onClick={() => move(st)}>{labelFor(st)}</button>
                ))}
                {canCancel && <button className="btn-link" style={{ color: "var(--error)" }} onClick={() => setCancelling(true)}>Cancel order</button>}
              </div>
            </section>
          )}

          <section className="panel">
            <h2 style={{ fontSize: 22, marginBottom: 14 }}>Customer</h2>
            <dl className="kv">
              <dt>Name</dt><dd>{o.fullName}</dd>
              <dt>Mobile</dt><dd>{o.mobile}</dd>
              {o.whatsapp && <><dt>WhatsApp</dt><dd>{o.whatsapp}</dd></>}
              {o.email && <><dt>Email</dt><dd>{o.email}</dd></>}
              <dt>Account</dt><dd>{o.user ? <Link to={`/admin/customers?q=${encodeURIComponent(o.user.email)}`}>{o.user.email}</Link> : "Guest"}</dd>
            </dl>
            <div className="contact-actions no-print">
              <a href={phoneLink(o.mobile)} className="btn btn-quiet btn-sm"><Icon name="phone" size={16} />Call</a>
              <a href={whatsappLink(o.whatsapp || o.mobile, msg)} target="_blank" rel="noreferrer" className="btn btn-quiet btn-sm"><Icon name="chat" size={16} />WhatsApp</a>
            </div>
          </section>

          <section className="panel">
            <h2 style={{ fontSize: 22, marginBottom: 14 }}>Delivery</h2>
            <dl className="kv">
              <dt>Method</dt><dd>{deliveryLabel[o.deliveryMethod]}</dd>
              {o.deliveryMethod === "DELIVERY" && <><dt>Address</dt><dd style={{ whiteSpace: "pre-line" }}>{[o.address, o.city, o.postalCode].filter(Boolean).join("\n")}</dd></>}
            </dl>
          </section>

          <section className="panel">
            <h2 style={{ fontSize: 22, marginBottom: 14 }}>Payment</h2>
            <dl className="kv">
              <dt>Method</dt><dd>{paymentLabel[o.paymentMethod]}</dd>
              <dt>Status</dt><dd><span className={`pill pill-${o.paymentStatus.toLowerCase()}`}>{paymentStatusLabel[o.paymentStatus]}</span></dd>
            </dl>
            <div className="contact-actions no-print">
              {o.paymentStatus !== "PAID" && <button className="btn btn-secondary btn-sm" onClick={() => pay("PAID")}><Icon name="check" size={16} />Mark as paid</button>}
              {o.paymentStatus === "PAID" && <button className="btn btn-quiet btn-sm" onClick={() => pay("UNPAID")}>Mark as not paid</button>}
              {o.paymentStatus === "PAID" && o.status === "CANCELLED" && <button className="btn btn-quiet btn-sm" onClick={() => pay("REFUNDED")}>Mark refunded</button>}
            </div>
          </section>
        </div>
      </div>

      <ConfirmDialog open={cancelling} danger title="Cancel this order?" confirmLabel="Cancel order" busy={busy} onConfirm={() => move("CANCELLED")} onClose={() => setCancelling(false)}
        body={<>The items go back into stock and the customer is told the order is cancelled.{o.paymentStatus === "PAID" && " This order is marked as paid, so arrange a refund."}</>} />
    </div>
  );
}
