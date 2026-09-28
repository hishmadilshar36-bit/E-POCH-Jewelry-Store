import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { api } from "../api/client";
import type { Product } from "../api/types";
import { typeLabel } from "../api/format";
import { useCart } from "../context/CartContext";
import { useWishlist } from "../context/WishlistContext";
import { useToast } from "../context/ToastContext";
import ProductCard from "../components/ProductCard";
import Icon from "../components/Icon";
import { Breadcrumb, EmptyState, PageLoading, Price, ProductImage, QtyStepper } from "../components/ui";

export default function ProductDetails() {
  const { slug } = useParams();
  const { add } = useCart();
  const { has, toggle } = useWishlist();
  const { show } = useToast();
  const [p, setP] = useState<Product | null>(null);
  const [related, setRelated] = useState<Product[]>([]);
  const [missing, setMissing] = useState(false);
  const [img, setImg] = useState(0);
  const [qty, setQty] = useState(1);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    setP(null); setMissing(false); setImg(0); setQty(1);
    api.product(slug!).then(setP).catch(() => setMissing(true));
    api.related(slug!).then(setRelated).catch(() => setRelated([]));
  }, [slug]);

  if (missing) return (
    <div className="page">
      <EmptyState icon="search" title="This piece isn't available" action={<Link to="/shop" className="btn btn-primary">Browse jewellery</Link>}>
        It may have sold out or been removed.
      </EmptyState>
    </div>
  );
  if (!p) return <PageLoading />;

  const images = p.images;
  const saved = has(p.id);
  const soldOut = p.stock <= 0;
  const low = !soldOut && p.stock <= 3;

  const addToCart = async () => {
    setBusy(true);
    await add([{ productId: p.id, qty }], `${p.name} added to cart`);
    setBusy(false);
  };

  const share = async () => {
    const url = window.location.href;
    try {
      if (navigator.share) await navigator.share({ title: p.name, url });
      else { await navigator.clipboard.writeText(url); show("Link copied"); }
    } catch { /* closed the share sheet */ }
  };

  return (
    <div className="page">
      <Breadcrumb items={[{ to: "/", label: "Home" }, { to: "/shop", label: "Shop" }, ...(p.category ? [{ to: `/shop/${p.category.slug}`, label: p.category.name }] : []), { label: p.name }]} />

      <div className="pdp">
        <div className="gallery">
          <div className="gallery-main">
            <ProductImage url={images[img]?.url} alt={`${p.name}${images.length > 1 ? `, photo ${img + 1} of ${images.length}` : ""}`} type={p.jewelleryType} iconSize={160} />
            {images.length > 1 && (
              <>
                <button className="icon-btn gallery-nav gallery-prev" aria-label="Previous photo" onClick={() => setImg((img - 1 + images.length) % images.length)}><Icon name="chevronLeft" /></button>
                <button className="icon-btn gallery-nav gallery-next" aria-label="Next photo" onClick={() => setImg((img + 1) % images.length)}><Icon name="chevronRight" /></button>
              </>
            )}
          </div>
          {images.length > 1 && (
            <div className="thumbs">
              {images.map((im, i) => (
                <button key={im.id} className="thumb" aria-current={i === img} aria-label={`Show photo ${i + 1}`} onClick={() => setImg(i)}>
                  <ProductImage url={im.url} alt="" type={p.jewelleryType} iconSize={32} />
                </button>
              ))}
            </div>
          )}
        </div>

        <div className="pdp-info">
          <div className="pdp-meta">
            <span>Code {p.code}</span>
            {soldOut ? <span className="stock stock-out"><Icon name="close" size={16} />Sold out</span>
              : low ? <span className="stock stock-low"><Icon name="alert" size={16} />Only {p.stock} left</span>
              : <span className="stock stock-in"><Icon name="check" size={16} />In stock</span>}
          </div>
          <h1>{p.name}</h1>
          <Price price={p.price} pricing={p} size="lg" />
          {p.offerTitle && <p className="pdp-offer">{p.offerTitle}: {p.offerPercent}% off</p>}
          {p.description && <p className="pdp-desc">{p.description}</p>}

          <div className="pdp-buy">
            <div className="pdp-buy-row">
              {!soldOut && <QtyStepper value={qty} max={Math.min(p.stock, 20)} onChange={setQty} />}
              <button className="btn btn-primary btn-lg" disabled={soldOut || busy} onClick={addToCart}>
                {soldOut ? "Sold out" : busy ? "Adding…" : "Add to cart"}
              </button>
            </div>
            {p.tryOnEnabled && (
              <Link to={`/try-on?products=${p.id}`} className="try-cta">
                <span className="try-cta-icon"><Icon name="sparkle" size={22} /></span>
                <span><strong>Try it on with AI</strong><span>See it on a model or on your own photo</span></span>
                <Icon name="chevronRight" />
              </Link>
            )}
          </div>

          <div className="pdp-actions">
            <button className="btn btn-quiet btn-sm" aria-pressed={saved} onClick={() => toggle(p.id, p.name)}>
              <Icon name="heart" size={18} filled={saved} />{saved ? "Saved" : "Save to wishlist"}
            </button>
            <button className="btn btn-quiet btn-sm" onClick={share}><Icon name="share" size={18} />Share</button>
          </div>

          <dl className="pdp-details">
            <dt>Type</dt><dd>{typeLabel[p.jewelleryType]}</dd>
            {p.category && <><dt>Category</dt><dd><Link to={`/shop/${p.category.slug}`}>{p.category.name}</Link></dd></>}
            {p.style && <><dt>Style</dt><dd>{p.style}</dd></>}
            {p.colour && <><dt>Colour</dt><dd>{p.colour}</dd></>}
          </dl>
        </div>
      </div>

      {related.length > 0 && (
        <section className="related" aria-labelledby="related-title">
          <div className="section-head"><h2 id="related-title">You may also like</h2>{p.category && <Link to={`/shop/${p.category.slug}`}>More {p.category.name.toLowerCase()}</Link>}</div>
          <div className="pgrid">{related.map((r) => <ProductCard key={r.id} p={r} />)}</div>
        </section>
      )}
    </div>
  );
}
