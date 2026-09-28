import { Link } from "react-router-dom";
import { lkr } from "../api/format";
import { useCart } from "../context/CartContext";
import Icon from "../components/Icon";
import { EmptyState, PageLoading, Price, ProductImage, QtyStepper } from "../components/ui";

export function FreeDeliveryBar({ subtotal, over }: { subtotal: number; over: number | null }) {
  if (!over) return null;
  const left = over - subtotal;
  return (
    <div className="free-bar">
      <span>{left > 0 ? <>Add <strong>{lkr(left)}</strong> more for free delivery</> : <strong>You get free delivery</strong>}</span>
      <span className="free-bar-track"><span className="free-bar-fill" style={{ width: `${Math.min(100, (subtotal / over) * 100)}%` }} /></span>
    </div>
  );
}

export default function CartPage() {
  const { cart, setQty, remove } = useCart();
  if (!cart) return <PageLoading />;
  if (!cart.items.length) return (
    <div className="page">
      <EmptyState icon="bag" title="Your cart is empty" action={<Link to="/shop" className="btn btn-primary">Browse jewellery</Link>}>
        Pieces you add will show here.
      </EmptyState>
    </div>
  );

  const blocked = cart.items.some((i) => !i.inStock);
  const count = cart.items.reduce((s, i) => s + i.qty, 0);

  return (
    <div className="page">
      <div className="page-head"><h1>Your cart</h1><p>{count} {count === 1 ? "piece" : "pieces"}</p></div>
      <div className="cart">
        <div className="cart-lines">
          {cart.items.map((i) => (
            <div key={i.id} className="cart-line">
              <Link to={`/product/${i.product.slug}`} className="cart-line-img" tabIndex={-1} aria-hidden="true">
                <ProductImage url={i.product.images[0]?.url} alt="" type={i.product.jewelleryType} />
              </Link>
              <div className="cart-line-info">
                <Link to={`/product/${i.product.slug}`} className="cart-line-name">{i.product.name}</Link>
                <Price price={i.product.price} pricing={i.product} />
                {!i.inStock && <span className="cart-line-warn">{i.product.stock ? `Only ${i.product.stock} left. Lower the quantity to continue.` : "Sold out. Remove it to continue."}</span>}
                <div className="cart-line-controls">
                  <QtyStepper value={i.qty} max={Math.max(1, Math.min(i.product.stock, 20))} onChange={(n) => setQty(i.productId, n)} label={`Quantity of ${i.product.name}`} />
                  <button className="btn-link" onClick={() => remove(i.productId)} style={{ fontSize: 14 }}>Remove</button>
                </div>
              </div>
              <span className="cart-line-total">{lkr(i.lineTotal)}</span>
            </div>
          ))}
        </div>

        <aside className="summary" aria-label="Order summary">
          <h2>Summary</h2>
          <div className="summary-row"><span>Subtotal</span><span>{lkr(cart.subtotal)}</span></div>
          <div className="summary-row"><span>Delivery</span><span>{cart.deliveryFee ? lkr(cart.deliveryFee) : "Free"}</span></div>
          <FreeDeliveryBar subtotal={cart.subtotal} over={cart.freeDeliveryOver} />
          <div className="summary-row summary-total"><span>Total</span><span>{lkr(cart.total)}</span></div>
          <p className="summary-note">Store pickup is free. You'll choose at checkout.</p>
          {blocked ? (
            <button className="btn btn-primary btn-lg btn-block" disabled>Checkout</button>
          ) : (
            <Link to="/checkout" className="btn btn-primary btn-lg btn-block"><Icon name="lock" size={18} />Checkout</Link>
          )}
          <Link to="/shop" className="btn btn-quiet btn-block">Continue shopping</Link>
        </aside>
      </div>
    </div>
  );
}
