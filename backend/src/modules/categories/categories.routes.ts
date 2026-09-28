import { Router } from "express";
import { z } from "zod";
import { db } from "../../config/db";
import { ah, HttpError } from "../../middleware/error";
import { requireAdmin } from "../../middleware/auth";
import { upload, fileUrl } from "../../middleware/upload";

const r = Router();
const slugify = (s: string) => s.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");

r.get("/", ah(async (_req, res) => {
  res.json(await db.category.findMany({
    orderBy: [{ sort: "asc" }, { name: "asc" }],
    include: { _count: { select: { products: { where: { isActive: true } } } } },
  }));
}));

// multipart/form-data: name, sort, image?
const body = z.object({ name: z.string().trim().min(1).max(60), sort: z.coerce.number().int().optional() });

r.post("/", requireAdmin, upload.single("image"), ah(async (req, res) => {
  const b = body.parse(req.body);
  const slug = slugify(b.name);
  if (await db.category.findUnique({ where: { slug } })) throw new HttpError(409, "A category with this name already exists.");
  res.status(201).json(await db.category.create({ data: { ...b, slug, imageUrl: req.file ? fileUrl(req.file.filename) : undefined } }));
}));

r.put("/:id", requireAdmin, upload.single("image"), ah(async (req, res) => {
  const b = body.partial().parse(req.body);
  const data: { name?: string; slug?: string; sort?: number; imageUrl?: string } = { ...b };
  if (b.name) {
    data.slug = slugify(b.name);
    const clash = await db.category.findFirst({ where: { slug: data.slug, NOT: { id: req.params.id } } });
    if (clash) throw new HttpError(409, "A category with this name already exists.");
  }
  if (req.file) data.imageUrl = fileUrl(req.file.filename);
  res.json(await db.category.update({ where: { id: req.params.id }, data }));
}));

r.delete("/:id", requireAdmin, ah(async (req, res) => {
  const count = await db.product.count({ where: { categoryId: req.params.id } });
  if (count) throw new HttpError(409, `This category has ${count} product${count === 1 ? "" : "s"}. Move them to another category first.`);
  await db.category.delete({ where: { id: req.params.id } });
  res.status(204).end();
}));

export default r;
