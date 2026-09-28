import { Link, useNavigate } from "react-router-dom";
import type { Product } from "../api/types";
import { useCart } from "../context/CartContext";
import { useWishlist } from "../context/WishlistContext";
import Icon from "./Icon";
import { Price, ProductImage } from "./ui";

export default function ProductCard({ p }: { p: Product }) {
  const { add } = useCart();
  const { has, toggle } = useWishlist();
  const nav = useNavigate();
  const saved = has(p.id);
  const soldOut = p.stock <= 0;

  return (
    <article className={`pcard ${soldOut ? "is-soldout" : ""}`}>
      <div className="pcard-media">
        <Link to={`/product/${p.slug}`} className="pcard-link" tabIndex={-1} aria-hidden="true">
          <ProductImage url={p.images[0]?.url} alt={p.name} type={p.jewelleryType} />
        </Link>
        <button className={`pcard-wish ${saved ? "is-on" : ""}`} aria-pressed={saved} aria-label={saved ? `Remove ${p.name} from wishlist` : `Save ${p.name} to wishlist`} onClick={() => toggle(p.id, p.name)}>
          <Icon name="heart" size={20} filled={saved} />
        </button>
      </div>
      <div className="pcard-body">
        <div className="pcard-meta">
          <span>{p.code}</span>
          {p.isNewArrival && !soldOut && <span className="pcard-new">New</span>}
        </div>
        <h3 className="pcard-name"><Link to={`/product/${p.slug}`}>{p.name}</Link></h3>
        <Price price={p.price} pricing={p} />
      </div>
      <div className="pcard-actions">
        <button className="btn btn-primary btn-sm pcard-add" disabled={soldOut} onClick={() => add([{ productId: p.id, qty: 1 }], `${p.name} added to cart`)}>
          {soldOut ? "Sold out" : "Add to cart"}
        </button>
        {p.tryOnEnabled && (
          <button className="btn btn-quiet btn-sm pcard-try" onClick={() => nav(`/try-on?products=${p.id}`)} aria-label={`Try on ${p.name} with AI`} title="Try on with AI">
            <Icon name="sparkle" size={18} />
          </button>
        )}
      </div>
    </article>
  );
}
