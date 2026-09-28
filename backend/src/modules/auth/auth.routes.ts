import { Router } from "express";
import bcrypt from "bcryptjs";
import { z } from "zod";
import { db } from "../../config/db";
import { ah, HttpError } from "../../middleware/error";
import { requireAuth, signToken } from "../../middleware/auth";

const r = Router();
const publicUser = { id: true, name: true, email: true, phone: true, role: true } as const;
const phone = z.string().regex(/^0\d{9}$/, "Use a mobile number like 07XXXXXXXX").optional().or(z.literal("").transform(() => undefined));

r.post("/register", ah(async (req, res) => {
  const b = z.object({ name: z.string().trim().min(2), email: z.string().trim().toLowerCase().email(), phone, password: z.string().min(6) }).parse(req.body);
  if (await db.user.findUnique({ where: { email: b.email } })) throw new HttpError(409, "An account with this email already exists. Sign in instead.");
  const u = await db.user.create({ data: { ...b, password: await bcrypt.hash(b.password, 10) }, select: publicUser });
  res.status(201).json({ token: signToken({ id: u.id, role: u.role }), user: u });
}));

r.post("/login", ah(async (req, res) => {
  const b = z.object({ email: z.string().trim().toLowerCase().email(), password: z.string() }).parse(req.body);
  const u = await db.user.findUnique({ where: { email: b.email } });
  if (!u || !(await bcrypt.compare(b.password, u.password))) throw new HttpError(401, "Wrong email or password.");
  res.json({ token: signToken({ id: u.id, role: u.role }), user: { id: u.id, name: u.name, email: u.email, phone: u.phone, role: u.role } });
}));

r.get("/me", requireAuth, ah(async (req, res) => {
  const u = await db.user.findUnique({ where: { id: req.user!.id }, select: publicUser });
  if (!u) throw new HttpError(401, "Sign in required");
  res.json(u);
}));

r.patch("/me", requireAuth, ah(async (req, res) => {
  const b = z.object({ name: z.string().trim().min(2).optional(), phone }).parse(req.body);
  res.json(await db.user.update({ where: { id: req.user!.id }, data: { name: b.name, phone: b.phone ?? null }, select: publicUser }));
}));

r.post("/password", requireAuth, ah(async (req, res) => {
  const b = z.object({ current: z.string(), next: z.string().min(6, "New password needs at least 6 characters") }).parse(req.body);
  const u = await db.user.findUnique({ where: { id: req.user!.id } });
  if (!u || !(await bcrypt.compare(b.current, u.password))) throw new HttpError(400, "Current password is wrong.");
  await db.user.update({ where: { id: u.id }, data: { password: await bcrypt.hash(b.next, 10) } });
  res.status(204).end();
}));

export default r;
