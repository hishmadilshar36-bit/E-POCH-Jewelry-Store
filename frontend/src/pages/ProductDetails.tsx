import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { api } from "../api/client";
import type { Product } from "../api/types";
import { useCart } from "../context/CartContext";
import { lkr } from "../components/ProductCard";

export default function ProductDetails() {
  const { slug } = useParams();
  const nav = useNavigate();
  const { add } = useCart();
  const [p, setP] = useState<Product | null>(null);
  const [img, setImg] = useState(0);
  const [qty, setQty] = useState(1);
  const [msg, setMsg] = useState("");

  useEffect(() => { api.product(slug!).then(setP).catch(() => setMsg("Product not found")); }, [slug]);
  if (!p) return <p>{msg || "Loading…"}</p>;

  const addToCart = async () => {
    try { await add([{ productId: p.id, qty }]); setMsg("Added to cart"); } catch (e) { setMsg((e as Error).message); }
  };

  return (
    <div className="grid">
      <div>
        <img src={p.images[img]?.url} alt={p.name} style={{ width: "100%" }} />
        <div className="row">{p.images.map((im, i) => <img key={im.id} src={im.url} width={64} onClick={() => setImg(i)} className={i === img ? "selected" : ""} />)}</div>
      </div>
      <div>
        <h1>{p.name}</h1>
        <p>Product code: {p.code}</p>
        <h2>{lkr(p.price)}</h2>
        <p>{p.stock > 0 ? "Available" : "Sold out"}</p>
        <p>{p.description}</p>
        <div className="row">
          <button className="ghost" onClick={() => setQty(Math.max(1, qty - 1))}>−</button>
          <span>{qty}</span>
          <button className="ghost" onClick={() => setQty(Math.min(p.stock, qty + 1))}>+</button>
        </div>
        <div className="row">
          <button disabled={!p.stock} onClick={addToCart}>Add to cart</button>
          {p.tryOnEnabled && <button className="ghost" onClick={() => nav(`/try-on?products=${p.id}`)}>Try it with AI</button>}
        </div>
        {msg && <p role="status">{msg}</p>}
      </div>
    </div>
  );
}
