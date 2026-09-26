import { Router } from "express";
import { z } from "zod";
import { db } from "../../config/db";
import { ah } from "../../middleware/error";
import { requireAdmin } from "../../middleware/auth";

const r = Router();
const slugify = (s: string) => s.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-");

r.get("/", ah(async (_req, res) => {
  res.json(await db.category.findMany({ orderBy: { sort: "asc" }, include: { _count: { select: { products: true } } } }));
}));

r.post("/", requireAdmin, ah(async (req, res) => {
  const b = z.object({ name: z.string(), imageUrl: z.string().optional(), sort: z.number().optional() }).parse(req.body);
  res.status(201).json(await db.category.create({ data: { ...b, slug: slugify(b.name) } }));
}));

r.put("/:id", requireAdmin, ah(async (req, res) => {
  const b = z.object({ name: z.string().optional(), imageUrl: z.string().optional(), sort: z.number().optional() }).parse(req.body);
  res.json(await db.category.update({ where: { id: req.params.id }, data: { ...b, ...(b.name && { slug: slugify(b.name) }) } }));
}));

r.delete("/:id", requireAdmin, ah(async (req, res) => {
  await db.category.delete({ where: { id: req.params.id } });
  res.status(204).end();
}));

export default r;