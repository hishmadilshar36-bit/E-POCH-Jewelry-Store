import { FormEvent, useState } from "react";
import { api } from "../../api/client";
import { useReloadSettings, useSettings } from "../../context/SettingsContext";
import { useToast } from "../../context/ToastContext";
import { Switch } from "../../components/ui";

export default function SettingsPage() {
  const s = useSettings();
  const reload = useReloadSettings();
  const { show } = useToast();
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  const save = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    const text = (k: string) => String(f.get(k) ?? "").trim();
    const body = {
      shopName: text("shopName"), tagline: text("tagline"), phone: text("phone"), whatsapp: text("whatsapp"),
      email: text("email"), address: text("address"), bankDetails: text("bankDetails"),
      deliveryFee: Number(f.get("deliveryFee") || 0),
      freeDeliveryOver: f.get("freeDeliveryOver") ? Number(f.get("freeDeliveryOver")) : null,
      codEnabled: !!f.get("codEnabled"), bankEnabled: !!f.get("bankEnabled"), onlineEnabled: !!f.get("onlineEnabled"), pickupEnabled: !!f.get("pickupEnabled"),
    };
    if (!body.codEnabled && !body.bankEnabled && !body.onlineEnabled) { setErr("Turn on at least one payment method so customers can order."); return; }
    setBusy(true); setErr("");
    try { await api.admin.saveSettings(body); await reload(); show("Settings saved"); }
    catch (e) { setErr((e as Error).message); } finally { setBusy(false); }
  };

  return (
    <form className="admin-page" onSubmit={save} key={s.shopName + s.phone}>
      <div className="admin-head"><div><h1>Settings</h1><p>These details appear across the shop, at checkout and in messages to customers.</p></div></div>
      {err && <p className="form-error" role="alert">{err}</p>}

      <div className="admin-form">
        <div className="admin-form-main">
          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>Shop</h2>
            <div className="form-grid">
              <label className="field"><span className="field-label">Shop name</span><input name="shopName" required maxLength={80} defaultValue={s.shopName} /></label>
              <label className="field"><span className="field-label">Tagline</span><input name="tagline" maxLength={200} defaultValue={s.tagline} /></label>
              <label className="field span-2"><span className="field-label">Address</span><textarea name="address" rows={2} maxLength={300} defaultValue={s.address} /><span className="field-hint">Shown for store pickup and on the contact page</span></label>
            </div>
          </section>
          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>Contact</h2>
            <div className="form-grid">
              <label className="field"><span className="field-label">Phone</span><input name="phone" type="tel" maxLength={30} defaultValue={s.phone} placeholder="0XX XXX XXXX" /></label>
              <label className="field"><span className="field-label">WhatsApp</span><input name="whatsapp" type="tel" maxLength={30} defaultValue={s.whatsapp} placeholder="07XXXXXXXX" /><span className="field-hint">Used for WhatsApp buttons and new-order alerts</span></label>
              <label className="field span-2"><span className="field-label">Email</span><input name="email" type="email" maxLength={120} defaultValue={s.email} /></label>
            </div>
          </section>
          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>Payment</h2>
            <Switch name="codEnabled" label="Cash on delivery" defaultChecked={s.codEnabled} />
            <Switch name="bankEnabled" label="Bank transfer" defaultChecked={s.bankEnabled} />
            <label className="field"><span className="field-label">Bank details</span><textarea name="bankDetails" rows={4} maxLength={1000} defaultValue={s.bankDetails} placeholder={"Bank: \nBranch: \nAccount name: \nAccount number: "} /><span className="field-hint">Shown to customers who choose bank transfer</span></label>
            <Switch name="onlineEnabled" label="Online card payment" hint="Needs a payment gateway such as PayHere to be connected first" defaultChecked={s.onlineEnabled} />
          </section>
        </div>
        <div className="admin-form-side">
          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>Delivery</h2>
            <label className="field"><span className="field-label">Delivery fee (LKR)</span><input name="deliveryFee" type="number" min={0} step={1} required defaultValue={s.deliveryFee} /></label>
            <label className="field"><span className="field-label">Free delivery over (LKR) <span className="optional">(optional)</span></span><input name="freeDeliveryOver" type="number" min={0} step={1} defaultValue={s.freeDeliveryOver ?? ""} /><span className="field-hint">Leave empty to always charge</span></label>
            <Switch name="pickupEnabled" label="Store pickup" hint="Free for the customer" defaultChecked={s.pickupEnabled} />
          </section>
        </div>
      </div>

      <div className="save-bar"><button className="btn btn-primary" disabled={busy}>{busy ? "Saving…" : "Save settings"}</button></div>
    </form>
  );
}
