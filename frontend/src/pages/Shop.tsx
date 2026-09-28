import { FormEvent, useEffect, useMemo, useState } from "react";
import { Link, useParams, useSearchParams } from "react-router-dom";
import { api } from "../api/client";
import type { Category, Paged, Product, ProductFilters } from "../api/types";
import ProductCard from "../components/ProductCard";
import Icon from "../components/Icon";
import { Breadcrumb, EmptyState, ErrorState, Pagination } from "../components/ui";

const sorts = [
  { v: "new", label: "Newest" },
  { v: "price_asc", label: "Price: low to high" },
  { v: "price_desc", label: "Price: high to low" },
  { v: "name", label: "Name A to Z" },
];

export default function Shop() {
  const { category } = useParams();
  const [sp, setSp] = useSearchParams();
  const [data, setData] = useState<Paged<Product> | null>(null);
  const [cats, setCats] = useState<Category[]>([]);
  const [facets, setFacets] = useState<ProductFilters | null>(null);
  const [err, setErr] = useState("");
  const [open, setOpen] = useState(false);
  const [reload, setReload] = useState(0);

  useEffect(() => {
    api.categories().then(setCats).catch(() => undefined);
    api.productFilters().then(setFacets).catch(() => undefined);
  }, []);

  useEffect(() => {
    setErr("");
    setData(null);
    api.products({ category, ...Object.fromEntries(sp), limit: 24 }).then(setData).catch((e) => setErr((e as Error).message));
  }, [category, sp, reload]);

  useEffect(() => { setOpen(false); }, [category, sp]);

  const set = (k: string, v: string | null) => {
    const n = new URLSearchParams(sp);
    v ? n.set(k, v) : n.delete(k);
    if (k !== "page") n.delete("page");
    setSp(n);
  };
  const toggle = (k: string) => set(k, sp.get(k) ? null : "1");

  const current = cats.find((c) => c.slug === category);
  const q = sp.get("q");
  const title = q ? `Results for “${q}”` : current?.name ?? (sp.get("newArrivals") ? "New arrivals" : sp.get("onSale") ? "Offers" : sp.get("tryOn") ? "Try on with AI" : "All jewellery");

  const activeChips = useMemo(() => {
    const chips: { label: string; clear: () => void }[] = [];
    if (q) chips.push({ label: `“${q}”`, clear: () => set("q", null) });
    if (sp.get("minPrice") || sp.get("maxPrice")) chips.push({ label: `LKR ${sp.get("minPrice") || "0"} to ${sp.get("maxPrice") || "any"}`, clear: () => { const n = new URLSearchParams(sp); n.delete("minPrice"); n.delete("maxPrice"); n.delete("page"); setSp(n); } });
    if (sp.get("style")) chips.push({ label: sp.get("style")!, clear: () => set("style", null) });
    if (sp.get("colour")) chips.push({ label: sp.get("colour")!, clear: () => set("colour", null) });
    if (sp.get("inStock")) chips.push({ label: "In stock", clear: () => set("inStock", null) });
    if (sp.get("onSale")) chips.push({ label: "On offer", clear: () => set("onSale", null) });
    if (sp.get("newArrivals")) chips.push({ label: "New arrivals", clear: () => set("newArrivals", null) });
    if (sp.get("tryOn")) chips.push({ label: "AI try-on", clear: () => set("tryOn", null) });
    return chips;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [sp]);

  const applyPrice = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    const n = new URLSearchParams(sp);
    const min = String(f.get("minPrice") || ""), max = String(f.get("maxPrice") || "");
    min ? n.set("minPrice", min) : n.delete("minPrice");
    max ? n.set("maxPrice", max) : n.delete("maxPrice");
    n.delete("page");
    setSp(n);
  };

  const keep = sp.toString() ? `?${new URLSearchParams([...sp].filter(([k]) => k !== "page")).toString()}` : "";

  return (
    <div className="page">
      <Breadcrumb items={[{ to: "/", label: "Home" }, { to: "/shop", label: "Shop" }, ...(current ? [{ label: current.name }] : [])]} />
      <div className="shop-head">
        <h1>{title}</h1>
      </div>

      <div className="shop">
        {open && <button className="drawer-scrim" aria-label="Close filters" onClick={() => setOpen(false)} />}
        <aside className={`filters ${open ? "is-open" : ""}`} aria-label="Filters">
          <div className="filters-head">
            <h2>Filters</h2>
            <button className="icon-btn" aria-label="Close filters" onClick={() => setOpen(false)}><Icon name="close" /></button>
          </div>

          <div className="filter-group">
            <h2>Category</h2>
            <div className="filter-list">
              <Link to={`/shop${keep}`} className={`filter-link ${!category ? "is-on" : ""}`}>All jewellery</Link>
              {cats.map((c) => (
                <Link key={c.id} to={`/shop/${c.slug}${keep}`} className={`filter-link ${category === c.slug ? "is-on" : ""}`} aria-current={category === c.slug ? "page" : undefined}>
                  {c.name}<span className="muted">{c._count?.products ?? ""}</span>
                </Link>
              ))}
            </div>
          </div>

          <form className="filter-group" onSubmit={applyPrice} key={`${sp.get("minPrice")}-${sp.get("maxPrice")}`}>
            <h2>Price (LKR)</h2>
            <div className="price-inputs">
              <label className="sr-only" htmlFor="minPrice">Minimum price</label>
              <input id="minPrice" name="minPrice" type="number" min={0} inputMode="numeric" placeholder={facets ? String(facets.minPrice) : "Min"} defaultValue={sp.get("minPrice") ?? ""} />
              <span aria-hidden="true">to</span>
              <label className="sr-only" htmlFor="maxPrice">Maximum price</label>
              <input id="maxPrice" name="maxPrice" type="number" min={0} inputMode="numeric" placeholder={facets ? String(facets.maxPrice) : "Max"} defaultValue={sp.get("maxPrice") ?? ""} />
            </div>
            <button className="btn btn-quiet btn-sm">Apply price</button>
          </form>

          {!!facets?.styles.length && (
            <div className="filter-group">
              <h2>Style</h2>
              <div className="chips">
                {facets.styles.map((st) => <button key={st} type="button" className="chip" aria-pressed={sp.get("style") === st} onClick={() => set("style", sp.get("style") === st ? null : st)}>{st}</button>)}
              </div>
            </div>
          )}
          {!!facets?.colours.length && (
            <div className="filter-group">
              <h2>Colour</h2>
              <div className="chips">
                {facets.colours.map((c) => <button key={c} type="button" className="chip" aria-pressed={sp.get("colour") === c} onClick={() => set("colour", sp.get("colour") === c ? null : c)}>{c}</button>)}
              </div>
            </div>
          )}

          <div className="filter-group">
            <h2>Show</h2>
            <label className="check"><input type="checkbox" checked={!!sp.get("inStock")} onChange={() => toggle("inStock")} />In stock only</label>
            <label className="check"><input type="checkbox" checked={!!sp.get("onSale")} onChange={() => toggle("onSale")} />On offer</label>
            <label className="check"><input type="checkbox" checked={!!sp.get("newArrivals")} onChange={() => toggle("newArrivals")} />New arrivals</label>
            <label className="check"><input type="checkbox" checked={!!sp.get("tryOn")} onChange={() => toggle("tryOn")} />Can try on with AI</label>
          </div>
        </aside>

        <div>
          <div className="shop-toolbar">
            <span className="shop-count" aria-live="polite">{data ? `${data.total} ${data.total === 1 ? "piece" : "pieces"}` : "Loading…"}</span>
            <div className="shop-toolbar-right">
              <button className="btn btn-quiet btn-sm filters-toggle" onClick={() => setOpen(true)} aria-expanded={open}><Icon name="filter" size={18} />Filters{activeChips.length ? ` (${activeChips.length})` : ""}</button>
              <label className="sort">
                <span className="sr-only">Sort by</span>
                <select value={sp.get("sort") ?? "new"} onChange={(e) => set("sort", e.target.value === "new" ? null : e.target.value)}>
                  {sorts.map((s) => <option key={s.v} value={s.v}>{s.label}</option>)}
                </select>
              </label>
            </div>
          </div>

          {activeChips.length > 0 && (
            <div className="active-filters">
              {activeChips.map((c) => <button key={c.label} className="chip" onClick={c.clear} aria-label={`Remove filter ${c.label}`}>{c.label}<Icon name="close" size={14} /></button>)}
              <Link to={category ? `/shop/${category}` : "/shop"} className="btn-link" style={{ minHeight: 36, fontSize: 14 }}>Clear all</Link>
            </div>
          )}

          {err ? <ErrorState message={err} onRetry={() => setReload((n) => n + 1)} />
            : !data ? <div className="pgrid">{Array.from({ length: 8 }, (_, i) => <div key={i} className="skeleton skeleton-card" />)}</div>
            : !data.items.length ? (
              <EmptyState title="No pieces match" action={<Link to="/shop" className="btn btn-primary">See all jewellery</Link>}>
                {activeChips.length ? "Remove a filter or search for something else." : "There's nothing in this category yet."}
              </EmptyState>
            ) : (
              <>
                <div className="pgrid">{data.items.map((p) => <ProductCard key={p.id} p={p} />)}</div>
                <Pagination page={data.page} pages={data.pages} onPage={(p) => set("page", p === 1 ? null : String(p))} />
              </>
            )}
        </div>
      </div>
    </div>
  );
}
