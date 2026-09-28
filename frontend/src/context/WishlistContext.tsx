import { createContext, useContext, useEffect, useState, ReactNode } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { api } from "../api/client";
import { useAuth } from "./AuthContext";
import { useToast } from "./ToastContext";

type Ctx = { ids: Set<string>; has: (id: string) => boolean; toggle: (id: string, name?: string) => Promise<void> };
const WishlistContext = createContext<Ctx>({ ids: new Set(), has: () => false, toggle: async () => undefined });

export function WishlistProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();
  const { show } = useToast();
  const nav = useNavigate();
  const loc = useLocation();
  const [ids, setIds] = useState<Set<string>>(new Set());

  useEffect(() => {
    if (user?.role !== "CUSTOMER") { setIds(new Set()); return; }
    api.wishlistIds().then((list) => setIds(new Set(list))).catch(() => undefined);
  }, [user]);

  const toggle = async (id: string, name?: string) => {
    if (!user) {
      show("Sign in to save pieces to your wishlist");
      nav("/login", { state: { from: loc.pathname + loc.search } });
      return;
    }
    const had = ids.has(id);
    const next = new Set(ids);
    had ? next.delete(id) : next.add(id);
    setIds(next);
    try {
      had ? await api.removeWish(id) : await api.addWish(id);
      show(had ? "Removed from wishlist" : `${name ?? "Saved"} added to your wishlist`, had ? {} : { link: { to: "/account/wishlist", label: "View" } });
    } catch (e) {
      setIds(ids);
      show((e as Error).message, { kind: "error" });
    }
  };

  return <WishlistContext.Provider value={{ ids, has: (id) => ids.has(id), toggle }}>{children}</WishlistContext.Provider>;
}

export const useWishlist = () => useContext(WishlistContext);
