import { ReactNode } from "react";
import { Link } from "react-router-dom";
import { useSettings } from "../context/SettingsContext";

type Props = { title: string; subtitle: string; aside: ReactNode; children: ReactNode };

export default function AuthShell({ title, subtitle, aside, children }: Props) {
  const s = useSettings();
  return (
    <div className="auth">
      <aside className="auth-aside">
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
