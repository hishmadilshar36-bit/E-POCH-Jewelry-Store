import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import { api } from "../../api/client";
import type { Order, OrderStatus } from "../../api/types";
import { lkr } from "../../components/ProductCard";

const next: Record<OrderStatus, { to: OrderStatus; label: string }[]> = {
  PENDING: [{ to: "CONFIRMED", label: "Confirm order" }, { to: "CANCELLED", label: "Cancel order" }],
  CONFIRMED: [{ to: "PROCESSING", label: "Start processing" }, { to: "CANCELLED", label: "Cancel order" }],
  PROCESSING: [{ to: "READY", label: "Mark ready" }, { to: "CANCELLED", label: "Cancel order" }],
  READY: [{ to: "DISPATCHED", label: "Mark dispatched" }, { to: "DELIVERED", label: "Mark picked up" }],
  DISPATCHED: [{ to: "DELIVERED", label: "Mark delivered" }],
  DELIVERED: [], CANCELLED: [],
};

export default function AdminOrderDetail() {
  const { id } = useParams();
  const [o, setO] = useState<Order | null>(null);
  const [err, setErr] = useState("");
  const load = () => api.admin.order(id!).then(setO);
  useEffect(() => { load(); }, [id]);
  if (!o) return <p>Loading…</p>;

  const move = async (to: OrderStatus) => {
    if (to === "CANCELLED" && !confirm("Cancel this order? Stock will be returned.")) return;
    try { setErr(""); await api.admin.setStatus(o.id, to); await load(); } catch (e) { setErr((e as Error).message); }
  };

  return (
    <section>
      <h1>#{o.orderNo}</h1>
      <p><strong>{o.fullName}</strong> · <a href={`tel:${o.mobile}`}>{o.mobile}</a></p>
      <table><tbody>{o.items.map((i) => <tr key={i.id}><td>{i.name}</td><td>× {i.qty}</td><td>{lkr(i.price * i.qty)}</td></tr>)}</tbody></table>
      <p>Subtotal {lkr(o.subtotal)} + delivery {lkr(o.deliveryFee)} = <strong>{lkr(o.total)}</strong></p>
      <p>Payment: {o.paymentMethod.replace("_", " ").toLowerCase()} ({o.paymentStatus.toLowerCase()})</p>
      <p>Delivery: {o.deliveryMethod === "PICKUP" ? "store pickup" : o.city}</p>
      <p>Status: <strong>{o.status.toLowerCase()}</strong></p>
      <div className="row">{next[o.status].map((n) => <button key={n.to} className={n.to === "CANCELLED" ? "ghost" : ""} onClick={() => move(n.to)}>{n.label}</button>)}</div>
      {err && <p className="error">{err}</p>}
    </section>
  );
}
