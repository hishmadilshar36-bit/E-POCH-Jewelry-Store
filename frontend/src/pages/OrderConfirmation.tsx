import { Link, useLocation, useParams } from "react-router-dom";
import type { Order } from "../api/types";
import { lkr } from "../components/ProductCard";

const SHOP_WHATSAPP = "94770000000";

export default function OrderConfirmation() {
  const { orderNo } = useParams();
  const order = useLocation().state as Order | undefined;
  return (
    <section>
      <h1>Order placed</h1>
      <p>Thank you for your order. Your order number is <strong>#{orderNo}</strong>.</p>
      {order && (
        <>
          <ul>{order.items.map((i) => <li key={i.id}>{i.name} × {i.qty}</li>)}</ul>
          <p>Total: {lkr(order.total)}</p>
        </>
      )}
      <div className="row">
        <Link to={`/track?orderNo=${orderNo}`}><button>Track order</button></Link>
        <a href={`https://wa.me/${SHOP_WHATSAPP}?text=${encodeURIComponent(`Hi, about my order #${orderNo}`)}`} target="_blank" rel="noreferrer">
          <button className="ghost">Contact via WhatsApp</button>
        </a>
      </div>
    </section>
  );
}
