import { FormEvent, useState } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "../api/client";
import { useCart } from "../context/CartContext";
import { lkr } from "../components/ProductCard";
import { DELIVERY_FEE } from "./Cart";

export default function Checkout() {
  const nav = useNavigate();
  const { cart, refresh } = useCart();
  const [delivery, setDelivery] = useState<"DELIVERY" | "PICKUP">("DELIVERY");
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  const submit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setBusy(true); setErr("");
    const body = Object.fromEntries(new FormData(e.currentTarget));
    try {
      const order = await api.placeOrder(body);
      await refresh();
      nav(`/order/${order.orderNo}`, { state: order });
    } catch (e) { setErr((e as Error).message); } finally { setBusy(false); }
  };

  const fee = delivery === "DELIVERY" ? DELIVERY_FEE : 0;
  return (
    <form onSubmit={submit}>
      <h1>Checkout</h1>
      <h2>Your details</h2>
      <label>Full name *<input name="fullName" required /></label>
      <label>Mobile number *<input name="mobile" required pattern="0\d{9}" placeholder="07XXXXXXXX" /></label>
      <label>WhatsApp number<input name="whatsapp" /></label>
      <label>Email<input name="email" type="email" /></label>

      <h2>Delivery</h2>
      <label className="row"><input type="radio" name="deliveryMethod" value="DELIVERY" checked={delivery === "DELIVERY"} onChange={() => setDelivery("DELIVERY")} /> Delivery</label>
      <label className="row"><input type="radio" name="deliveryMethod" value="PICKUP" checked={delivery === "PICKUP"} onChange={() => setDelivery("PICKUP")} /> Store pickup</label>
      {delivery === "DELIVERY" && (
        <>
          <label>Address *<textarea name="address" required /></label>
          <label>City *<input name="city" required /></label>
          <label>Postal code<input name="postalCode" /></label>
        </>
      )}
      <label>Order note<textarea name="note" /></label>

      <h2>Payment</h2>
      <label className="row"><input type="radio" name="paymentMethod" value="BANK_TRANSFER" defaultChecked /> Bank transfer</label>
      <label className="row"><input type="radio" name="paymentMethod" value="COD" /> Cash on delivery</label>
      <label className="row"><input type="radio" name="paymentMethod" value="ONLINE" /> Online payment</label>

      <h2>Total: {lkr((cart?.subtotal ?? 0) + fee)}</h2>
      {err && <p className="error">{err}</p>}
      <button disabled={busy || !cart?.items.length}>{busy ? "Placing order…" : "Place order"}</button>
    </form>
  );
}
