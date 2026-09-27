import { useEffect, useState } from "react";
import { useParams, useSearchParams } from "react-router-dom";
import { api } from "../api/client";
import type { Paged, Product } from "../api/types";
import ProductCard from "../components/ProductCard";

export default function Shop() {
  const { category } = useParams();
  const [sp, setSp] = useSearchParams();
  const [data, setData] = useState<Paged<Product>>({ items: [], total: 0 });

  useEffect(() => {
    api.products({ category, ...Object.fromEntries(sp) }).then(setData);
  }, [category, sp]);

  const set = (k: string, v: string) => { const n = new URLSearchParams(sp); v ? n.set(k, v) : n.delete(k); n.delete("page"); setSp(n); };

  return (
    <>
      <div className="row">
        <input placeholder="Search by name or code" defaultValue={sp.get("q") ?? ""} onKeyDown={(e) => e.key === "Enter" && set("q", e.currentTarget.value)} />
        <input type="number" placeholder="Min price" onBlur={(e) => set("minPrice", e.target.value)} />
        <input type="number" placeholder="Max price" onBlur={(e) => set("maxPrice", e.target.value)} />
        <select value={sp.get("sort") ?? "new"} onChange={(e) => set("sort", e.target.value)}>
          <option value="new">Newest</option><option value="price_asc">Price: low to high</option><option value="price_desc">Price: high to low</option>
        </select>
        <label className="row"><input type="checkbox" checked={!!sp.get("inStock")} onChange={(e) => set("inStock", e.target.checked ? "1" : "")} /> In stock only</label>
      </div>
      <p>{data.total} items</p>
      <div className="grid">{data.items.map((p) => <ProductCard key={p.id} p={p} />)}</div>
      {!data.items.length && <p>No items match these filters. Clear a filter to see more.</p>}
      <div className="row">
        {Array.from({ length: data.pages ?? 1 }, (_, i) => (
          <button key={i} className={data.page === i + 1 ? "" : "ghost"} onClick={() => set("page", String(i + 1))}>{i + 1}</button>
        ))}
      </div>
    </>
  );
}
