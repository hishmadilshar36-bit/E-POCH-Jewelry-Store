import { FormEvent, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { api } from "../api/client";
import type { Order } from "../api/types";
import { lkr } from "../components/ProductCard";

const stages = ["PENDING", "CONFIRMED", "PROCESSING", "READY", "DISPATCHED", "DELIVERED"];

export default function TrackOrder() {
  const [sp] = useSearchParams();
  const [order, setOrder] = useState<Order | null>(null);
  const [err, setErr] = useState("");

  const submit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    try { setErr(""); setOrder(await api.trackOrder(String(f.get("orderNo")), String(f.get("mobile")))); }
    catch (e) { setErr((e as Error).message); setOrder(null); }
  };

  return (
    <section>
      <h1>Track your order</h1>
      <form onSubmit={submit}>
        <label>Order number<input name="orderNo" defaultValue={sp.get("orderNo") ?? ""} required /></label>
        <label>Mobile number<input name="mobile" required /></label>
        <button>Track order</button>
      </form>
      {err && <p className="error">{err}</p>}
      {order && (
        <>
          <h2>#{order.orderNo} — {lkr(order.total)}</h2>
          {order.status === "CANCELLED" ? <p>This order was cancelled.</p> : (
            <ol>{stages.map((s) => <li key={s} style={{ fontWeight: s === order.status ? 700 : 400 }}>{s.toLowerCase()}</li>)}</ol>
          )}
        </>
      )}
    </section>
  );
}
