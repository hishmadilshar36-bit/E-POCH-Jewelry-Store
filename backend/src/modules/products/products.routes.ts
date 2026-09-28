import { Router } from "express";
import { z } from "zod";
import { Prisma, JewelleryType } from "@prisma/client";
import { db } from "../../config/db";
import { ah, HttpError } from "../../middleware/error";
import { requireAdmin } from "../../middleware/auth";
import { upload, fileUrl } from "../../middleware/upload";
import { getActiveOffers, priceFor, withPricing } from "../../services/pricing";

const r = Router();
const slugify = (s: string) => s.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
const firstImage = { images: { orderBy: { sort: "asc" as const }, take: 1 } };

// GET /api/products?ids=a,b&category=earrings&q=&minPrice=&maxPrice=&style=&colour=&inStock=1&newArrivals=1&onSale=1&type=EARRINGS&sort=price_asc&page=1
r.get("/", ah(async (req, res) => {
  const q = z.object({
    category: z.string().optional(), q: z.string().optional(),
    minPrice: z.coerce.number().optional(), maxPrice: z.coerce.number().optional(),
    style: z.string().optional(), colour: z.string().optional(),
    inStock: z.string().optional(), newArrivals: z.string().optional(), onSale: z.string().optional(),
    type: z.nativeEnum(JewelleryType).optional(), tryOn: z.string().optional(),
    ids: z.string().optional().transform((v) => (v ? v.split(",").filter(Boolean).slice(0, 20) : undefined)),
    sort: z.enum(["new", "price_asc", "price_desc", "name"]).default("new"),
    page: z.coerce.number().int().min(1).default(1), limit: z.coerce.number().int().min(1).max(60).default(24),
  }).parse(req.query);

  const where: Prisma.ProductWhereInput = {
    isActive: true,
    ...(q.category && { category: { slug: q.category } }),
    ...(q.q && { OR: [{ name: { contains: q.q, mode: "insensitive" } }, { code: { contains: q.q, mode: "insensitive" } }, { description: { contains: q.q, mode: "insensitive" } }] }),
    ...((q.minPrice !== undefined || q.maxPrice !== undefined) && { price: { gte: q.minPrice, lte: q.maxPrice } }),
    ...(q.style && { style: q.style }),
    ...(q.colour && { colour: q.colour }),
    ...(q.inStock && { stock: { gt: 0 } }),
    ...(q.newArrivals && { isNewArrival: true }),
    ...(q.type && { jewelleryType: q.type }),
    ...(q.tryOn && { tryOnEnabled: true }),
    ...(q.ids && { id: { in: q.ids } }),
  };
  const orderBy: Prisma.ProductOrderByWithRelationInput =
    q.sort === "price_asc" ? { price: "asc" } : q.sort === "price_desc" ? { price: "desc" } : q.sort === "name" ? { name: "asc" } : { createdAt: "desc" };

  if (q.onSale) {
    // Offers can target products, categories or the whole shop, so filter after pricing.
    const offers = await getActiveOffers();
    const all = await db.product.findMany({ where, orderBy, include: firstImage });
    const onSale = all.map((p) => ({ ...p, ...priceFor(p, offers) })).filter((p) => p.salePrice !== null);
    const items = onSale.slice((q.page - 1) * q.limit, q.page * q.limit);
    return res.json({ items, total: onSale.length, page: q.page, pages: Math.max(1, Math.ceil(onSale.length / q.limit)) });
  }

  const [items, total] = await Promise.all([
    db.product.findMany({ where, orderBy, skip: (q.page - 1) * q.limit, take: q.limit, include: firstImage }),
    db.product.count({ where }),
  ]);
  res.json({ items: await withPricing(items), total, page: q.page, pages: Math.max(1, Math.ceil(total / q.limit)) });
}));

// Values for the filter panel
r.get("/filters", ah(async (_req, res) => {
  const [styles, colours, range] = await Promise.all([
    db.product.findMany({ where: { isActive: true, style: { not: null } }, distinct: ["style"], select: { style: true }, orderBy: { style: "asc" } }),
    db.product.findMany({ where: { isActive: true, colour: { not: null } }, distinct: ["colour"], select: { colour: true }, orderBy: { colour: "asc" } }),
    db.product.aggregate({ where: { isActive: true }, _min: { price: true }, _max: { price: true } }),
  ]);
  res.json({
    styles: styles.map((s) => s.style).filter(Boolean),
    colours: colours.map((c) => c.colour).filter(Boolean),
    minPrice: range._min.price ?? 0,
    maxPrice: range._max.price ?? 0,
  });
}));

r.get("/:slug", ah(async (req, res) => {
  const p = await db.product.findUnique({ where: { slug: req.params.slug }, include: { images: { orderBy: { sort: "asc" } }, category: true } });
  if (!p || !p.isActive) throw new HttpError(404, "This product isn't available.");
  const [priced] = await withPricing([p]);
  res.json(priced);
}));

r.get("/:slug/related", ah(async (req, res) => {
  const p = await db.product.findUnique({ where: { slug: req.params.slug }, select: { id: true, categoryId: true } });
  if (!p) return res.json([]);
  const items = await db.product.findMany({
    where: { isActive: true, categoryId: p.categoryId, NOT: { id: p.id } },
    orderBy: { createdAt: "desc" }, take: 4, include: firstImage,
  });
  res.json(await withPricing(items));
}));

// ---------- Admin ----------
const bool = z.preprocess((v) => v === true || v === "true" || v === "on" || v === "1", z.boolean());
const productBody = z.object({
  code: z.string().trim().min(1).max(30), name: z.string().trim().min(2).max(120), description: z.string().max(4000).optional(),
  price: z.coerce.number().int().positive(), stock: z.coerce.number().int().min(0).default(0),
  categoryId: z.string().min(1), jewelleryType: z.nativeEnum(JewelleryType),
  tryOnEnabled: bool.default(true), isNewArrival: bool.default(false), isActive: bool.default(true),
  style: z.string().trim().max(40).optional().transform((v) => v || null),
  colour: z.string().trim().max(40).optional().transform((v) => v || null),
});
const files = upload.fields([{ name: "images", maxCount: 10 }, { name: "tryOnAsset", maxCount: 1 }]);

async function assertCodeFree(code: string, exceptId?: string) {
  const clash = await db.product.findFirst({ where: { code, ...(exceptId && { NOT: { id: exceptId } }) } });
  if (clash) throw new HttpError(409, `Product code ${code} is already used by "${clash.name}".`);
}

r.post("/", requireAdmin, files, ah(async (req, res) => {
  const b = productBody.parse(req.body);
  await assertCodeFree(b.code);
  const f = req.files as Record<string, Express.Multer.File[]> | undefined;
  const p = await db.product.create({
    data: {
      ...b, slug: `${slugify(b.name)}-${slugify(b.code)}`,
      tryOnAssetUrl: f?.tryOnAsset?.[0] ? fileUrl(f.tryOnAsset[0].filename) : undefined,
      images: { create: (f?.images ?? []).map((file, i) => ({ url: fileUrl(file.filename), sort: i })) },
    },
    include: { images: true },
  });
  res.status(201).json(p);
}));

r.put("/:id", requireAdmin, files, ah(async (req, res) => {
  const b = productBody.partial().parse(req.body);
  if (b.code) await assertCodeFree(b.code, req.params.id);
  const f = req.files as Record<string, Express.Multer.File[]> | undefined;
  const current = await db.productImage.aggregate({ where: { productId: req.params.id }, _max: { sort: true } });
  const start = (current._max.sort ?? -1) + 1;
  const p = await db.product.update({
    where: { id: req.params.id },
    data: {
      ...b,
      ...(f?.tryOnAsset?.[0] && { tryOnAssetUrl: fileUrl(f.tryOnAsset[0].filename) }),
      ...(f?.images?.length && { images: { create: f.images.map((file, i) => ({ url: fileUrl(file.filename), sort: start + i })) } }),
    },
    include: { images: { orderBy: { sort: "asc" } } },
  });
  res.json(p);
}));

// Body: { order: [imageId, imageId, ...] } — first becomes the main image
r.put("/:id/images/order", requireAdmin, ah(async (req, res) => {
  const { order } = z.object({ order: z.array(z.string()) }).parse(req.body);
  await db.$transaction(order.map((id, i) => db.productImage.updateMany({ where: { id, productId: req.params.id }, data: { sort: i } })));
  res.status(204).end();
}));

r.delete("/:id/images/:imageId", requireAdmin, ah(async (req, res) => {
  await db.productImage.deleteMany({ where: { id: req.params.imageId, productId: req.params.id } });
  res.status(204).end();
}));

r.delete("/:id/try-on-asset", requireAdmin, ah(async (req, res) => {
  await db.product.update({ where: { id: req.params.id }, data: { tryOnAssetUrl: null } });
  res.status(204).end();
}));

// Hiding keeps order history intact; the product can be shown again from the edit form.
r.delete("/:id", requireAdmin, ah(async (req, res) => {
  await db.product.update({ where: { id: req.params.id }, data: { isActive: false } });
  res.status(204).end();
}));

export default r;
