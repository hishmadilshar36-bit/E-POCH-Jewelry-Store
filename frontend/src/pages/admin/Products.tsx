import { FormEvent, useEffect, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { api } from "../../api/client";
import type { Category, Paged, Product } from "../../api/types";
import { lkr } from "../../api/format";
import { useToast } from "../../context/ToastContext";
import Icon from "../../components/Icon";
import { ConfirmDialog, EmptyState, ErrorState, PageLoading, Pagination, ProductImage } from "../../components/ui";

const shows = [
  { v: "all", label: "All" },
  { v: "active", label: "In the shop" },
  { v: "low", label: "Low stock" },
  { v: "hidden", label: "Hidden" },
];

export default function AdminProducts() {
  const [sp, setSp] = useSearchParams();
  const { show } = useToast();
  const [data, setData] = useState<Paged<Product> | null>(null);
  const [cats, setCats] = useState<Category[]>([]);
  const [err, setErr] = useState("");
  const [hiding, setHiding] = useState<Product | null>(null);
  const [busy, setBusy] = useState(false);

  const load = () => {
    setErr("");
    api.admin.products({ q: sp.get("q"), categoryId: sp.get("category"), show: sp.get("show") ?? "all", page: sp.get("page") ?? 1 })
      .then(setData).catch((e) => setErr((e as Error).message));
  };
  useEffect(load, [sp]);
  useEffect(() => { api.categories().then(setCats).catch(() => undefined); }, []);

  const set = (k: string, v: string | null) => {
    const n = new URLSearchParams(sp);
    v ? n.set(k, v) : n.delete(k);
    if (k !== "page") n.delete("page");
    setSp(n);
  };
  const search = (e: FormEvent<HTMLFormElement>) => { e.preventDefault(); set("q", String(new FormData(e.currentTarget).get("q") || "") || null); };

  const hide = async () => {
    if (!hiding) return;
    setBusy(true);
    try { await api.admin.hideProduct(hiding.id); show(`${hiding.name} is hidden from the shop`); setHiding(null); load(); }
    catch (e) { show((e as Error).message, { kind: "error" }); }
    finally { setBusy(false); }
  };

  return (
    <div className="admin-page">
      <div className="admin-head">
        <div><h1>Products</h1><p>{data ? `${data.total} ${data.total === 1 ? "product" : "products"}` : " "}</p></div>
        <Link to="/admin/products/new" className="btn btn-primary"><Icon name="plus" size={18} />Add product</Link>
      </div>

      <div className="toolbar">
        <form className="search" role="search" onSubmit={search}>
          <Icon name="search" size={18} />
          <label htmlFor="p-search" className="sr-only">Search products</label>
          <input id="p-search" name="q" type="search" placeholder="Name or code" defaultValue={sp.get("q") ?? ""} />
        </form>
        <label><span className="sr-only">Category</span>
          <select value={sp.get("category") ?? ""} onChange={(e) => set("category", e.target.value || null)}>
            <option value="">All categories</option>
            {cats.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
          </select>
        </label>
        <div className="tabs" role="group" aria-label="Show">
          {shows.map((s) => <button key={s.v} className="tab" aria-pressed={(sp.get("show") ?? "all") === s.v} onClick={() => set("show", s.v === "all" ? null : s.v)}>{s.label}</button>)}
        </div>
      </div>

      {err ? <ErrorState message={err} onRetry={load} /> : !data ? <PageLoading /> : !data.items.length ? (
        <div className="panel">
          <EmptyState icon="products" title={sp.toString() ? "No products match" : "No products yet"} action={<Link to="/admin/products/new" className="btn btn-primary">Add your first product</Link>}>
            {sp.toString() ? "Try another search or filter." : "Products you add appear in the shop straight away."}
          </EmptyState>
        </div>
      ) : (
        <>
          <div className="panel panel-flush">
            <div className="table-scroll">
              <table className="table">
                <thead><tr><th>Product</th><th>Category</th><th className="num">Price</th><th className="num">Stock</th><th>Try-on</th><th>Status</th><th><span className="sr-only">Actions</span></th></tr></thead>
                <tbody>
                  {data.items.map((p) => (
                    <tr key={p.id} className={p.isActive ? "" : "is-hidden-row"}>
                      <td>
                        <div className="cell-product">
                          <span className="table-thumb"><ProductImage url={p.images[0]?.url} alt="" type={p.jewelleryType} iconSize={24} /></span>
                          <span><Link to={`/admin/products/${p.id}`}>{p.name}</Link><span className="muted" style={{ display: "block" }}>{p.code}</span></span>
                        </div>
                      </td>
                      <td>{p.category?.name}</td>
                      <td className="num">{lkr(p.price)}</td>
                      <td className="num"><span className={p.stock === 0 ? "stock-num-out" : p.stock <= 3 ? "stock-num-low" : ""}>{p.stock}</span></td>
                      <td>{p.tryOnEnabled ? <span className="pill pill-on">On</span> : <span className="pill pill-off">Off</span>}</td>
                      <td>{p.isActive ? <span className="pill pill-on">In shop</span> : <span className="pill pill-off">Hidden</span>}</td>
                      <td>
                        <div className="row-actions">
                          <Link to={`/admin/products/${p.id}`} className="icon-btn" aria-label={`Edit ${p.name}`}><Icon name="edit" size={18} /></Link>
                          {p.isActive && <a href={`/product/${p.slug}`} target="_blank" rel="noreferrer" className="icon-btn" aria-label={`View ${p.name} in the shop`}><Icon name="eye" size={18} /></a>}
                          {p.isActive && <button className="icon-btn" aria-label={`Hide ${p.name}`} onClick={() => setHiding(p)}><Icon name="eyeOff" size={18} /></button>}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
          <Pagination page={data.page} pages={data.pages} onPage={(p) => set("page", String(p))} />
        </>
      )}

      <ConfirmDialog open={!!hiding} title="Hide this product?" confirmLabel="Hide product" busy={busy} onConfirm={hide} onClose={() => setHiding(null)}
        body={<>{hiding?.name} will be removed from the shop. Past orders keep it, and you can show it again from its edit page.</>} />
    </div>
  );
}
