import { Router } from "express";
import bcrypt from "bcryptjs";
import { z } from "zod";
import { db } from "../../config/db";
import { ah, HttpError } from "../../middleware/error";
import { requireAuth, signToken } from "../../middleware/auth";

const r = Router();

r.post("/register", ah(async (req, res) => {
  const b = z.object({ name: z.string().min(2), email: z.string().email(), phone: z.string().optional(), password: z.string().min(6) }).parse(req.body);
  if (await db.user.findUnique({ where: { email: b.email } })) throw new HttpError(409, "Email already registered");
  const u = await db.user.create({ data: { ...b, password: await bcrypt.hash(b.password, 10) } });
  res.status(201).json({ token: signToken({ id: u.id, role: u.role }), user: { id: u.id, name: u.name, role: u.role } });
}));

r.post("/login", ah(async (req, res) => {
  const b = z.object({ email: z.string().email(), password: z.string() }).parse(req.body);
  const u = await db.user.findUnique({ where: { email: b.email } });
  if (!u || !(await bcrypt.compare(b.password, u.password))) throw new HttpError(401, "Wrong email or password");
  res.json({ token: signToken({ id: u.id, role: u.role }), user: { id: u.id, name: u.name, role: u.role } });
}));

r.get("/me", requireAuth, ah(async (req, res) => {
  res.json(await db.user.findUnique({ where: { id: req.user!.id }, select: { id: true, name: true, email: true, phone: true, role: true } }));
}));

export default r;