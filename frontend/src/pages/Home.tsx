import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../api/client";
import type { Category, Product } from "../api/types";
import ProductCard from "../components/ProductCard";

export default function Home() {
  const [cats, setCats] = useState<Category[]>([]);
  const [fresh, setFresh] = useState<Product[]>([]);
  useEffect(() => {
    api.categories().then(setCats);
    api.products({ newArrivals: 1, limit: 8 }).then((r) => setFresh(r.items));
  }, []);
  return (
    <>
      <section className="hero">
        <h1>Discover your perfect jewellery</h1>
        <p>Earrings, bangles, chains, necklaces, rings and more — see them on before you buy.</p>
        <Link to="/shop"><button>Shop now</button></Link>
      </section>
      <h2>Categories</h2>
      <div className="grid">
        {cats.map((c) => <Link key={c.id} to={`/shop/${c.slug}`} className="card">{c.name}</Link>)}
      </div>
      <h2>New arrivals</h2>
      <div className="grid">{fresh.map((p) => <ProductCard key={p.id} p={p} />)}</div>
    </>
  );
}
