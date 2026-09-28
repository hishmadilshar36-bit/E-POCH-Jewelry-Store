import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../api/client";
import type { Category, JewelleryType, Product } from "../api/types";
import { lkr } from "../api/format";
import { useSettings } from "../context/SettingsContext";
import ProductCard from "../components/ProductCard";
import Icon from "../components/Icon";
import Reveal from "../components/Reveal";

const lookTypes: { label: string; types: JewelleryType[] }[] = [
  { label: "Earrings", types: ["EARRINGS"] },
  { label: "Necklace", types: ["NECKLACE", "CHAIN", "LONG_CHAIN"] },
  { label: "Bangles", types: ["BANGLE", "BRACELET"] },
];

export default function Home() {
  const s = useSettings();
  const [cats, setCats] = useState<Category[]>([]);
  const [fresh, setFresh] = useState<Product[]>([]);
  const [sale, setSale] = useState<Product[]>([]);
  const [models, setModels] = useState<string[]>([]);
  const [lookPieces, setLookPieces] = useState<{ label: string; p: Product }[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      api.categories().then(setCats),
      api.products({ newArrivals: 1, limit: 8 }).then(async (r) => {
        // Fall back to the newest pieces when nothing is marked as a new arrival.
        setFresh(r.items.length ? r.items : (await api.products({ limit: 8 })).items);
      }),
      api.products({ onSale: 1, limit: 12 }).then((r) => setSale(r.items)),
      api.aiModels().then((m) => setModels(m.map((x) => x.imageUrl))),
      Promise.all(lookTypes.map(async (t) => {
        const found = (await Promise.all(t.types.map((type) => api.products({ type, tryOn: 1, inStock: 1, limit: 1 })))).flatMap((r) => r.items)[0];
        return found?.images[0] ? { label: t.label, p: found } : null;
      })).then((list) => setLookPieces(list.filter(Boolean) as { label: string; p: Product }[])),
    ]).catch(() => undefined).finally(() => setLoading(false));
  }, []);

  const heroImg = models[0] ?? fresh.find((p) => p.images[0])?.images[0]?.url;
  const lookImg = models[1] ?? models[0] ?? heroImg;
  const catsWithItems = cats.filter((c) => (c._count?.products ?? 0) > 0);
  const shownCats = catsWithItems.length ? catsWithItems : cats;

  return (
    <>
      <section className="hero" aria-labelledby="hero-title">
        <div className="hero-copy">
          <h1 id="hero-title">Discover your perfect jewellery</h1>
          <p>See any piece on a model or on your own photo before you order.</p>
          <div className="hero-actions">
            <Link to="/shop" className="btn btn-primary btn-lg">Shop now</Link>
            <Link to="/shop?tryOn=1" className="btn btn-secondary btn-lg"><Icon name="sparkle" size={18} />Try on with AI</Link>
          </div>
        </div>
        <div className={`hero-media ${heroImg ? "" : "hero-media-empty"}`}>
          {heroImg ? <img src={heroImg} alt="A model wearing earrings and bangles from the shop" {...{ fetchpriority: "high" }} /> : <Icon name="diamond" size={96} />}
        </div>
      </section>

      {shownCats.length > 0 && (
        <section className="home-section" aria-labelledby="cat-title">
          <div className="section-head">
            <h2 id="cat-title">Shop by category</h2>
            <Link to="/shop">View all</Link>
          </div>
          <div className="rail">
            {shownCats.map((c, i) => (
              <Reveal key={c.id} index={i}>
                <Link to={`/shop/${c.slug}`} className="cat-card">
                  <span className="cat-card-img">
                    {c.imageUrl ? <img src={c.imageUrl} alt="" loading="lazy" /> : <span className="cat-card-letter" aria-hidden="true">{c.name.charAt(0)}</span>}
                  </span>
                  <span className="cat-card-name">{c.name}</span>
                </Link>
              </Reveal>
            ))}
          </div>
        </section>
      )}

      <section className="home-section" aria-labelledby="new-title">
        <div className="section-head">
          <h2 id="new-title">New arrivals</h2>
          <Link to="/shop?newArrivals=1">See all</Link>
        </div>
        {loading ? (
          <div className="pgrid">{[0, 1, 2, 3].map((i) => <div key={i} className="skeleton skeleton-card" />)}</div>
        ) : fresh.length ? (
          <div className="pgrid">{fresh.map((p, i) => <Reveal key={p.id} index={i % 4}><ProductCard p={p} /></Reveal>)}</div>
        ) : (
          <p className="empty-note">New pieces are on their way. Check back soon.</p>
        )}
      </section>

      <section className="home-section" aria-labelledby="look-title">
        <Reveal className="look-bento">
          <div className="look-copy">
            <h2 id="look-title">Create your look</h2>
            <p>Pick earrings, a necklace and bangles, then see the whole set on a model before you order.</p>
            <Link to="/build-look" className="btn btn-primary">Start your look</Link>
          </div>
          {lookImg && <div className="look-photo"><img src={lookImg} alt="A model wearing a full jewellery set" loading="lazy" /></div>}
          {lookPieces.length > 0 && (
            <div className="look-pieces">
              {lookPieces.map(({ label, p }) => (
                <Link key={p.id} to={`/product/${p.slug}`} className="look-piece">
                  <span className="look-piece-img"><img src={p.images[0].url} alt="" loading="lazy" /></span>
                  <span>{label}<br /><span className="muted">{lkr(p.salePrice ?? p.price)}</span></span>
                </Link>
              ))}
            </div>
          )}
        </Reveal>
      </section>

      {sale.length > 0 && (
        <section className="home-section" aria-labelledby="sale-title">
          <div className="section-head">
            <h2 id="sale-title">On offer now</h2>
            <Link to="/shop?onSale=1">See all offers</Link>
          </div>
          <div className="rail rail-products">
            {sale.map((p) => <ProductCard key={p.id} p={p} />)}
          </div>
        </section>
      )}

      <section className="services" aria-label="Delivery and payment">
        <div className="service"><Icon name="truck" size={22} /><span><strong>Islandwide delivery</strong><span>{s.freeDeliveryOver ? `Free over ${lkr(s.freeDeliveryOver)}, otherwise ${lkr(s.deliveryFee)}` : `Delivered to your door for ${lkr(s.deliveryFee)}`}</span></span></div>
        {s.codEnabled && <div className="service"><Icon name="cash" size={22} /><span><strong>Cash on delivery</strong><span>{s.bankEnabled ? "Or pay by bank transfer" : "Pay when it arrives"}</span></span></div>}
        <div className="service"><Icon name="chat" size={22} /><span><strong>Help on WhatsApp</strong><span>Ask about any piece or order</span></span></div>
        {s.pickupEnabled && <div className="service"><Icon name="store" size={22} /><span><strong>Store pickup</strong><span>{s.address ? `Collect from ${s.address}` : "Collect from our shop"}</span></span></div>}
      </section>
    </>
  );
}
