import { Router } from "express";
import { db } from "../../config/db";
import { ah, HttpError } from "../../middleware/error";
import { requireAuth } from "../../middleware/auth";
import { withPricing } from "../../services/pricing";

const r = Router();
r.use(requireAuth);

r.get("/", ah(async (req, res) => {
  const rows = await db.wishlistItem.findMany({
    where: { userId: req.user!.id, product: { isActive: true } },
    orderBy: { id: "desc" },
    include: { product: { include: { images: { orderBy: { sort: "asc" }, take: 1 } } } },
  });
  res.json(await withPricing(rows.map((w) => w.product)));
}));

r.get("/ids", ah(async (req, res) => {
  const rows = await db.wishlistItem.findMany({ where: { userId: req.user!.id }, select: { productId: true } });
  res.json(rows.map((w) => w.productId));
}));

r.post("/:productId", ah(async (req, res) => {
  const p = await db.product.findUnique({ where: { id: req.params.productId } });
  if (!p || !p.isActive) throw new HttpError(404, "Product not found");
  await db.wishlistItem.upsert({
    where: { userId_productId: { userId: req.user!.id, productId: p.id } },
    update: {},
    create: { userId: req.user!.id, productId: p.id },
  });
  res.status(204).end();
}));

r.delete("/:productId", ah(async (req, res) => {
  await db.wishlistItem.deleteMany({ where: { userId: req.user!.id, productId: req.params.productId } });
  res.status(204).end();
}));

export default r;
