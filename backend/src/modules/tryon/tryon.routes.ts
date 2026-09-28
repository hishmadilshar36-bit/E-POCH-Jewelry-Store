import { Router } from "express";
import { z } from "zod";
import { db } from "../../config/db";
import { ah, HttpError } from "../../middleware/error";
import { optionalAuth, requireAuth } from "../../middleware/auth";
import { upload, fileUrl } from "../../middleware/upload";

const r = Router();
r.use(optionalAuth);

r.get("/models", ah(async (_req, res) => res.json(await db.aiModel.findMany({ where: { isActive: true }, orderBy: { createdAt: "asc" } }))));

// multipart: productIds (JSON array string), source=AI_MODEL|UPLOAD, aiModelId?, photo?
r.post("/", upload.single("photo"), ah(async (req, res) => {
  const b = z.object({
    productIds: z.string().transform((s, ctx) => {
      try { return z.array(z.string()).min(1).max(5).parse(JSON.parse(s)); }
      catch { ctx.addIssue({ code: "custom", message: "Choose 1 to 5 items" }); return z.NEVER; }
    }),
    source: z.enum(["AI_MODEL", "UPLOAD"]),
    aiModelId: z.string().optional(),
  }).parse(req.body);

  const products = await db.product.findMany({ where: { id: { in: b.productIds }, tryOnEnabled: true, isActive: true } });
  if (products.length !== b.productIds.length) throw new HttpError(400, "One or more of these items can't be tried on.");
  if (new Set(products.map((p) => p.jewelleryType)).size !== products.length) throw new HttpError(400, "Choose one item of each type, for example one pair of earrings and one necklace.");

  let inputUrl: string;
  if (b.source === "UPLOAD") {
    if (!req.file) throw new HttpError(400, "Upload a JPG, PNG or WebP photo to continue.");
    inputUrl = fileUrl(req.file.filename);
  } else {
    const m = b.aiModelId ? await db.aiModel.findFirst({ where: { id: b.aiModelId, isActive: true } }) : null;
    if (!m) throw new HttpError(400, "Choose a model to continue.");
    inputUrl = m.imageUrl;
  }

  const job = await db.tryOn.create({
    data: { userId: req.user?.id, source: b.source, aiModelId: b.source === "AI_MODEL" ? b.aiModelId : undefined, inputUrl, items: { create: b.productIds.map((productId) => ({ productId })) } },
  });
  res.status(202).json({ id: job.id, status: job.status });
}));

r.get("/mine", requireAuth, ah(async (req, res) => {
  res.json(await db.tryOn.findMany({
    where: { userId: req.user!.id, status: "DONE" },
    orderBy: { createdAt: "desc" },
    take: 50,
    select: {
      id: true, resultUrl: true, createdAt: true,
      items: { select: { product: { select: { id: true, name: true, slug: true, price: true, isActive: true } } } },
    },
  }));
}));

// The page polls this every 2 seconds
r.get("/:id", ah(async (req, res) => {
  const j = await db.tryOn.findUnique({ where: { id: req.params.id }, select: { id: true, status: true, resultUrl: true, error: true, items: { select: { productId: true } } } });
  if (!j) throw new HttpError(404, "Try-on not found");
  res.json({ ...j, error: j.error ? "We couldn't create a preview from this photo. Try a clear, front-facing photo with good light." : null });
}));

export default r;
