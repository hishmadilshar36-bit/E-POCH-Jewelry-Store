import { useEffect, useRef, useState } from "react";
import { Link, useLocation, useParams } from "react-router-dom";
import { api } from "../api/client";
import type { Order } from "../api/types";
import { lkr, whatsappLink } from "../api/format";
import { useSettings } from "../context/SettingsContext";
import { useAuth } from "../context/AuthContext";
import { useToast } from "../context/ToastContext";
import Icon from "../components/Icon";
import { OrderLines, OrderNotice, awaitingPayment, isConfirmed } from "../components/OrderView";

const POLL_MS = 15000;

export default function OrderConfirmation() {
  const { orderNo } = useParams();
  const placed = useLocation().state as Order | undefined;
  const s = useSettings();
  const { user } = useAuth();
  const { show } = useToast();
  const [order, setOrder] = useState<Order | undefined>(placed);
  const wasConfirmed = useRef(placed ? isConfirmed(placed) : false);

  // Keep checking while the order waits for payment or a call, so the page updates once it is confirmed.
  useEffect(() => {
    if (!orderNo || !placed?.mobile) return;
    let stop = false;
    const check = async () => {
      if (document.hidden) return;
      try {
        const fresh = await api.trackOrder(orderNo, placed.mobile);
        if (stop) return;
        setOrder(fresh);
        if (!wasConfirmed.current && isConfirmed(fresh)) {
          wasConfirmed.current = true;
          show("Your order is confirmed");
        }
      } catch { /* try again on the next tick */ }
    };
    check();
    const t = window.setInterval(check, POLL_MS);
    return () => { stop = true; window.clearInterval(t); };
  }, [orderNo, placed?.mobile, show]);

  const contact = s.whatsapp || s.phone;
  const msg = `Hi, about my order ${orderNo}${order ? ` (${lkr(order.total)})` : ""}.`;
  const confirmed = order ? isConfirmed(order) : false;
  const cancelled = order?.status === "CANCELLED";
  const waiting = order ? awaitingPayment(order) : false;

  const title = cancelled ? "Your order was cancelled" : confirmed ? "Your order is confirmed" : waiting ? "Order received, waiting for payment" : "Thank you for your order";
  const sub = cancelled
    ? "Contact us if you have any questions about this order."
    : confirmed
      ? `${order?.paymentStatus === "PAID" ? "We received your payment. " : ""}We're getting your pieces ready.`
      : waiting
        ? "Your order is confirmed as soon as we receive your payment."
        : `We'll contact you${order ? ` on ${order.mobile}` : ""} to confirm it. Keep your order number to track it.`;

  return (
    <div className="page">
      <div className="confirm">
        <section className="confirm-hero" aria-live="polite">
          <span className={`confirm-icon ${confirmed ? "" : cancelled ? "is-cancelled" : "is-waiting"}`}>
            <Icon name={confirmed ? "check" : cancelled ? "close" : "clock"} size={36} />
          </span>
          <h1>{title}</h1>
          <p className="order-no">Your order number<strong>{orderNo}</strong></p>
          <p className="muted">{sub}</p>
          <div className="card-actions" style={{ marginTop: 8 }}>
            <Link to={`/track?orderNo=${orderNo}${order ? `&mobile=${order.mobile}` : ""}`} className="btn btn-primary">Track order</Link>
            {contact && <a href={whatsappLink(contact, msg)} target="_blank" rel="noreferrer" className="btn btn-secondary"><Icon name="chat" size={18} />{waiting ? "Send payment slip" : "WhatsApp us"}</a>}
          </div>
        </section>

        {order && !cancelled && !confirmed && <OrderNotice order={order} />}

        {order && (
          <section className="card" aria-labelledby="sum-title">
            <h2 id="sum-title">Order summary</h2>
            <OrderLines order={order} />
          </section>
        )}

        <div className="card-actions">
          {user?.role === "CUSTOMER" && <Link to="/account" className="btn btn-quiet">View my orders</Link>}
          <Link to="/shop" className="btn btn-quiet">Continue shopping</Link>
        </div>
      </div>
    </div>
  );
}
