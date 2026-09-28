import { createContext, useContext, useEffect, useState, ReactNode } from "react";
import { api } from "../api/client";
import type { Cart } from "../api/types";
import { useToast } from "./ToastContext";

type Ctx = {
  cart: Cart | null;
  count: number;
  add: (items: { productId: string; qty: number }[], message?: string) => Promise<boolean>;
  setQty: (productId: string, qty: number) => Promise<void>;
  remove: (productId: string) => Promise<void>;
  refresh: () => Promise<void>;
};
const CartContext = createContext<Ctx>(null!);

export function CartProvider({ children }: { children: ReactNode }) {
  const { show } = useToast();
  const [cart, setCart] = useState<Cart | null>(null);
  const refresh = async () => setCart(await api.cart());
  useEffect(() => { refresh().catch(() => undefined); }, []);

  const value: Ctx = {
    cart,
    count: cart?.items.reduce((s, i) => s + i.qty, 0) ?? 0,
    add: async (items, message) => {
      try {
        setCart(await api.addToCart(items));
        show(message ?? "Added to cart", { link: { to: "/cart", label: "View cart" } });
        return true;
      } catch (e) {
        show((e as Error).message, { kind: "error" });
        return false;
      }
    },
    setQty: async (id, qty) => {
      try { setCart(await api.setQty(id, qty)); } catch (e) { show((e as Error).message, { kind: "error" }); }
    },
    remove: async (id) => {
      try { setCart(await api.removeItem(id)); show("Removed from cart"); } catch (e) { show((e as Error).message, { kind: "error" }); }
    },
    refresh,
  };
  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}
export const useCart = () => useContext(CartContext);
