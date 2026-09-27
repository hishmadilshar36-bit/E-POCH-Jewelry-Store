import { FormEvent, useEffect, useState } from "react";
import { api } from "../../api/client";
import type { Category, Product, JewelleryType } from "../../api/types";
import { lkr } from "../../components/ProductCard";

const types: JewelleryType[] = ["EARRINGS", "NECKLACE", "CHAIN", "LONG_CHAIN", "BANGLE", "BRACELET", "RING", "ANKLET", "HAIR", "OTHER"];

export default function AdminProducts() {
  const [items, setItems] = useState<Product[]>([]);
  const [cats, setCats] = useState<Category[]>([]);
  const [editing, setEditing] = useState<Product | null | "new">(null);
  const [msg, setMsg] = useState("");

  const load = () => api.products({ limit: 60 }).then((r) => setItems(r.items));
  useEffect(() => { load(); api.categories().then(setCats); }, []);

  const save = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);
    fd.set("tryOnEnabled", fd.get("tryOnEnabled") ? "true" : "");
    fd.set("isNewArrival", fd.get("isNewArrival") ? "true" : "");
    try {
      await api.admin.saveProduct(fd, editing !== "new" ? editing?.id : undefined);
      setMsg("Product saved"); setEditing(null); load();
    } catch (e) { setMsg((e as Error).message); }
  };

  if (editing) {
    const p = editing === "new" ? undefined : editing;
    return (
      <form onSubmit={save}>
        <h1>{p ? "Edit product" : "Add product"}</h1>
        <label>Product name<input name="name" defaultValue={p?.name} required /></label>
        <label>Product code<input name="code" defaultValue={p?.code} required /></label>
        <label>Category
          <select name="categoryId" defaultValue={p?.category?.id} required>{cats.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}</select>
        </label>
        <label>Price (LKR)<input name="price" type="number" defaultValue={p?.price} required /></label>
        <label>Stock<input name="stock" type="number" defaultValue={p?.stock ?? 1} /></label>
        <label>Description<textarea name="description" defaultValue={p?.description} /></label>
        <label>Product images<input name="images" type="file" accept="image/*" multiple /></label>
        <label>Jewellery type
          <select name="jewelleryType" defaultValue={p?.jewelleryType ?? "EARRINGS"}>{types.map((t) => <option key={t}>{t}</option>)}</select>
        </label>
        <label className="row"><input type="checkbox" name="tryOnEnabled" defaultChecked={p?.tryOnEnabled ?? true} /> AI try-on enabled</label>
        <label>Try-on image (transparent PNG, optional)<input name="tryOnAsset" type="file" accept="image/png" /></label>
        <label className="row"><input type="checkbox" name="isNewArrival" /> Show in new arrivals</label>
        <div className="row"><button className="ghost" type="button" onClick={() => setEditing(null)}>Cancel</button><button>Save product</button></div>
        {msg && <p>{msg}</p>}
      </form>
    );
  }

  return (
    <section>
      <div className="row"><h1>Products</h1><button onClick={() => setEditing("new")}>Add product</button></div>
      {msg && <p role="status">{msg}</p>}
      <table>
        <thead><tr><th>Code</th><th>Name</th><th>Price</th><th>Stock</th><th>Try-on</th><th /></tr></thead>
        <tbody>
          {items.map((p) => (
            <tr key={p.id}>
              <td>{p.code}</td><td>{p.name}</td><td>{lkr(p.price)}</td><td>{p.stock}</td><td>{p.tryOnEnabled ? "On" : "Off"}</td>
              <td className="row">
                <button className="ghost" onClick={() => api.product(p.slug).then(setEditing)}>Edit</button>
                <button className="ghost" onClick={async () => { if (confirm(`Hide ${p.name} from the shop?`)) { await api.admin.deleteProduct(p.id); load(); } }}>Hide</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </section>
  );
}
