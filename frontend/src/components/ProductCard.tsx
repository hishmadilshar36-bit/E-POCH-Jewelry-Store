import { Link, useNavigate } from "react-router-dom";
import type { Product } from "../api/types";
import { useCart } from "../context/CartContext";

export const lkr = (n: number) => `LKR ${n.toLocaleString("en-LK")}`;

export default function ProductCard({ p }: { p: Product }) {
  const { add } = useCart();
  const nav = useNavigate();
  return (
    <article className="card">
      <Link to={`/product/${p.slug}`}><img src={p.images[0]?.url} alt={p.name} /></Link>
      <h3>{p.name}</h3>
      <p>{lkr(p.price)}</p>
      <div className="row">
        <button disabled={!p.stock} onClick={() => add([{ productId: p.id, qty: 1 }])}>{p.stock ? "Add to cart" : "Sold out"}</button>
        {p.tryOnEnabled && <button onClick={() => nav(`/try-on?products=${p.id}`)}>Try with AI</button>}
      </div>
    </article>
  );
}
