import { useEffect, useRef, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { api } from "../api/client";
import type { AiModel, TryOnJob } from "../api/types";
import { useCart } from "../context/CartContext";

// Reusable: /try-on?products=id1,id2,id3  (single product or a Build Your Look set)
export default function TryOn() {
  const [sp] = useSearchParams();
  const productIds = (sp.get("products") ?? "").split(",").filter(Boolean);
  const { add } = useCart();

  const [mode, setMode] = useState<"AI_MODEL" | "UPLOAD" | null>(null);
  const [models, setModels] = useState<AiModel[]>([]);
  const [modelId, setModelId] = useState<string>();
  const [photo, setPhoto] = useState<File>();
  const [job, setJob] = useState<TryOnJob | null>(null);
  const [err, setErr] = useState("");
  const timer = useRef<number>();

  useEffect(() => { if (mode === "AI_MODEL") api.aiModels().then(setModels); }, [mode]);
  useEffect(() => () => clearInterval(timer.current), []);

  const generate = async () => {
    setErr("");
    const fd = new FormData();
    fd.append("productIds", JSON.stringify(productIds));
    fd.append("source", mode!);
    if (mode === "AI_MODEL" && modelId) fd.append("aiModelId", modelId);
    if (mode === "UPLOAD" && photo) fd.append("photo", photo);
    try {
      const j = await api.startTryOn(fd);
      setJob(j);
      timer.current = window.setInterval(async () => {
        const s = await api.tryOnStatus(j.id);
        setJob(s);
        if (s.status === "DONE" || s.status === "FAILED") clearInterval(timer.current);
      }, 2000);
    } catch (e) { setErr((e as Error).message); }
  };

  const reset = () => { setJob(null); setPhoto(undefined); };

  if (!productIds.length) return <p>Choose a product first, then select “Try with AI”.</p>;

  if (job) return (
    <section>
      <h1>Your preview</h1>
      {(job.status === "PENDING" || job.status === "PROCESSING") && <p role="status">Generating your preview…</p>}
      {job.status === "FAILED" && <p className="error">{job.error}</p>}
      {job.status === "DONE" && (
        <>
          <img src={job.resultUrl} alt="Try-on preview" style={{ maxWidth: 480, width: "100%" }} />
          <div className="row">
            <a href={job.resultUrl} download><button className="ghost">Save</button></a>
            <button className="ghost" onClick={() => navigator.share?.({ url: job.resultUrl })}>Share</button>
            <button onClick={() => add(productIds.map((productId) => ({ productId, qty: 1 })))}>Add to cart</button>
          </div>
        </>
      )}
      <button className="ghost" onClick={reset}>Try again</button>
    </section>
  );

  return (
    <section>
      <h1>Virtual try-on</h1>
      <div className="row">
        <button className={mode === "AI_MODEL" ? "" : "ghost"} onClick={() => setMode("AI_MODEL")}>Use an AI model</button>
        <button className={mode === "UPLOAD" ? "" : "ghost"} onClick={() => setMode("UPLOAD")}>Upload my photo</button>
      </div>

      {mode === "AI_MODEL" && (
        <div className="grid">
          {models.map((m) => (
            <img key={m.id} src={m.imageUrl} alt={m.name} className={modelId === m.id ? "selected" : ""} onClick={() => setModelId(m.id)} />
          ))}
        </div>
      )}

      {mode === "UPLOAD" && (
        <>
          <input type="file" accept="image/jpeg,image/png,image/webp" onChange={(e) => setPhoto(e.target.files?.[0])} />
          {photo && <img src={URL.createObjectURL(photo)} alt="Your photo" width={240} />}
          <ul><li>Face clearly visible</li><li>Good lighting</li><li>Front-facing photo</li></ul>
        </>
      )}

      {mode && <button disabled={(mode === "AI_MODEL" && !modelId) || (mode === "UPLOAD" && !photo)} onClick={generate}>Generate try-on</button>}
      {err && <p className="error">{err}</p>}
    </section>
  );
}
