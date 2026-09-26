import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { env } from "../config/env";

export type AuthUser = { id: string; role: "CUSTOMER" | "ADMIN" };
declare global { namespace Express { interface Request { user?: AuthUser } } }

export const signToken = (u: AuthUser) => jwt.sign(u, env.jwtSecret, { expiresIn: "7d" });

export function optionalAuth(req: Request, _res: Response, next: NextFunction) {
  const t = req.headers.authorization?.replace("Bearer ", "");
  if (t) try { req.user = jwt.verify(t, env.jwtSecret) as AuthUser; } catch {}
  next();
}
export function requireAuth(req: Request, res: Response, next: NextFunction) {
  optionalAuth(req, res, () => (req.user ? next() : res.status(401).json({ error: "Sign in required" })));
}
export function requireAdmin(req: Request, res: Response, next: NextFunction) {
  requireAuth(req, res, () => (req.user?.role === "ADMIN" ? next() : res.status(403).json({ error: "Admin only" })));
}