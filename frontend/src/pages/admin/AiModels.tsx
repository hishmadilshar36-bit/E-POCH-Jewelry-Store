import { FormEvent, useEffect, useState } from "react";
import { api } from "../../api/client";
import type { AiModel } from "../../api/types";
import { useToast } from "../../context/ToastContext";
import Icon from "../../components/Icon";
import { ConfirmDialog, EmptyState, ErrorState, Modal, PageLoading } from "../../components/ui";

export default function AiModels() {
  const { show } = useToast();
  const [models, setModels] = useState<AiModel[] | null>(null);
  const [err, setErr] = useState("");
  const [adding, setAdding] = useState(false);
  const [preview, setPreview] = useState<string>();
  const [formErr, setFormErr] = useState("");
  const [busy, setBusy] = useState(false);
  const [deleting, setDeleting] = useState<AiModel | null>(null);

  const load = () => { setErr(""); api.admin.aiModels().then(setModels).catch((e) => setErr((e as Error).message)); };
  useEffect(load, []);

  const add = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);
    if (!(fd.get("image") as File)?.size) { setFormErr("Choose a photo of the model."); return; }
    setBusy(true); setFormErr("");
    try { await api.admin.addAiModel(fd); show("Model added"); setAdding(false); setPreview(undefined); load(); }
    catch (e) { setFormErr((e as Error).message); } finally { setBusy(false); }
  };
  const toggle = async (m: AiModel) => {
    try { await api.admin.updateAiModel(m.id, { isActive: !m.isActive }); show(m.isActive ? `${m.name} is hidden from customers` : `${m.name} is available`); load(); }
    catch (e) { show((e as Error).message, { kind: "error" }); }
  };
  const remove = async () => {
    setBusy(true);
    try {
      const r = await api.admin.deleteAiModel(deleting!.id);
      show(r?.hidden ? `${deleting!.name} has past try-ons, so it was hidden instead of deleted` : "Model deleted");
      setDeleting(null); load();
    } catch (e) { show((e as Error).message, { kind: "error" }); } finally { setBusy(false); }
  };

  return (
    <div className="admin-page">
      <div className="admin-head">
        <div><h1>AI models</h1><p>Customers who don't upload their own photo choose one of these models for their try-on.</p></div>
        <button className="btn btn-primary" onClick={() => { setAdding(true); setFormErr(""); }}><Icon name="plus" size={18} />Add model</button>
      </div>

      {err ? <ErrorState message={err} onRetry={load} /> : !models ? <PageLoading /> : !models.length ? (
        <div className="panel">
          <EmptyState icon="model" title="No models yet" action={<button className="btn btn-primary" onClick={() => setAdding(true)}>Add your first model</button>}>
            Add a few front-facing portrait photos with the ears, neck and wrists visible. Use photos you have the rights to.
          </EmptyState>
        </div>
      ) : (
        <div className="gallery-admin">
          {models.map((m) => (
            <article key={m.id} className={`model-admin ${m.isActive ? "" : "is-off"}`}>
              <img src={m.imageUrl} alt={`Model ${m.name}`} />
              <div className="model-admin-body">
                <span><strong>{m.name}</strong><span className="muted" style={{ display: "block", fontSize: 13 }}>{m._count?.tryOns ?? 0} try-ons</span></span>
                <span className={`pill ${m.isActive ? "pill-on" : "pill-off"}`}>{m.isActive ? "Shown" : "Hidden"}</span>
              </div>
              <div className="model-admin-actions">
                <button className="btn btn-quiet btn-sm" style={{ flex: 1 }} onClick={() => toggle(m)}>{m.isActive ? "Hide" : "Show"}</button>
                <button className="icon-btn" aria-label={`Delete ${m.name}`} onClick={() => setDeleting(m)}><Icon name="trash" size={18} /></button>
              </div>
            </article>
          ))}
        </div>
      )}

      <Modal open={adding} title="Add model" onClose={() => { setAdding(false); setPreview(undefined); }}>
        <form className="form" onSubmit={add}>
          <label className="field"><span className="field-label">Name</span><input name="name" required maxLength={40} placeholder="Model 1" autoFocus /><span className="field-hint">Customers see this name</span></label>
          <div className="field">
            <span className="field-label">Photo</span>
            {preview && <img src={preview} alt="Preview" style={{ width: 140, aspectRatio: "3 / 4", objectFit: "cover", borderRadius: 12 }} />}
            <label className="btn btn-quiet btn-sm" style={{ alignSelf: "flex-start" }}><Icon name="upload" size={16} />{preview ? "Choose another" : "Choose photo"}
              <input name="image" type="file" accept="image/jpeg,image/png,image/webp" className="sr-only" onChange={(e) => { const f = e.target.files?.[0]; setPreview(f ? URL.createObjectURL(f) : undefined); }} />
            </label>
            <span className="field-hint">Front-facing, good light, ears, neck and wrists visible.</span>
          </div>
          {formErr && <p className="form-error" role="alert">{formErr}</p>}
          <div className="modal-foot" style={{ margin: "4px -24px -24px" }}>
            <button type="button" className="btn btn-secondary" onClick={() => setAdding(false)}>Cancel</button>
            <button className="btn btn-primary" disabled={busy}>{busy ? "Uploading…" : "Add model"}</button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog open={!!deleting} danger title="Delete this model?" confirmLabel="Delete model" busy={busy} onConfirm={remove} onClose={() => setDeleting(null)}
        body={deleting?._count?.tryOns ? <>{deleting.name} was used in {deleting._count.tryOns} try-ons, so it will be hidden instead of deleted.</> : <>{deleting?.name} will be removed.</>} />
    </div>
  );
}
