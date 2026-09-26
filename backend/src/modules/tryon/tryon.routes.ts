import { Router } from "express";
import { z } from "zod";
import { db } from "../../config/db";
import { ah, HttpError } from "../../middleware/error";
import { optionalAuth, requireAdmin } from "../../middleware/auth";
import { upload, fileUrl } from "../../middleware/upload";

const r = Router();
r.use(optionalAuth);

r.get("/models", ah(async (_req, res) => res.json(await db.aiModel.findMany({ where: { isActive: true } }))));

r.post("/models", requireAdmin, upload.single("image"), ah(async (req, res) => {
  if (!req.file) throw new HttpError(400, "Image required");
  res.status(201).json(await db.aiModel.create({ data: { name: String(req.body.name ?? "Model"), imageUrl: fileUrl(req.file.filename) } }));
}));

// multipart: productIds (JSON array string), source=AI_MODEL|UPLOAD, aiModelId?, photo?
r.post("/", upload.single("photo"), ah(async (req, res) => {
  const b = z.object({
    productIds: z.string().transform((s) => z.array(z.string()).min(1).max(5).parse(JSON.parse(s))),
    source: z.enum(["AI_MODEL", "UPLOAD"]),
    aiModelId: z.string().optional(),
  }).parse(req.body);

  const products = await db.product.findMany({ where: { id: { in: b.productIds }, tryOnEnabled: true, isActive: true } });
  if (products.length !== b.productIds.length) throw new HttpError(400, "One or more items can't be tried on");
  if (new Set(products.map((p: { jewelleryType: any; }) => p.jewelleryType)).size !== products.length) throw new HttpError(400, "Pick one item per jewellery type");

  let inputUrl: string;
  if (b.source === "UPLOAD") {
    if (!req.file) throw new HttpError(400, "Upload a photo to continue");
    inputUrl = fileUrl(req.file.filename);
  } else {
    const m = b.aiModelId && (await db.aiModel.findUnique({ where: { id: b.aiModelId } }));
    if (!m) throw new HttpError(400, "Choose a model");
    inputUrl = m.imageUrl;
  }

  const job = await db.tryOn.create({
    data: { userId: req.user?.id, source: b.source, aiModelId: b.aiModelId, inputUrl, items: { create: b.productIds.map((productId) => ({ productId })) } },
  });
  res.status(202).json({ id: job.id, status: job.status });
}));

// Frontend polls this every ~2s
r.get("/:id", ah(async (req, res) => {
  const j = await db.tryOn.findUnique({ where: { id: req.params.id }, select: { id: true, status: true, resultUrl: true, error: true, items: { select: { productId: true } } } });
  if (!j) throw new HttpError(404, "Try-on not found");
  res.json({ ...j, error: j.error ? "Preview couldn't be generated. Try another photo." : null });
}));

export default r;