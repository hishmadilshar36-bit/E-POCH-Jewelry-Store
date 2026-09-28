import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../api/client";
import type { Category, Product } from "../api/types";
import { lkr } from "../api/format";
import { useSettings } from "../context/SettingsContext";
import ProductCard from "../components/ProductCard";
import Icon from "../components/Icon";
import JewelIcon from "../components/JewelIcon";
import { ProductImage } from "../components/ui";

function ProductRow({ items, loading, emptyText }: { items: Product[]; loading: boolean; emptyText: string }) {
  if (loading) return <div className="pgrid">{[0, 1, 2, 3].map((i) => <div key={i} className="skeleton skeleton-card" />)}</div>;
  if (!items.length) return <p className="empty-note">{emptyText}</p>;
  return <div className="pgrid">{items.map((p) => <ProductCard key={p.id} p={p} />)}</div>;
}

export default function Home() {
  const s = useSettings();
  const [cats, setCats] = useState<Category[]>([]);
  const [fresh, setFresh] = useState<Product[]>([]);
  const [sale, setSale] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      api.categories().then(setCats),
      api.products({ newArrivals: 1, limit: 8 }).then(async (r) => {
        // Fall back to the newest pieces when nothing is marked as a new arrival.
        setFresh(r.items.length ? r.items : (await api.products({ limit: 8 })).items);
      }),
      api.products({ onSale: 1, limit: 4 }).then((r) => setSale(r.items)),
    ]).catch(() => undefined).finally(() => setLoading(false));
  }, []);

  const heroPick = fresh.find((p) => p.tryOnEnabled) ?? fresh[0];

  return (
    <>
      <section className="hero">
        <div className="hero-inner">
          <div className="hero-copy">
            <h1>Discover your perfect jewellery</h1>
            <p>Earrings, bangles, chains, necklaces, rings and more. See any piece on a model or on your own photo before you order.</p>
            <div className="hero-actions">
              <Link to="/shop" className="btn btn-gold btn-lg">Shop now</Link>
              <Link to={heroPick?.tryOnEnabled ? `/try-on?products=${heroPick.id}` : "/shop?tryOn=1"} className="btn btn-outline-light btn-lg">
                <Icon name="sparkle" size={18} />Try it on with AI
              </Link>
            </div>
          </div>
          <div className="hero-visual" aria-hidden={!heroPick}>
            <div className="hero-arch">
              {heroPick?.images[0] ? <img src={heroPick.images[0].url} alt="" /> : <JewelIcon type={heroPick?.jewelleryType ?? "EARRINGS"} size={140} strokeWidth={1} />}
            </div>
            <span className="hero-chip"><Icon name="sparkle" size={14} />AI preview</span>
            {heroPick && (
              <Link to={`/product/${heroPick.slug}`} className="hero-card">
                <span className="hero-card-img"><ProductImage url={heroPick.images[0]?.url} alt="" type={heroPick.jewelleryType} iconSize={34} /></span>
                <span>
                  <span className="hero-card-name">{heroPick.name}</span><br />
                  <span className="muted">{lkr(heroPick.salePrice ?? heroPick.price)}</span>
                </span>
              </Link>
            )}
          </div>
        </div>
      </section>

      <section className="home-section" aria-labelledby="cat-title">
        <div className="section-head">
          <h2 id="cat-title">Shop by category</h2>
          <Link to="/shop">View all</Link>
        </div>
        <div className="cat-grid">
          {cats.map((c) => (
            <Link key={c.id} to={`/shop/${c.slug}`} className="cat-tile">
              <span className="cat-circle">{c.imageUrl ? <img src={c.imageUrl} alt="" /> : <JewelIcon slug={c.slug} size={52} />}</span>
              <span className="cat-name">{c.name}</span>
            </Link>
          ))}
        </div>
      </section>

      <section className="home-section" aria-labelledby="new-title">
        <div className="section-head">
          <h2 id="new-title">New arrivals</h2>
          <Link to="/shop?newArrivals=1">See all new pieces</Link>
        </div>
        <ProductRow items={fresh} loading={loading} emptyText="New pieces are on their way. Check back soon." />
      </section>

      {sale.length > 0 && (
        <section className="home-section" aria-labelledby="sale-title">
          <div className="section-head">
            <h2 id="sale-title">On offer now</h2>
            <Link to="/shop?onSale=1">See all offers</Link>
          </div>
          <ProductRow items={sale} loading={false} emptyText="" />
        </section>
      )}

      <section className="home-section" aria-labelledby="look-title">
        <div className="look-band" style={{ marginTop: 8 }}>
          <div className="look-copy">
            <h2 id="look-title">Create your look</h2>
            <p>Pick earrings, a necklace and bangles, then see the whole set on an AI model before you order. Mix any pieces you like.</p>
            <Link to="/build-look" className="btn btn-primary btn-lg">Start your look</Link>
          </div>
          <ol className="look-steps">
            <li className="look-step"><span className="look-step-num">1</span><span className="look-step-art"><JewelIcon type="EARRINGS" size={46} /></span><span className="look-step-name">Choose earrings</span></li>
            <li className="look-step"><span className="look-step-num">2</span><span className="look-step-art"><JewelIcon type="NECKLACE" size={46} /></span><span className="look-step-name">Choose a necklace</span></li>
            <li className="look-step"><span className="look-step-num">3</span><span className="look-step-art"><JewelIcon type="BANGLE" size={46} /></span><span className="look-step-name">Choose bangles</span></li>
            <li className="look-step look-step-final"><span className="look-step-num"><Icon name="sparkle" size={16} /></span><span className="look-step-art"><Icon name="model" size={40} /></span><span className="look-step-name">See it on with AI</span></li>
          </ol>
        </div>
      </section>

      <section className="trust" aria-label="Why shop with us">
        <div className="trust-item"><span className="trust-icon"><Icon name="truck" /></span><span><strong>Islandwide delivery</strong><span>{s.freeDeliveryOver ? `Free over ${lkr(s.freeDeliveryOver)}, otherwise ${lkr(s.deliveryFee)}` : `Delivered to your door for ${lkr(s.deliveryFee)}`}</span></span></div>
        {s.codEnabled && <div className="trust-item"><span className="trust-icon"><Icon name="cash" /></span><span><strong>Cash on delivery</strong><span>{s.bankEnabled ? "Or pay by bank transfer" : "Pay when it arrives"}</span></span></div>}
        <div className="trust-item"><span className="trust-icon"><Icon name="chat" /></span><span><strong>Help on WhatsApp</strong><span>Ask about any piece or order</span></span></div>
        {s.pickupEnabled && <div className="trust-item"><span className="trust-icon"><Icon name="store" /></span><span><strong>Store pickup</strong><span>{s.address ? `Collect from ${s.address}` : "Collect from our shop"}</span></span></div>}
      </section>
    </>
  );
}
