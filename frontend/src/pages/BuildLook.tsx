import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "../api/client";
import type { Product } from "../api/types";
import { lkr } from "../components/ProductCard";
import { useCart } from "../context/CartContext";

const steps = [
  { title: "Choose earrings", category: "earrings" },
  { title: "Choose a necklace", category: "necklaces" },
  { title: "Choose bangles", category: "bangles" },
];

export default function BuildLook() {
  const nav = useNavigate();
  const { add } = useCart();
  const [step, setStep] = useState(0);
  const [options, setOptions] = useState<Product[]>([]);
  const [picked, setPicked] = useState<Record<number, Product | undefined>>({});

  useEffect(() => {
    if (step < steps.length) api.products({ category: steps[step].category, inStock: 1 }).then((r) => setOptions(r.items.filter((p) => p.tryOnEnabled)));
  }, [step]);

  const chosen = Object.values(picked).filter(Boolean) as Product[];
  const total = chosen.reduce((s, p) => s + p.price, 0);

  if (step >= steps.length) return (
    <section>
      <h1>Your look</h1>
      <ul>{chosen.map((p) => <li key={p.id}>{p.name} — {lkr(p.price)}</li>)}</ul>
      <p>Total: {lkr(total)}</p>
      <div className="row">
        <button className="ghost" onClick={() => setStep(0)}>Change items</button>
        <button disabled={!chosen.length} onClick={() => nav(`/try-on?products=${chosen.map((p) => p.id).join(",")}`)}>Preview with AI</button>
        <button disabled={!chosen.length} onClick={async () => { await add(chosen.map((p) => ({ productId: p.id, qty: 1 }))); nav("/cart"); }}>Add all to cart</button>
      </div>
    </section>
  );

  return (
    <section>
      <p>Step {step + 1} of {steps.length}</p>
      <h1>{steps[step].title}</h1>
      <div className="grid">
        {options.map((p) => (
          <button key={p.id} className={`ghost ${picked[step]?.id === p.id ? "selected" : ""}`}
            onClick={() => setPicked({ ...picked, [step]: picked[step]?.id === p.id ? undefined : p })}>
            <img src={p.images[0]?.url} alt="" width="100%" />
            {p.name}<br />{lkr(p.price)}
          </button>
        ))}
      </div>
      <div className="row">
        {step > 0 && <button className="ghost" onClick={() => setStep(step - 1)}>Back</button>}
        <button onClick={() => setStep(step + 1)}>{picked[step] ? "Next" : "Skip"}</button>
      </div>
    </section>
  );
}
