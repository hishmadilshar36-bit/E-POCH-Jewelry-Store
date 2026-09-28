import { Link } from "react-router-dom";
import type { Order, OrderStatus } from "../api/types";
import { customerStatus, dateTime, deliveryLabel, lkr, paymentLabel } from "../api/format";
import Icon from "./Icon";
import { ProductImage } from "./ui";

const flowDelivery: OrderStatus[] = ["PENDING", "CONFIRMED", "PROCESSING", "DISPATCHED", "DELIVERED"];
const flowPickup: OrderStatus[] = ["PENDING", "CONFIRMED", "PROCESSING", "READY", "DELIVERED"];

export function OrderTimeline({ order }: { order: Order }) {
  const history = order.history ?? [];
  const when = (s: OrderStatus) => history.find((h) => h.status === s)?.createdAt;

  if (order.status === "CANCELLED") {
    return (
      <ol className="timeline">
        <li className="tl-step is-done"><span className="tl-dot"><Icon name="check" size={16} /></span><span className="tl-text"><strong>Order received</strong>{when("PENDING") && <span>{dateTime(when("PENDING")!)}</span>}</span></li>
        <li className="tl-step is-current"><span className="tl-dot" /><span className="tl-text"><strong>Cancelled</strong>{when("CANCELLED") && <span>{dateTime(when("CANCELLED")!)}</span>}</span></li>
      </ol>
    );
  }

  const flow = order.deliveryMethod === "PICKUP" ? flowPickup : flowDelivery;
  const reached = history.map((h) => h.status);
  // READY can happen on delivery orders too; place the current step at the furthest reached point.
  const currentIndex = Math.max(flow.indexOf(order.status), ...reached.map((s) => flow.indexOf(s)));
  const labels: Partial<Record<OrderStatus, string>> = order.deliveryMethod === "PICKUP" ? { READY: "Ready to collect", DELIVERED: "Collected" } : {};

  return (
    <ol className="timeline">
      {flow.map((s, i) => {
        const state = i < currentIndex || (i === currentIndex && s === "DELIVERED") ? "is-done" : i === currentIndex ? "is-current" : "";
        return (
          <li key={s} className={`tl-step ${state}`} aria-current={state === "is-current" ? "step" : undefined}>
            <span className="tl-dot">{state === "is-done" && <Icon name="check" size={16} />}</span>
            <span className="tl-text"><strong>{labels[s] ?? customerStatus[s]}</strong>{when(s) && <span>{dateTime(when(s)!)}</span>}</span>
          </li>
        );
      })}
    </ol>
  );
}

export function OrderLines({ order }: { order: Order }) {
  return (
    <>
      <div className="order-lines">
        {order.items.map((i) => (
          <div key={i.id} className="order-line">
            <span className="order-line-img"><ProductImage url={i.product?.images[0]?.url} alt="" /></span>
            <span>{i.product?.slug ? <Link to={`/product/${i.product.slug}`}>{i.name}</Link> : i.name} <span className="muted">× {i.qty}</span></span>
            <span className="num">{lkr(i.price * i.qty)}</span>
          </div>
        ))}
      </div>
      <div className="order-totals">
        <div className="summary-row"><span>Subtotal</span><span>{lkr(order.subtotal)}</span></div>
        <div className="summary-row"><span>{deliveryLabel[order.deliveryMethod]}</span><span>{order.deliveryFee ? lkr(order.deliveryFee) : "Free"}</span></div>
        <div className="summary-row summary-total"><span>Total</span><span>{lkr(order.total)}</span></div>
        <div className="summary-row muted"><span>Payment</span><span>{paymentLabel[order.paymentMethod]}</span></div>
      </div>
    </>
  );
}
