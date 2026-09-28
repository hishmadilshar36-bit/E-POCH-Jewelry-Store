import { ReactNode, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../api/client";
import { useSettings } from "../context/SettingsContext";

type Props = { title: string; subtitle: string; aside: ReactNode; children: ReactNode };

export default function AuthShell({ title, subtitle, aside, children }: Props) {
  const s = useSettings();
  const [photo, setPhoto] = useState<string | null>(null);
  useEffect(() => { api.aiModels().then((m) => setPhoto(m[1]?.imageUrl ?? m[0]?.imageUrl ?? null)).catch(() => undefined); }, []);

  return (
    <div className="auth">
      <aside className={`auth-aside ${photo ? "has-photo" : ""}`}>
        {photo && <img className="auth-photo" src={photo} alt="" />}
        <Link to="/" className="auth-logo">{s.shopName}</Link>
        <div className="auth-aside-body">{aside}</div>
      </aside>
      <main className="auth-main">
        <div className="auth-card">
          <h1>{title}</h1>
          <p className="auth-sub">{subtitle}</p>
          {children}
        </div>
      </main>
    </div>
  );
}
