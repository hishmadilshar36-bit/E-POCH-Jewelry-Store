import { FormEvent, useEffect, useState } from "react";
import { api } from "../../api/client";
import type { Category, Offer, Product } from "../../api/types";
import { shortDate } from "../../api/format";
import { useToast } from "../../context/ToastContext";
import Icon from "../../components/Icon";
import { ConfirmDialog, EmptyState, ErrorState, Modal, PageLoading, Switch } from "../../components/ui";

type Scope = "shop" | "category" | "product";
const toInput = (iso?: string) => (iso ? new Date(iso).toISOString().slice(0, 10) : "");
const today = () => new Date().toISOString().slice(0, 10);
const plus = (days: number) => { const d = new Date(); d.setDate(d.getDate() + days); return d.toISOString().slice(0, 10); };

function offerState(o: Offer) {
  const now = Date.now();
  if (!o.isActive) return { label: "Off", cls: "pill-off" };
  if (new Date(o.startsAt).getTime() > now) return { label: "Scheduled", cls: "pill-confirmed" };
  if (new Date(o.endsAt).getTime() < now) return { label: "Ended", cls: "pill-off" };
  return { label: "Live", cls: "pill-on" };
}

export default function Offers() {
  const { show } = useToast();
  const [offers, setOffers] = useState<Offer[] | null>(null);
  const [cats, setCats] = useState<Category[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [err, setErr] = useState("");
  const [editing, setEditing] = useState<Offer | "new" | null>(null);
  const [scope, setScope] = useState<Scope>("shop");
  const [formErr, setFormErr] = useState("");
  const [busy, setBusy] = useState(false);
  const [deleting, setDeleting] = useState<Offer | null>(null);

  const load = () => { setErr(""); api.admin.offers().then(setOffers).catch((e) => setErr((e as Error).message)); };
  useEffect(() => {
    load();
    api.categories().then(setCats).catch(() => undefined);
    api.admin.products({ show: "active" }).then(async (first) => {
      const rest = await Promise.all(Array.from({ length: Math.min(first.pages, 10) - 1 }, (_, i) => api.admin.products({ show: "active", page: i + 2 })));
      setProducts([...first.items, ...rest.flatMap((r) => r.items)]);
    }).catch(() => undefined);
  }, []);

  const open = (o: Offer | "new") => {
    setFormErr("");
    setScope(o !== "new" && o.productId ? "product" : o !== "new" && o.categoryId ? "category" : "shop");
    setEditing(o);
  };

  const save = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    const body = {
      title: f.get("title"), percentOff: Number(f.get("percentOff")),
      startsAt: new Date(`${f.get("startsAt")}T00:00:00`).toISOString(),
      endsAt: new Date(`${f.get("endsAt")}T23:59:59`).toISOString(),
      isActive: !!f.get("isActive"),
      productId: scope === "product" ? f.get("productId") : null,
      categoryId: scope === "category" ? f.get("categoryId") : null,
    };
    setBusy(true); setFormErr("");
    try { await api.admin.saveOffer(body, editing === "new" ? undefined : editing!.id); show("Offer saved"); setEditing(null); load(); }
    catch (e) { setFormErr((e as Error).message); } finally { setBusy(false); }
  };
  const remove = async () => {
    setBusy(true);
    try { await api.admin.deleteOffer(deleting!.id); show("Offer deleted"); setDeleting(null); load(); }
    catch (e) { show((e as Error).message, { kind: "error" }); } finally { setBusy(false); }
  };

  const cur = editing && editing !== "new" ? editing : null;

  return (
    <div className="admin-page">
      <div className="admin-head">
        <div><h1>Offers</h1><p>Discounts show on product cards and are applied in the cart. If two offers cover a piece, the bigger one wins.</p></div>
        <button className="btn btn-primary" onClick={() => open("new")}><Icon name="plus" size={18} />Create offer</button>
      </div>

      {err ? <ErrorState message={err} onRetry={load} /> : !offers ? <PageLoading /> : !offers.length ? (
        <div className="panel"><EmptyState icon="offers" title="No offers yet" action={<button className="btn btn-primary" onClick={() => open("new")}>Create an offer</button>}>Run a sale on one piece, a whole category or the entire shop.</EmptyState></div>
      ) : (
        <div className="panel panel-flush">
          <div className="table-scroll">
            <table className="table">
              <thead><tr><th>Offer</th><th className="num">Discount</th><th>Applies to</th><th>Dates</th><th>Status</th><th><span className="sr-only">Actions</span></th></tr></thead>
              <tbody>
                {offers.map((o) => {
                  const st = offerState(o);
                  return (
                    <tr key={o.id}>
                      <td><strong>{o.title}</strong></td>
                      <td className="num">{o.percentOff}%</td>
                      <td>{o.product ? `${o.product.name} (${o.product.code})` : o.category ? `All ${o.category.name.toLowerCase()}` : "Whole shop"}</td>
                      <td className="muted">{shortDate(o.startsAt)} to {shortDate(o.endsAt)}</td>
                      <td><span className={`pill ${st.cls}`}>{st.label}</span></td>
                      <td><div className="row-actions">
                        <button className="icon-btn" aria-label={`Edit ${o.title}`} onClick={() => open(o)}><Icon name="edit" size={18} /></button>
                        <button className="icon-btn" aria-label={`Delete ${o.title}`} onClick={() => setDeleting(o)}><Icon name="trash" size={18} /></button>
                      </div></td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      <Modal open={!!editing} title={editing === "new" ? "Create offer" : "Edit offer"} onClose={() => setEditing(null)}>
        {editing && (
          <form className="form" onSubmit={save}>
            <label className="field"><span className="field-label">Title</span><input name="title" required maxLength={80} defaultValue={cur?.title} placeholder="Avurudu sale" autoFocus /><span className="field-hint">Shown on the product page</span></label>
            <label className="field"><span className="field-label">Discount (%)</span><input name="percentOff" type="number" required min={1} max={90} defaultValue={cur?.percentOff ?? 10} /></label>
            <fieldset className="fieldset">
              <legend>Applies to</legend>
              <div className="chips">
                {(["shop", "category", "product"] as Scope[]).map((s) => (
                  <button key={s} type="button" className="chip" aria-pressed={scope === s} onClick={() => setScope(s)}>{s === "shop" ? "Whole shop" : s === "category" ? "A category" : "One product"}</button>
                ))}
              </div>
              {scope === "category" && (
                <label className="field"><span className="sr-only">Category</span>
                  <select name="categoryId" required defaultValue={cur?.categoryId ?? ""}><option value="" disabled>Choose a category</option>{cats.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}</select>
                </label>
              )}
              {scope === "product" && (
                <label className="field"><span className="sr-only">Product</span>
                  <select name="productId" required defaultValue={cur?.productId ?? ""}><option value="" disabled>Choose a product</option>{products.map((p) => <option key={p.id} value={p.id}>{p.name} ({p.code})</option>)}</select>
                </label>
              )}
            </fieldset>
            <div className="form-grid">
              <label className="field"><span className="field-label">Starts</span><input name="startsAt" type="date" required defaultValue={toInput(cur?.startsAt) || today()} /></label>
              <label className="field"><span className="field-label">Ends</span><input name="endsAt" type="date" required defaultValue={toInput(cur?.endsAt) || plus(14)} /></label>
            </div>
            <Switch name="isActive" label="Offer is on" hint="Turn off to pause it without deleting" defaultChecked={cur?.isActive ?? true} />
            {formErr && <p className="form-error" role="alert">{formErr}</p>}
            <div className="modal-foot" style={{ margin: "4px -24px -24px" }}>
              <button type="button" className="btn btn-secondary" onClick={() => setEditing(null)}>Cancel</button>
              <button className="btn btn-primary" disabled={busy}>{busy ? "Saving…" : "Save offer"}</button>
            </div>
          </form>
        )}
      </Modal>

      <ConfirmDialog open={!!deleting} danger title="Delete this offer?" confirmLabel="Delete offer" busy={busy} onConfirm={remove} onClose={() => setDeleting(null)}
        body={<>{deleting?.title} will stop applying straight away. Past orders keep the price they were charged.</>} />
    </div>
  );
}
