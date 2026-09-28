import { ReactNode, useEffect, useRef, useState } from "react";
import { Link } from "react-router-dom";
import type { JewelleryType, OrderStatus, Pricing } from "../api/types";
import { lkr, statusLabel } from "../api/format";
import Icon, { IconName } from "./Icon";

/* ---------- Product image with a drawn placeholder ---------- */
export function ProductImage({ url, alt, type, className = "", iconSize = 72 }: { url?: string | null; alt: string; type?: JewelleryType; className?: string; iconSize?: number }) {
  const [failed, setFailed] = useState(false);
  if (url && !failed) return <img src={url} alt={alt} className={`pimg ${className}`} loading="lazy" onError={() => setFailed(true)} />;
  return <span className={`pimg pimg-empty ${className}`} role="img" aria-label={alt} data-type={type}><Icon name="diamond" size={Math.round(iconSize * 0.6)} /></span>;
}

/* ---------- Price with offer ---------- */
export function Price({ price, pricing, size = "md" }: { price: number; pricing?: Pricing; size?: "md" | "lg" }) {
  const sale = pricing?.salePrice;
  return (
    <span className={`price price-${size}`}>
      {sale != null ? (
        <>
          <span className="price-now">{lkr(sale)}</span>
          <s className="price-was"><span className="sr-only">Was </span>{lkr(price)}</s>
          <span className="price-off">{pricing?.offerPercent}% off</span>
        </>
      ) : <span className="price-now">{lkr(price)}</span>}
    </span>
  );
}

/* ---------- Quantity stepper ---------- */
export function QtyStepper({ value, max, onChange, label = "Quantity", disabled }: { value: number; max: number; onChange: (n: number) => void; label?: string; disabled?: boolean }) {
  return (
    <div className="qty" role="group" aria-label={label}>
      <button type="button" className="qty-btn" aria-label="Decrease quantity" disabled={disabled || value <= 1} onClick={() => onChange(value - 1)}><Icon name="minus" size={16} /></button>
      <output className="qty-value" aria-live="polite">{value}</output>
      <button type="button" className="qty-btn" aria-label="Increase quantity" disabled={disabled || value >= max} onClick={() => onChange(value + 1)}><Icon name="plus" size={16} /></button>
    </div>
  );
}

/* ---------- Order status pill ---------- */
export function StatusPill({ status, label }: { status: OrderStatus; label?: string }) {
  return <span className={`pill pill-${status.toLowerCase()}`}>{label ?? statusLabel[status]}</span>;
}

/* ---------- Loading / empty / error ---------- */
export function PageLoading({ label = "Loading…" }: { label?: string }) {
  return <div className="page-loading" role="status"><span className="spinner" aria-hidden="true" />{label}</div>;
}

export function EmptyState({ icon = "search", title, children, action }: { icon?: IconName; title: string; children?: ReactNode; action?: ReactNode }) {
  return (
    <div className="empty-state">
      <span className="empty-icon"><Icon name={icon} size={28} /></span>
      <h2>{title}</h2>
      {children && <p>{children}</p>}
      {action}
    </div>
  );
}

export function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div className="empty-state">
      <span className="empty-icon empty-icon-error"><Icon name="alert" size={28} /></span>
      <h2>That didn't load</h2>
      <p>{message}</p>
      {onRetry && <button className="btn btn-secondary" onClick={onRetry}><Icon name="refresh" size={18} />Try again</button>}
    </div>
  );
}

/* ---------- Pagination ---------- */
export function Pagination({ page, pages, onPage }: { page: number; pages: number; onPage: (p: number) => void }) {
  if (pages <= 1) return null;
  const nums = Array.from({ length: pages }, (_, i) => i + 1).filter((n) => n === 1 || n === pages || Math.abs(n - page) <= 1);
  return (
    <nav className="pager" aria-label="Pages">
      <button className="pager-btn" disabled={page <= 1} onClick={() => onPage(page - 1)} aria-label="Previous page"><Icon name="chevronLeft" size={18} /></button>
      {nums.map((n, i) => (
        <span key={n} className="pager-group">
          {i > 0 && n - nums[i - 1] > 1 && <span className="pager-gap" aria-hidden="true">…</span>}
          <button className={`pager-btn ${n === page ? "is-current" : ""}`} aria-current={n === page ? "page" : undefined} onClick={() => onPage(n)}>{n}</button>
        </span>
      ))}
      <button className="pager-btn" disabled={page >= pages} onClick={() => onPage(page + 1)} aria-label="Next page"><Icon name="chevronRight" size={18} /></button>
    </nav>
  );
}

/* ---------- Modal (native dialog) ---------- */
export function Modal({ open, title, onClose, children, footer, wide }: { open: boolean; title: string; onClose: () => void; children: ReactNode; footer?: ReactNode; wide?: boolean }) {
  const ref = useRef<HTMLDialogElement>(null);
  useEffect(() => {
    const d = ref.current;
    if (!d) return;
    if (open && !d.open) d.showModal();
    if (!open && d.open) d.close();
  }, [open]);
  return (
    <dialog ref={ref} className={`modal ${wide ? "modal-wide" : ""}`} onClose={onClose} onCancel={(e) => { e.preventDefault(); onClose(); }}
      onClick={(e) => { if (e.target === ref.current) onClose(); }}>
      {open && (
        <div className="modal-inner">
          <header className="modal-head">
            <h2>{title}</h2>
            <button className="icon-btn" aria-label="Close" onClick={onClose}><Icon name="close" /></button>
          </header>
          <div className="modal-body">{children}</div>
          {footer && <footer className="modal-foot">{footer}</footer>}
        </div>
      )}
    </dialog>
  );
}

export function ConfirmDialog({ open, title, body, confirmLabel, danger, busy, onConfirm, onClose }: {
  open: boolean; title: string; body: ReactNode; confirmLabel: string; danger?: boolean; busy?: boolean; onConfirm: () => void; onClose: () => void;
}) {
  return (
    <Modal open={open} title={title} onClose={onClose} footer={
      <>
        <button className="btn btn-secondary" onClick={onClose}>Keep it</button>
        <button className={`btn ${danger ? "btn-danger" : "btn-primary"}`} disabled={busy} onClick={onConfirm}>{busy ? "Working…" : confirmLabel}</button>
      </>
    }>
      <p className="modal-text">{body}</p>
    </Modal>
  );
}

/* ---------- Breadcrumb ---------- */
export function Breadcrumb({ items }: { items: { to?: string; label: string }[] }) {
  return (
    <nav className="crumbs" aria-label="Breadcrumb">
      <ol>
        {items.map((it, i) => (
          <li key={i}>
            {it.to && i < items.length - 1 ? <Link to={it.to}>{it.label}</Link> : <span aria-current={i === items.length - 1 ? "page" : undefined}>{it.label}</span>}
          </li>
        ))}
      </ol>
    </nav>
  );
}

/* ---------- Switch (checkbox styled as a toggle) ---------- */
export function Switch({ name, label, hint, defaultChecked, checked, onChange }: { name?: string; label: string; hint?: string; defaultChecked?: boolean; checked?: boolean; onChange?: (v: boolean) => void }) {
  return (
    <label className="switch">
      <input type="checkbox" role="switch" name={name} defaultChecked={defaultChecked} checked={checked} onChange={onChange ? (e) => onChange(e.target.checked) : undefined} />
      <span className="switch-track" aria-hidden="true"><span className="switch-thumb" /></span>
      <span className="switch-text"><span className="switch-label">{label}</span>{hint && <span className="field-hint">{hint}</span>}</span>
    </label>
  );
}
