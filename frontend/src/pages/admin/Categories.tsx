import { FormEvent, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../../api/client";
import type { Category } from "../../api/types";
import { useToast } from "../../context/ToastContext";
import Icon from "../../components/Icon";
import JewelIcon from "../../components/JewelIcon";
import { ConfirmDialog, ErrorState, Modal, PageLoading } from "../../components/ui";

export default function Categories() {
  const { show } = useToast();
  const [cats, setCats] = useState<Category[] | null>(null);
  const [err, setErr] = useState("");
  const [editing, setEditing] = useState<Category | "new" | null>(null);
  const [deleting, setDeleting] = useState<Category | null>(null);
  const [formErr, setFormErr] = useState("");
  const [busy, setBusy] = useState(false);
  const [preview, setPreview] = useState<string>();

  const load = () => { setErr(""); api.categories().then(setCats).catch((e) => setErr((e as Error).message)); };
  useEffect(load, []);

  const open = (c: Category | "new") => { setFormErr(""); setPreview(undefined); setEditing(c); };

  const save = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);
    if (!(fd.get("image") as File)?.size) fd.delete("image");
    setBusy(true); setFormErr("");
    try {
      await api.admin.saveCategory(fd, editing === "new" ? undefined : editing!.id);
      show(editing === "new" ? "Category added" : "Category saved");
      setEditing(null); load();
    } catch (e) { setFormErr((e as Error).message); } finally { setBusy(false); }
  };

  const remove = async () => {
    setBusy(true);
    try { await api.admin.deleteCategory(deleting!.id); show("Category deleted"); setDeleting(null); load(); }
    catch (e) { show((e as Error).message, { kind: "error" }); setDeleting(null); }
    finally { setBusy(false); }
  };

  const current = editing && editing !== "new" ? editing : null;

  return (
    <div className="admin-page">
      <div className="admin-head">
        <div><h1>Categories</h1><p>Shown on the home page and as filters in the shop, in this order.</p></div>
        <button className="btn btn-primary" onClick={() => open("new")}><Icon name="plus" size={18} />Add category</button>
      </div>

      {err ? <ErrorState message={err} onRetry={load} /> : !cats ? <PageLoading /> : (
        <div className="panel panel-flush">
          <div className="table-scroll">
            <table className="table">
              <thead><tr><th>Category</th><th className="num">Order</th><th className="num">Products</th><th><span className="sr-only">Actions</span></th></tr></thead>
              <tbody>
                {cats.map((c) => (
                  <tr key={c.id}>
                    <td><div className="cell-product"><span className="cat-row-img">{c.imageUrl ? <img src={c.imageUrl} alt="" /> : <JewelIcon slug={c.slug} size={26} />}</span><strong>{c.name}</strong></div></td>
                    <td className="num">{c.sort}</td>
                    <td className="num"><Link to={`/admin/products?category=${c.id}`}>{c._count?.products ?? 0}</Link></td>
                    <td>
                      <div className="row-actions">
                        <button className="icon-btn" aria-label={`Edit ${c.name}`} onClick={() => open(c)}><Icon name="edit" size={18} /></button>
                        <button className="icon-btn" aria-label={`Delete ${c.name}`} onClick={() => setDeleting(c)}><Icon name="trash" size={18} /></button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      <Modal open={!!editing} title={editing === "new" ? "Add category" : "Edit category"} onClose={() => setEditing(null)}>
        {editing && (
          <form className="form" onSubmit={save} id="cat-form">
            <label className="field"><span className="field-label">Name</span><input name="name" required maxLength={60} defaultValue={current?.name} autoFocus /></label>
            <label className="field"><span className="field-label">Order</span><input name="sort" type="number" step={1} defaultValue={current?.sort ?? (cats?.length ?? 0)} /><span className="field-hint">Lower numbers show first</span></label>
            <div className="field">
              <span className="field-label">Image <span className="optional">(optional)</span></span>
              <div className="asset-row">
                <span className="cat-row-img" style={{ width: 72, height: 72 }}>{preview || current?.imageUrl ? <img src={preview ?? current!.imageUrl!} alt="" /> : <JewelIcon slug={current?.slug ?? ""} size={36} />}</span>
                <label className="btn btn-quiet btn-sm"><Icon name="upload" size={16} />Choose image
                  <input name="image" type="file" accept="image/jpeg,image/png,image/webp" className="sr-only" onChange={(e) => { const f = e.target.files?.[0]; setPreview(f ? URL.createObjectURL(f) : undefined); }} />
                </label>
              </div>
              <span className="field-hint">Without an image, a drawing that matches the name is shown.</span>
            </div>
            {formErr && <p className="form-error" role="alert">{formErr}</p>}
            <div className="modal-foot" style={{ margin: "4px -24px -24px" }}>
              <button type="button" className="btn btn-secondary" onClick={() => setEditing(null)}>Cancel</button>
              <button className="btn btn-primary" disabled={busy}>{busy ? "Saving…" : "Save category"}</button>
            </div>
          </form>
        )}
      </Modal>

      <ConfirmDialog open={!!deleting} danger title="Delete this category?" confirmLabel="Delete category" busy={busy} onConfirm={remove} onClose={() => setDeleting(null)}
        body={deleting?._count?.products ? <>{deleting.name} still has {deleting._count.products} products. Move them to another category first.</> : <>{deleting?.name} will be removed from the shop.</>} />
    </div>
  );
}
