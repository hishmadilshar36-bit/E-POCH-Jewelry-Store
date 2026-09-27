import { createContext, useContext, useEffect, useState, ReactNode } from "react";
import { api } from "../api/client";
import type { Cart } from "../api/types";

type Ctx = {
  cart: Cart | null; count: number;
  add: (items: { productId: string; qty: number }[]) => Promise<void>;
  setQty: (productId: string, qty: number) => Promise<void>;
  remove: (productId: string) => Promise<void>;
  refresh: () => Promise<void>;
};
const CartContext = createContext<Ctx>(null!);

export function CartProvider({ children }: { children: ReactNode }) {
  const [cart, setCart] = useState<Cart | null>(null);
  const refresh = async () => setCart(await api.cart());
  useEffect(() => { refresh().catch(console.error); }, []);

  const value: Ctx = {
    cart,
    count: cart?.items.reduce((s, i) => s + i.qty, 0) ?? 0,
    add: async (items) => setCart(await api.addToCart(items)),
    setQty: async (id, qty) => setCart(await api.setQty(id, qty)),
    remove: async (id) => setCart(await api.removeItem(id)),
    refresh,
  };
  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}
export const useCart = () => useContext(CartContext);
