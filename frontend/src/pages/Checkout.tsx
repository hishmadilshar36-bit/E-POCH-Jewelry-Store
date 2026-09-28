import { FormEvent, useEffect, useState } from "react";
import { Link, Navigate, useNavigate } from "react-router-dom";
import { api, ApiError } from "../api/client";
import type { DeliveryMethod, PaymentMethod } from "../api/types";
import { lkr, paymentLabel } from "../api/format";
import { useCart } from "../context/CartContext";
import { useAuth } from "../context/AuthContext";
import { useSettings } from "../context/SettingsContext";
import Icon, { IconName } from "../components/Icon";
import { PageLoading, ProductImage } from "../components/ui";
import { FreeDeliveryBar } from "./Cart";

const paymentInfo: Record<PaymentMethod, { icon: IconName; note: string }> = {
  COD: { icon: "cash", note: "Pay in cash when your order arrives." },
  BANK_TRANSFER: { icon: "bank", note: "Transfer the total and send us the slip on WhatsApp." },
  ONLINE: { icon: "card", note: "Pay securely by card." },
};

export default function Checkout() {
  const nav = useNavigate();
  const { cart, refresh } = useCart();
  const { user } = useAuth();
  const s = useSettings();
  const methods = (["COD", "BANK_TRANSFER", "ONLINE"] as PaymentMethod[]).filter((m) => ({ COD: s.codEnabled, BANK_TRANSFER: s.bankEnabled, ONLINE: s.onlineEnabled })[m]);
  const [delivery, setDelivery] = useState<DeliveryMethod>("DELIVERY");
  const [payment, setPayment] = useState<PaymentMethod | "">("");
  const [err, setErr] = useState("");
  const [badField, setBadField] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => { if (!payment && methods.length) setPayment(methods[0]); }, [methods, payment]);

  if (!cart) return <PageLoading />;
  if (!cart.items.length && !busy) return <Navigate to="/cart" replace />;

  const fee = delivery === "DELIVERY" ? cart.deliveryFee : 0;
  const total = cart.subtotal + fee;

  const submit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setErr(""); setBadField("");
    const body = Object.fromEntries(new FormData(e.currentTarget));
    setBusy(true);
    try {
      const order = await api.placeOrder(body);
      await refresh();
      nav(`/order/${order.orderNo}`, { state: order, replace: true });
    } catch (e) {
      setBusy(false);
      setErr((e as Error).message);
      if (e instanceof ApiError && e.field) {
        setBadField(e.field);
        document.querySelector<HTMLInputElement>(`[name="${e.field}"]`)?.focus();
      } else window.scrollTo({ top: 0, behavior: "smooth" });
    }
  };
  const invalid = (name: string) => (badField === name ? { "aria-invalid": true as const } : {});

  return (
    <div className="page">
      <div className="page-head"><h1>Checkout</h1><p>{user ? `Signed in as ${user.email}` : <>Checking out as a guest. <Link to="/login" state={{ from: "/checkout" }}>Sign in</Link> to track orders in your account.</>}</p></div>
      <form className="cart" onSubmit={submit} noValidate={false}>
        <div className="checkout-sections">
          {err && <p className="form-error" role="alert">{err}</p>}

          <section className="checkout-section" aria-labelledby="co-details">
            <h2 id="co-details"><span className="checkout-num">1</span>Your details</h2>
            <div className="form-grid">
              <label className="field span-2"><span className="field-label">Full name</span><input name="fullName" required minLength={2} autoComplete="name" defaultValue={user?.name ?? ""} {...invalid("fullName")} /></label>
              <label className="field"><span className="field-label">Mobile number</span><input name="mobile" type="tel" required pattern="0\d{9}" placeholder="07XXXXXXXX" autoComplete="tel" inputMode="tel" defaultValue={user?.phone ?? ""} {...invalid("mobile")} /><span className="field-hint">We'll call or message about your order</span></label>
              <label className="field"><span className="field-label">WhatsApp number <span className="optional">(optional)</span></span><input name="whatsapp" type="tel" placeholder="If different from mobile" inputMode="tel" /></label>
              <label className="field span-2"><span className="field-label">Email <span className="optional">(optional)</span></span><input name="email" type="email" autoComplete="email" defaultValue={user?.email ?? ""} {...invalid("email")} /></label>
            </div>
          </section>

          <section className="checkout-section" aria-labelledby="co-delivery">
            <h2 id="co-delivery"><span className="checkout-num">2</span>Delivery</h2>
            <fieldset className="fieldset">
              <legend className="sr-only">Delivery method</legend>
              <div className="choices choices-2">
                <label className="choice">
                  <input type="radio" name="deliveryMethod" value="DELIVERY" checked={delivery === "DELIVERY"} onChange={() => setDelivery("DELIVERY")} />
                  <span className="choice-dot" aria-hidden="true" />
                  <span className="choice-body"><span className="choice-title"><Icon name="truck" size={18} />Deliver to me</span><span className="choice-note">{cart.deliveryFee ? lkr(cart.deliveryFee) : "Free"} · islandwide</span></span>
                </label>
                {s.pickupEnabled && (
                  <label className="choice">
                    <input type="radio" name="deliveryMethod" value="PICKUP" checked={delivery === "PICKUP"} onChange={() => setDelivery("PICKUP")} />
                    <span className="choice-dot" aria-hidden="true" />
                    <span className="choice-body"><span className="choice-title"><Icon name="store" size={18} />Store pickup</span><span className="choice-note">Free{s.address ? ` · ${s.address}` : ""}</span></span>
                  </label>
                )}
              </div>
            </fieldset>
            {delivery === "DELIVERY" && (
              <div className="form-grid">
                <label className="field span-2"><span className="field-label">Address</span><textarea name="address" required rows={2} autoComplete="street-address" {...invalid("address")} /></label>
                <label className="field"><span className="field-label">City</span><input name="city" required autoComplete="address-level2" {...invalid("city")} /></label>
                <label className="field"><span className="field-label">Postal code <span className="optional">(optional)</span></span><input name="postalCode" autoComplete="postal-code" inputMode="numeric" /></label>
              </div>
            )}
            <label className="field"><span className="field-label">Order note <span className="optional">(optional)</span></span><textarea name="note" rows={2} placeholder="Gift wrapping, a delivery time, anything we should know" /></label>
          </section>

          <section className="checkout-section" aria-labelledby="co-payment">
            <h2 id="co-payment"><span className="checkout-num">3</span>Payment</h2>
            {methods.length ? (
              <fieldset className="fieldset">
                <legend className="sr-only">Payment method</legend>
                <div className="choices">
                  {methods.map((m) => (
                    <label key={m} className="choice">
                      <input type="radio" name="paymentMethod" value={m} checked={payment === m} onChange={() => setPayment(m)} required />
                      <span className="choice-dot" aria-hidden="true" />
                      <span className="choice-body"><span className="choice-title"><Icon name={paymentInfo[m].icon} size={18} />{paymentLabel[m]}</span><span className="choice-note">{paymentInfo[m].note}</span></span>
                    </label>
                  ))}
                </div>
              </fieldset>
            ) : <p className="form-error">No payment methods are available right now. Contact the shop to order.</p>}
            {payment === "BANK_TRANSFER" && s.bankDetails && <div className="bank-box"><strong>Bank details</strong>{"\n"}{s.bankDetails}</div>}
          </section>
        </div>

        <aside className="summary" aria-label="Order summary">
          <h2>Your order</h2>
          <div className="summary-items">
            {cart.items.map((i) => (
              <div key={i.id} className="summary-item">
                <span className="summary-item-img"><ProductImage url={i.product.images[0]?.url} alt="" type={i.product.jewelleryType} /><span className="summary-item-qty" aria-label={`Quantity ${i.qty}`}>{i.qty}</span></span>
                <span>{i.product.name}</span>
                <span className="num">{lkr(i.lineTotal)}</span>
              </div>
            ))}
          </div>
          <div className="summary-row"><span>Subtotal</span><span>{lkr(cart.subtotal)}</span></div>
          <div className="summary-row"><span>Delivery</span><span>{fee ? lkr(fee) : "Free"}</span></div>
          {delivery === "DELIVERY" && <FreeDeliveryBar subtotal={cart.subtotal} over={cart.freeDeliveryOver} />}
          <div className="summary-row summary-total"><span>Total</span><span>{lkr(total)}</span></div>
          <button className="btn btn-primary btn-lg btn-block" disabled={busy || !methods.length}>{busy ? "Placing order…" : `Place order · ${lkr(total)}`}</button>
          <p className="summary-note">We'll confirm your order by phone or WhatsApp before it's sent.</p>
        </aside>
      </form>
    </div>
  );
}
