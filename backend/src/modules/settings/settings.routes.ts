import { Router } from "express";
import { z } from "zod";
import { db } from "../../config/db";
import { ah } from "../../middleware/error";
import { requireAdmin } from "../../middleware/auth";
import { getSettings } from "../../services/settings";

const r = Router();

r.get("/", ah(async (_req, res) => res.json(await getSettings())));

const body = z.object({
  shopName: z.string().min(1).max(80),
  tagline: z.string().max(200),
  phone: z.string().max(30),
  whatsapp: z.string().max(30),
  email: z.string().max(120),
  address: z.string().max(300),
  deliveryFee: z.coerce.number().int().min(0),
  freeDeliveryOver: z.coerce.number().int().min(0).nullable(),
  bankDetails: z.string().max(1000),
  codEnabled: z.boolean(),
  bankEnabled: z.boolean(),
  onlineEnabled: z.boolean(),
  pickupEnabled: z.boolean(),
}).partial();

r.put("/", requireAdmin, ah(async (req, res) => {
  const data = body.parse(req.body);
  await getSettings();
  res.json(await db.shopSettings.update({ where: { id: 1 }, data }));
}));

export default r;
