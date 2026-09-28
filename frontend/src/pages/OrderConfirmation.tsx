import { Link, useLocation, useParams } from "react-router-dom";
import type { Order } from "../api/types";
import { lkr, whatsappLink } from "../api/format";
import { useSettings } from "../context/SettingsContext";
import { useAuth } from "../context/AuthContext";
import Icon from "../components/Icon";
import { OrderLines } from "../components/OrderView";

export default function OrderConfirmation() {
  const { orderNo } = useParams();
  const order = useLocation().state as Order | undefined;
  const s = useSettings();
  const { user } = useAuth();
  const contact = s.whatsapp || s.phone;
  const msg = `Hi, about my order ${orderNo}${order ? ` (${lkr(order.total)})` : ""}.`;

  return (
    <div className="page">
      <div className="confirm">
        <section className="confirm-hero">
          <span className="confirm-icon"><Icon name="check" size={36} /></span>
          <h1>Thank you for your order</h1>
          <p className="order-no">Your order number<strong>{orderNo}</strong></p>
          <p className="muted">We'll contact you{order ? ` on ${order.mobile}` : ""} to confirm it. Keep your order number to track it.</p>
          <div className="card-actions" style={{ marginTop: 8 }}>
            <Link to={`/track?orderNo=${orderNo}${order ? `&mobile=${order.mobile}` : ""}`} className="btn btn-primary">Track order</Link>
            {contact && <a href={whatsappLink(contact, msg)} target="_blank" rel="noreferrer" className="btn btn-secondary"><Icon name="chat" size={18} />WhatsApp us</a>}
          </div>
        </section>

        {order?.paymentMethod === "BANK_TRANSFER" && (
          <section className="card" aria-labelledby="pay-title">
            <h2 id="pay-title">Complete your payment</h2>
            <p style={{ marginBottom: 12 }}>Transfer <strong>{lkr(order.total)}</strong> and use <strong>{orderNo}</strong> as the reference. Then send the slip to us on WhatsApp.</p>
            {s.bankDetails ? <div className="bank-box">{s.bankDetails}</div> : <p className="muted">We'll send you our bank details when we confirm your order.</p>}
          </section>
        )}

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
