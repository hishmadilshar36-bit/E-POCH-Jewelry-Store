import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../../api/client";
import type { Order, OrderStatus } from "../../api/types";
import { lkr } from "../../components/ProductCard";

const filters: (OrderStatus | "")[] = ["", "PENDING", "CONFIRMED", "PROCESSING", "READY", "DISPATCHED", "DELIVERED", "CANCELLED"];

export default function AdminOrders() {
  const [status, setStatus] = useState<OrderStatus | "">("PENDING");
  const [q, setQ] = useState("");
  const [orders, setOrders] = useState<Order[]>([]);
  useEffect(() => { api.admin.orders({ status, q }).then((r) => setOrders(r.items)); }, [status, q]);

  return (
    <section>
      <h1>Orders</h1>
      <div className="row">
        {filters.map((f) => <button key={f} className={status === f ? "" : "ghost"} onClick={() => setStatus(f)}>{f ? f.toLowerCase() : "all"}</button>)}
        <input placeholder="Order no, name or mobile" onKeyDown={(e) => e.key === "Enter" && setQ(e.currentTarget.value)} />
      </div>
      <table>
        <thead><tr><th>Order</th><th>Customer</th><th>Total</th><th>Status</th><th>Date</th></tr></thead>
        <tbody>
          {orders.map((o) => (
            <tr key={o.id}>
              <td><Link to={`/admin/orders/${o.id}`}>#{o.orderNo}</Link></td>
              <td>{o.fullName}</td><td>{lkr(o.total)}</td><td>{o.status.toLowerCase()}</td>
              <td>{new Date(o.createdAt).toLocaleString()}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </section>
  );
}
