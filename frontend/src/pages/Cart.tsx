import { Link } from "react-router-dom";
import { useCart } from "../context/CartContext";
import { lkr } from "../components/ProductCard";

export const DELIVERY_FEE = 450;

export default function CartPage() {
  const { cart, setQty, remove } = useCart();
  if (!cart?.items.length) return <p>Your cart is empty. <Link to="/shop">Browse jewellery</Link></p>;
  return (
    <section>
      <h1>My cart</h1>
      <table>
        <tbody>
          {cart.items.map((i) => (
            <tr key={i.id}>
              <td><img src={i.product.images[0]?.url} width={64} alt="" /></td>
              <td>{i.product.name}</td>
              <td>{lkr(i.product.price)}</td>
              <td>
                <input type="number" min={1} max={i.product.stock} value={i.qty} style={{ width: 70 }}
                  onChange={(e) => setQty(i.productId, Math.max(1, +e.target.value))} />
              </td>
              <td>{lkr(i.product.price * i.qty)}</td>
              <td><button className="ghost" onClick={() => remove(i.productId)}>Remove</button></td>
            </tr>
          ))}
        </tbody>
      </table>
      <p>Subtotal: {lkr(cart.subtotal)}</p>
      <p>Delivery: {lkr(DELIVERY_FEE)} (free for store pickup)</p>
      <h2>Total: {lkr(cart.subtotal + DELIVERY_FEE)}</h2>
      <Link to="/checkout"><button>Checkout</button></Link>
    </section>
  );
}
