import { Router } from "express";
import { z } from "zod";
import { db } from "../../config/db";
import { ah, HttpError } from "../../middleware/error";
import { requireAdmin } from "../../middleware/auth";
import { upload, fileUrl } from "../../middleware/upload";

const r = Router();
const slugify = (s: string) => s.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-");

// GET /api/products?category=earrings&q=&minPrice=&maxPrice=&style=&colour=&inStock=1&newArrivals=1&sort=price_asc&page=1
r.get("/", ah(async (req, res) => {
  const q = z.object({
    category: z.string().optional(), q: z.string().optional(),
    minPrice: z.coerce.number().optional(), maxPrice: z.coerce.number().optional(),
    style: z.string().optional(), colour: z.string().optional(),
    inStock: z.string().optional(), newArrivals: z.string().optional(),
    sort: z.enum(["new", "price_asc", "price_desc"]).default("new"),
    page: z.coerce.number().default(1), limit: z.coerce.number().max(60).default(24),
  }).parse(req.query);

  // Let Prisma infer the filter type from the generated client. Some Prisma
  // versions do not expose model-specific input types through `Prisma`.
  const where = {
    isActive: true,
    ...(q.category && { category: { slug: q.category } }),
    ...(q.q && { OR: [{ name: { contains: q.q, mode: "insensitive" } }, { code: { contains: q.q, mode: "insensitive" } }] }),
    ...((q.minPrice || q.maxPrice) && { price: { gte: q.minPrice, lte: q.maxPrice } }),
    ...(q.style && { style: q.style }),
    ...(q.colour && { colour: q.colour }),
    ...(q.inStock && { stock: { gt: 0 } }),
    ...(q.newArrivals && { isNewArrival: true }),
  };
  const orderBy =
    q.sort === "price_asc" ? { price: "asc" } : q.sort === "price_desc" ? { price: "desc" } : { createdAt: "desc" };

  const [items, total] = await Promise.all([
    db.product.findMany({ where, orderBy, skip: (q.page - 1) * q.limit, take: q.limit, include: { images: { orderBy: { sort: "asc" }, take: 1 } } }),
    db.product.count({ where }),
  ]);
  res.json({ items, total, page: q.page, pages: Math.ceil(total / q.limit) });
}));

r.get("/:slug", ah(async (req, res) => {
  const p = await db.product.findUnique({ where: { slug: req.params.slug }, include: { images: { orderBy: { sort: "asc" } }, category: true } });
  if (!p || !p.isActive) throw new HttpError(404, "Product not found");
  res.json(p);
}));

// ---------- Admin ----------
const productBody = z.object({
  code: z.string(), name: z.string(), description: z.string().optional(),
  price: z.coerce.number().int().positive(), stock: z.coerce.number().int().min(0).default(0),
  categoryId: z.string(), jewelleryType: z.string(),
  tryOnEnabled: z.coerce.boolean().default(true), isNewArrival: z.coerce.boolean().default(false),
  isActive: z.coerce.boolean().default(true), style: z.string().optional(), colour: z.string().optional(),
});

r.post("/", requireAdmin, upload.fields([{ name: "images", maxCount: 8 }, { name: "tryOnAsset", maxCount: 1 }]), ah(async (req, res) => {
  const b = productBody.parse(req.body);
  const files = req.files as Record<string, Express.Multer.File[]>;
  const p = await db.product.create({
    data: {
      ...b, slug: `${slugify(b.name)}-${b.code.toLowerCase()}`,
      tryOnAssetUrl: files?.tryOnAsset?.[0] ? fileUrl(files.tryOnAsset[0].filename) : undefined,
      images: { create: (files?.images ?? []).map((f, i) => ({ url: fileUrl(f.filename), sort: i })) },
    },
    include: { images: true },
  });
  res.status(201).json(p);
}));

r.put("/:id", requireAdmin, upload.fields([{ name: "images", maxCount: 8 }, { name: "tryOnAsset", maxCount: 1 }]), ah(async (req, res) => {
  const b = productBody.partial().parse(req.body);
  const files = req.files as Record<string, Express.Multer.File[]>;
  const p = await db.product.update({
    where: { id: req.params.id },
    data: {
      ...b,
      ...(files?.tryOnAsset?.[0] && { tryOnAssetUrl: fileUrl(files.tryOnAsset[0].filename) }),
      ...(files?.images?.length && { images: { create: files.images.map((f, i) => ({ url: fileUrl(f.filename), sort: 100 + i })) } }),
    },
    include: { images: true },
  });
  res.json(p);
}));

r.delete("/:id/images/:imageId", requireAdmin, ah(async (req, res) => {
  await db.productImage.delete({ where: { id: req.params.imageId } });
  res.status(204).end();
}));

r.delete("/:id", requireAdmin, ah(async (req, res) => {
  await db.product.update({ where: { id: req.params.id }, data: { isActive: false } }); // soft delete keeps order history
  res.status(204).end();
}));

export default r;