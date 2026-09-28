import { FormEvent, useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { api } from "../../api/client";
import type { Category, JewelleryType, Product, ProductImage as Img } from "../../api/types";
import { jewelleryTypes, typeLabel } from "../../api/format";
import { useToast } from "../../context/ToastContext";
import Icon from "../../components/Icon";
import { ErrorState, PageLoading, Switch } from "../../components/ui";

type NewFile = { file: File; url: string };
const okType = (f: File) => /image\/(jpeg|png|webp)/.test(f.type) && f.size <= 8 * 1024 * 1024;

export default function ProductForm() {
  const { id } = useParams();
  const isNew = !id;
  const nav = useNavigate();
  const { show } = useToast();
  const [p, setP] = useState<Product | null>(null);
  const [cats, setCats] = useState<Category[]>([]);
  const [images, setImages] = useState<Img[]>([]);
  const [files, setFiles] = useState<NewFile[]>([]);
  const [asset, setAsset] = useState<NewFile | null>(null);
  const [type, setType] = useState<JewelleryType>("EARRINGS");
  const [loadErr, setLoadErr] = useState("");
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    api.categories().then(setCats).catch(() => undefined);
    if (isNew) return;
    api.admin.product(id!).then((prod) => { setP(prod); setImages(prod.images); setType(prod.jewelleryType); }).catch((e) => setLoadErr((e as Error).message));
  }, [id, isNew]);

  useEffect(() => () => { files.forEach((f) => URL.revokeObjectURL(f.url)); if (asset) URL.revokeObjectURL(asset.url); }, []); // eslint-disable-line react-hooks/exhaustive-deps

  if (loadErr) return <ErrorState message={loadErr} />;
  if (!isNew && !p) return <PageLoading />;

  const addFiles = (list: FileList | null) => {
    if (!list) return;
    const good = Array.from(list).filter(okType);
    if (good.length < list.length) show("Some files were skipped. Use JPG, PNG or WebP up to 8 MB.", { kind: "error" });
    setFiles((prev) => [...prev, ...good.map((file) => ({ file, url: URL.createObjectURL(file) }))].slice(0, 10));
  };
  const removeNew = (i: number) => setFiles((prev) => { URL.revokeObjectURL(prev[i].url); return prev.filter((_, j) => j !== i); });

  const deleteImage = async (img: Img) => {
    try { await api.admin.deleteImage(p!.id, img.id); setImages((prev) => prev.filter((x) => x.id !== img.id)); show("Photo removed"); }
    catch (e) { show((e as Error).message, { kind: "error" }); }
  };
  const makeMain = async (img: Img) => {
    const order = [img.id, ...images.filter((x) => x.id !== img.id).map((x) => x.id)];
    try { await api.admin.orderImages(p!.id, order); setImages((prev) => [img, ...prev.filter((x) => x.id !== img.id)]); show("Main photo updated"); }
    catch (e) { show((e as Error).message, { kind: "error" }); }
  };
  const removeAsset = async () => {
    if (asset) { URL.revokeObjectURL(asset.url); setAsset(null); return; }
    try { await api.admin.removeTryOnAsset(p!.id); setP({ ...p!, tryOnAssetUrl: null }); show("Try-on image removed"); }
    catch (e) { show((e as Error).message, { kind: "error" }); }
  };

  const submit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);
    for (const k of ["isActive", "isNewArrival", "tryOnEnabled"]) fd.set(k, fd.get(k) ? "true" : "false");
    fd.delete("imagesPicker"); fd.delete("assetPicker");
    files.forEach((f) => fd.append("images", f.file));
    if (asset) fd.set("tryOnAsset", asset.file);
    setBusy(true); setErr("");
    try {
      const saved = await api.admin.saveProduct(fd, id);
      show(isNew ? `${saved.name} added to the shop` : "Changes saved");
      nav(isNew ? "/admin/products" : `/admin/products`, { replace: isNew });
    } catch (e) {
      setErr((e as Error).message);
      window.scrollTo({ top: 0, behavior: "smooth" });
    } finally { setBusy(false); }
  };

  const assetUrl = asset?.url ?? p?.tryOnAssetUrl;

  return (
    <form className="admin-page" onSubmit={submit}>
      <div className="admin-head">
        <div>
          <Link to="/admin/products" className="back-link"><Icon name="arrowLeft" size={16} />Products</Link>
          <h1>{isNew ? "Add product" : p!.name}</h1>
        </div>
        {!isNew && p!.isActive && <a href={`/product/${p!.slug}`} target="_blank" rel="noreferrer" className="btn btn-quiet"><Icon name="eye" size={18} />View in shop</a>}
      </div>
      {err && <p className="form-error" role="alert">{err}</p>}

      <div className="admin-form">
        <div className="admin-form-main">
          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>Details</h2>
            <div className="form-grid">
              <label className="field span-2"><span className="field-label">Product name</span><input name="name" required minLength={2} maxLength={120} defaultValue={p?.name} placeholder="Gold jhumka earrings" /></label>
              <label className="field"><span className="field-label">Product code</span><input name="code" required maxLength={30} defaultValue={p?.code} placeholder="ER025" autoCapitalize="characters" /></label>
              <label className="field"><span className="field-label">Category</span>
                <select name="categoryId" required defaultValue={p?.categoryId ?? ""}>
                  <option value="" disabled>Choose a category</option>
                  {cats.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
                </select>
              </label>
              <label className="field span-2"><span className="field-label">Description</span><textarea name="description" rows={5} maxLength={4000} defaultValue={p?.description ?? ""} placeholder="Materials, size, finish and how to care for it" /></label>
              <label className="field"><span className="field-label">Style <span className="optional">(optional)</span></span><input name="style" maxLength={40} defaultValue={p?.style ?? ""} placeholder="Traditional, Modern…" /><span className="field-hint">Shown as a filter in the shop</span></label>
              <label className="field"><span className="field-label">Colour <span className="optional">(optional)</span></span><input name="colour" maxLength={40} defaultValue={p?.colour ?? ""} placeholder="Gold, Silver, Rose gold…" /></label>
            </div>
          </section>

          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>Photos</h2>
            <p className="field-hint" style={{ marginTop: -8 }}>The first photo is the main one in the shop. JPG, PNG or WebP, up to 8 MB each.</p>
            <div className="image-manager">
              {images.map((img, i) => (
                <div key={img.id} className="im-tile">
                  <img src={img.url} alt={`Photo ${i + 1}`} />
                  {i === 0 && <span className="im-tile-main">Main</span>}
                  <div className="im-tile-actions">
                    {i > 0 && <button type="button" className="icon-btn" aria-label={`Make photo ${i + 1} the main photo`} title="Make main" onClick={() => makeMain(img)}><Icon name="check" size={16} /></button>}
                    <button type="button" className="icon-btn" aria-label={`Remove photo ${i + 1}`} title="Remove" onClick={() => deleteImage(img)}><Icon name="trash" size={16} /></button>
                  </div>
                </div>
              ))}
              {files.map((f, i) => (
                <div key={f.url} className="im-tile">
                  <img src={f.url} alt={`New photo ${i + 1}`} />
                  <span className={images.length === 0 && i === 0 ? "im-tile-main" : "im-tile-new"}>{images.length === 0 && i === 0 ? "Main" : "New"}</span>
                  <div className="im-tile-actions"><button type="button" className="icon-btn" aria-label={`Remove new photo ${i + 1}`} onClick={() => removeNew(i)}><Icon name="close" size={16} /></button></div>
                </div>
              ))}
              {images.length + files.length < 10 && (
                <label className="im-add">
                  <Icon name="image" size={24} />Add photos
                  <input name="imagesPicker" type="file" accept="image/jpeg,image/png,image/webp" multiple onChange={(e) => { addFiles(e.target.files); e.target.value = ""; }} />
                </label>
              )}
            </div>
          </section>

          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>AI try-on</h2>
            <Switch name="tryOnEnabled" label="Customers can try this on with AI" defaultChecked={p?.tryOnEnabled ?? true} />
            <label className="field"><span className="field-label">Jewellery type</span>
              <select name="jewelleryType" value={type} onChange={(e) => setType(e.target.value as JewelleryType)}>
                {jewelleryTypes.map((t) => <option key={t} value={t}>{typeLabel[t]}</option>)}
              </select>
              <span className="field-hint">Tells the AI where the piece is worn, for example earrings on the earlobes.</span>
            </label>
            <div className="field">
              <span className="field-label">Try-on image <span className="optional">(optional)</span></span>
              <div className="asset-row">
                <span className="asset-preview">{assetUrl ? <img src={assetUrl} alt="Try-on image" /> : <Icon name="image" size={28} />}</span>
                <div className="stack" style={{ gap: 8 }}>
                  <span className="field-hint">A PNG of just the piece on a transparent background gives the best results. Without one, the main photo is used.</span>
                  <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                    <label className="btn btn-quiet btn-sm">
                      <Icon name="upload" size={16} />{assetUrl ? "Replace" : "Upload PNG"}
                      <input name="assetPicker" type="file" accept="image/png,image/webp" className="sr-only" onChange={(e) => { const f = e.target.files?.[0]; if (f && okType(f)) setAsset({ file: f, url: URL.createObjectURL(f) }); e.target.value = ""; }} />
                    </label>
                    {assetUrl && <button type="button" className="btn btn-quiet btn-sm" onClick={removeAsset}>Remove</button>}
                  </div>
                </div>
              </div>
            </div>
          </section>
        </div>

        <div className="admin-form-side">
          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>Price and stock</h2>
            <label className="field"><span className="field-label">Price (LKR)</span><input name="price" type="number" required min={1} step={1} inputMode="numeric" defaultValue={p?.price} /></label>
            <label className="field"><span className="field-label">Stock</span><input name="stock" type="number" required min={0} step={1} inputMode="numeric" defaultValue={p?.stock ?? 1} /><span className="field-hint">Shows as sold out at 0</span></label>
          </section>
          <section className="panel form">
            <h2 style={{ fontSize: 22 }}>Visibility</h2>
            <Switch name="isActive" label="Show in the shop" defaultChecked={p?.isActive ?? true} />
            <Switch name="isNewArrival" label="Show in New arrivals" defaultChecked={p?.isNewArrival ?? true} />
          </section>
        </div>
      </div>

      <div className="save-bar">
        <Link to="/admin/products" className="btn btn-quiet">Cancel</Link>
        <button className="btn btn-primary" disabled={busy}>{busy ? "Saving…" : isNew ? "Add product" : "Save changes"}</button>
      </div>
    </form>
  );
}
