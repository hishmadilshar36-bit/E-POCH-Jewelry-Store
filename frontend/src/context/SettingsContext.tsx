import { createContext, useContext, useEffect, useState, ReactNode } from "react";
import { api } from "../api/client";
import type { Settings } from "../api/types";

const defaults: Settings = {
  shopName: "[Shop name]", tagline: "Jewellery for every day and every occasion.",
  phone: "", whatsapp: "", email: "", address: "",
  deliveryFee: 450, freeDeliveryOver: null, bankDetails: "",
  codEnabled: true, bankEnabled: true, onlineEnabled: false, pickupEnabled: true,
};

type Ctx = { settings: Settings; reload: () => Promise<void> };
const SettingsContext = createContext<Ctx>({ settings: defaults, reload: async () => undefined });

export function SettingsProvider({ children }: { children: ReactNode }) {
  const [settings, setSettings] = useState<Settings>(defaults);
  const reload = async () => {
    const data = await api.settings();
    // Keep defaults for anything the server doesn't send (for example an older backend).
    if (data && typeof data === "object" && !Array.isArray(data)) setSettings({ ...defaults, ...data });
  };

  useEffect(() => { reload().catch(() => undefined); }, []);
  useEffect(() => { document.title = settings.shopName.replace(/^\[|\]$/g, "") || "Jewellery"; }, [settings.shopName]);

  return <SettingsContext.Provider value={{ settings, reload }}>{children}</SettingsContext.Provider>;
}

export const useSettings = () => useContext(SettingsContext).settings;
export const useReloadSettings = () => useContext(SettingsContext).reload;
