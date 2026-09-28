import { FormEvent, useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { api } from "../api/client";
import type { Order } from "../api/types";
import { customerStatus, shortDate, whatsappLink } from "../api/format";
import { useSettings } from "../context/SettingsContext";
import Icon from "../components/Icon";
import { OrderLines, OrderNotice, OrderTimeline } from "../components/OrderView";

export default function TrackOrder() {
  const [sp, setSp] = useSearchParams();
  const s = useSettings();
  const [order, setOrder] = useState<Order | null>(null);
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  const lookup = async (orderNo: string, mobile: string) => {
    setBusy(true); setErr("");
    try { setOrder(await api.trackOrder(orderNo, mobile)); }
    catch (e) { setErr((e as Error).message); setOrder(null); }
    finally { setBusy(false); }
  };

  useEffect(() => {
    const o = sp.get("orderNo"), m = sp.get("mobile");
    if (o && m) lookup(o, m);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const submit = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    const orderNo = String(f.get("orderNo")).trim(), mobile = String(f.get("mobile")).trim();
    setSp({ orderNo, mobile }, { replace: true });
    lookup(orderNo, mobile);
  };

  const contact = s.whatsapp || s.phone;

  return (
    <div className="page">
      <div className="page-head"><h1>Track your order</h1><p>Enter your order number and the mobile number you used at checkout.</p></div>
      <div className="track-grid">
        <form className="card form" onSubmit={submit}>
          <label className="field"><span className="field-label">Order number</span><input name="orderNo" required placeholder="ORD-000125" defaultValue={sp.get("orderNo") ?? ""} autoCapitalize="characters" /></label>
          <label className="field"><span className="field-label">Mobile number</span><input name="mobile" type="tel" required placeholder="07XXXXXXXX" inputMode="tel" defaultValue={sp.get("mobile") ?? ""} /></label>
          {err && <p className="form-error" role="alert">{err}</p>}
          <button className="btn btn-primary btn-block" disabled={busy}>{busy ? "Checking…" : "Track order"}</button>
        </form>

        {order ? (
          <div className="stack">
            <section className="card" aria-labelledby="status-title">
              <div className="order-card-head" style={{ marginBottom: 20 }}>
                <div><h2 id="status-title" style={{ marginBottom: 4 }}>{customerStatus[order.status]}</h2><span className="muted">{order.orderNo} · placed {shortDate(order.createdAt)}</span></div>
                {contact && <a href={whatsappLink(contact, `Hi, about my order ${order.orderNo}.`)} target="_blank" rel="noreferrer" className="btn btn-quiet btn-sm"><Icon name="chat" size={16} />Ask on WhatsApp</a>}
              </div>
              <OrderNotice order={order} />
              <OrderTimeline order={order} />
            </section>
            <section className="card" aria-labelledby="items-title">
              <h2 id="items-title">Items</h2>
              <OrderLines order={order} />
            </section>
          </div>
        ) : (
          <div className="card" style={{ display: "flex", gap: 16, alignItems: "center" }}>
            <span className="empty-icon" style={{ flexShrink: 0 }}><Icon name="truck" size={26} /></span>
            <p className="muted">Your order number is on the confirmation page and in the message we sent you. It looks like ORD-000125.</p>
          </div>
        )}
      </div>
    </div>
  );
}
