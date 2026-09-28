import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { api } from "../api/client";
import type { JewelleryType, Product } from "../api/types";
import { lkr } from "../api/format";
import { useCart } from "../context/CartContext";
import Icon from "../components/Icon";
import { EmptyState, PageLoading, Price, ProductImage } from "../components/ui";

const steps: { title: string; short: string; types: JewelleryType[] }[] = [
  { title: "Choose earrings", short: "Earrings", types: ["EARRINGS"] },
  { title: "Choose a necklace or chain", short: "Necklace", types: ["NECKLACE", "CHAIN", "LONG_CHAIN"] },
  { title: "Choose bangles or a bracelet", short: "Bangles", types: ["BANGLE", "BRACELET"] },
];

export default function BuildLook() {
  const nav = useNavigate();
  const { add } = useCart();
  const [step, setStep] = useState(0);
  const [options, setOptions] = useState<Product[] | null>(null);
  const [picked, setPicked] = useState<(Product | undefined)[]>([]);

  useEffect(() => {
    if (step >= steps.length) return;
    setOptions(null);
    Promise.all(steps[step].types.map((type) => api.products({ type, inStock: 1, tryOn: 1, limit: 24 })))
      .then((rs) => setOptions(rs.flatMap((r) => r.items)))
      .catch(() => setOptions([]));
  }, [step]);

  const chosen = picked.filter(Boolean) as Product[];
  const total = chosen.reduce((s, p) => s + (p.salePrice ?? p.price), 0);
  const pick = (p: Product) => setPicked((prev) => { const n = [...prev]; n[step] = n[step]?.id === p.id ? undefined : p; return n; });
  const finished = step >= steps.length;

  const tray = (
    <aside className="look-tray" aria-label="Your look">
      <h2>Your look</h2>
      {steps.map((s, i) => {
        const p = picked[i];
        return (
          <div key={s.short} className={`tray-slot ${p ? "" : "tray-slot-empty"}`}>
            <span className="tray-slot-img">{p ? <ProductImage url={p.images[0]?.url} alt="" type={p.jewelleryType} iconSize={28} /> : <Icon name="plus" size={20} />}</span>
            <span className="tray-slot-text">
              {p ? <><strong>{p.name}</strong><span className="muted">{lkr(p.salePrice ?? p.price)}</span></> : <span className="muted">{s.short}: not chosen</span>}
            </span>
          </div>
        );
      })}
      <div className="tray-total"><span>Total</span><span className="num">{lkr(total)}</span></div>
    </aside>
  );

  if (finished) return (
    <div className="page">
      <div className="page-head"><h1>Your look</h1><p>Preview the full set with AI, or add it straight to your cart.</p></div>
      <div className="look">
        {chosen.length ? (
          <div className="stack">
            <div className="look-options">
              {chosen.map((p) => (
                <div key={p.id} className="look-option" style={{ cursor: "default" }}>
                  <span className="look-option-img"><ProductImage url={p.images[0]?.url} alt="" type={p.jewelleryType} /></span>
                  <Link to={`/product/${p.slug}`} className="look-option-name">{p.name}</Link>
                  <Price price={p.price} pricing={p} />
                </div>
              ))}
            </div>
            <div className="look-nav">
              <button className="btn btn-quiet" onClick={() => setStep(0)}><Icon name="edit" size={18} />Change pieces</button>
              <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
                <button className="btn btn-secondary" onClick={() => nav(`/try-on?products=${chosen.map((p) => p.id).join(",")}`)}><Icon name="sparkle" size={18} />Preview with AI</button>
                <button className="btn btn-primary" onClick={async () => { if (await add(chosen.map((p) => ({ productId: p.id, qty: 1 })), "Your look was added to the cart")) nav("/cart"); }}>Add all to cart · {lkr(total)}</button>
              </div>
            </div>
          </div>
        ) : (
          <EmptyState icon="sparkle" title="You haven't picked anything yet" action={<button className="btn btn-primary" onClick={() => setStep(0)}>Start again</button>}>
            Go back and choose at least one piece.
          </EmptyState>
        )}
        {tray}
      </div>
    </div>
  );

  return (
    <div className="page">
      <div className="page-head"><h1>Create your look</h1><p>Choose a piece at each step, or skip any you don't need.</p></div>
      <ol className="stepper" aria-label="Steps">
        {[...steps.map((s) => s.short), "Review"].map((label, i) => (
          <li key={label} className={step === i ? "is-current" : step > i ? "is-done" : ""} aria-current={step === i ? "step" : undefined}>
            <span className="step-dot">{step > i ? <Icon name="check" size={14} /> : i + 1}</span>{label}
          </li>
        ))}
      </ol>
      <div className="look">
        <div>
          <h2 style={{ fontSize: 28, marginBottom: 20 }}>{steps[step].title}</h2>
          {!options ? <PageLoading /> : !options.length ? (
            <p className="empty-note" style={{ textAlign: "left" }}>No pieces available for this step right now. Skip to the next one.</p>
          ) : (
            <div className="look-options">
              {options.map((p) => (
                <button key={p.id} className="look-option" aria-pressed={picked[step]?.id === p.id} onClick={() => pick(p)}>
                  <span className="look-option-img"><ProductImage url={p.images[0]?.url} alt="" type={p.jewelleryType} /></span>
                  <span className="look-option-name">{p.name}</span>
                  <Price price={p.price} pricing={p} />
                  <span className="look-option-check" aria-hidden="true"><Icon name="check" size={16} /></span>
                </button>
              ))}
            </div>
          )}
          <div className="look-nav">
            {step > 0 ? <button className="btn btn-quiet" onClick={() => setStep(step - 1)}><Icon name="arrowLeft" size={18} />Back</button> : <span />}
            <button className="btn btn-primary" onClick={() => setStep(step + 1)}>
              {picked[step] ? (step === steps.length - 1 ? "Review your look" : "Next") : "Skip this step"}<Icon name="chevronRight" size={18} />
            </button>
          </div>
        </div>
        {tray}
      </div>
    </div>
  );
}
