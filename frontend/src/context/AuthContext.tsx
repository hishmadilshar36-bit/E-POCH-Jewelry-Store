import { createContext, useContext, useEffect, useState, ReactNode } from "react";
import { api, auth } from "../api/client";
import type { User } from "../api/types";
import { useCart } from "./CartContext";

type RegisterInput = { name: string; email: string; password: string; phone?: string };
type Ctx = {
  user: User | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<User>;
  register: (b: RegisterInput) => Promise<User>;
  logout: () => void;
  setUser: (u: User) => void;
};

const AuthContext = createContext<Ctx>(null!);

export function AuthProvider({ children }: { children: ReactNode }) {
  const { refresh } = useCart();
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(!!auth.token);

  useEffect(() => {
    if (!auth.token) return;
    api.me()
      .then(setUser)
      .catch(() => auth.set(null))
      .finally(() => setLoading(false));
  }, []);

  const signIn = async (token: string, u: User) => {
    auth.set(token);
    setUser(u);
    if (u.role === "CUSTOMER") await api.mergeCart().catch(() => undefined);
    await refresh().catch(() => undefined);
    return u;
  };

  const value: Ctx = {
    user,
    loading,
    login: async (email, password) => {
      const r = await api.login(email, password);
      return signIn(r.token, r.user);
    },
    register: async (b) => {
      const r = await api.register(b);
      return signIn(r.token, r.user);
    },
    logout: () => {
      auth.set(null);
      setUser(null);
      refresh().catch(() => undefined);
    },
    setUser,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export const useAuth = () => useContext(AuthContext);
