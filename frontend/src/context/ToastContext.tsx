import { createContext, useCallback, useContext, useRef, useState, ReactNode } from "react";
import { Link } from "react-router-dom";
import Icon from "../components/Icon";

type Toast = { id: number; text: string; kind: "ok" | "error"; link?: { to: string; label: string } };
type Ctx = { show: (text: string, opts?: { kind?: "ok" | "error"; link?: { to: string; label: string } }) => void };

const ToastContext = createContext<Ctx>({ show: () => undefined });

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);
  const nextId = useRef(1);

  const dismiss = (id: number) => setToasts((t) => t.filter((x) => x.id !== id));
  const show = useCallback<Ctx["show"]>((text, opts = {}) => {
    const id = nextId.current++;
    setToasts((t) => [...t.slice(-2), { id, text, kind: opts.kind ?? "ok", link: opts.link }]);
    window.setTimeout(() => dismiss(id), opts.kind === "error" ? 6000 : 3500);
  }, []);

  return (
    <ToastContext.Provider value={{ show }}>
      {children}
      <div className="toasts" role="status" aria-live="polite">
        {toasts.map((t) => (
          <div key={t.id} className={`toast toast-${t.kind}`}>
            <Icon name={t.kind === "ok" ? "check" : "alert"} size={18} />
            <span className="toast-text">{t.text}</span>
            {t.link && <Link to={t.link.to} className="toast-link" onClick={() => dismiss(t.id)}>{t.link.label}</Link>}
            <button className="icon-btn icon-btn-sm" aria-label="Dismiss" onClick={() => dismiss(t.id)}><Icon name="close" size={16} /></button>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export const useToast = () => useContext(ToastContext);
