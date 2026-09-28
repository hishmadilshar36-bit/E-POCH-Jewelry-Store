import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { env } from "../config/env";
import { db } from "../config/db";

export type AuthUser = { id: string; role: "CUSTOMER" | "ADMIN" };
declare global { namespace Express { interface Request { user?: AuthUser } } }

export const signToken = (u: AuthUser) => jwt.sign(u, env.jwtSecret, { expiresIn: "7d" });

// Reads the login token if there is one. A token for a user that no longer exists
// (for example after the database was reset) is ignored, so the request continues as a guest.
export async function optionalAuth(req: Request, _res: Response, next: NextFunction) {
  const t = req.headers.authorization?.replace("Bearer ", "");
  if (t) {
    try {
      const payload = jwt.verify(t, env.jwtSecret) as AuthUser;
      const u = await db.user.findUnique({ where: { id: payload.id }, select: { id: true, role: true } });
      if (u) req.user = { id: u.id, role: u.role };
    } catch { /* bad or expired token: treat as guest */ }
  }
  next();
}

export function requireAuth(req: Request, res: Response, next: NextFunction) {
  optionalAuth(req, res, () => (req.user ? next() : res.status(401).json({ error: "Sign in required" })));
}

export function requireAdmin(req: Request, res: Response, next: NextFunction) {
  requireAuth(req, res, () => (req.user?.role === "ADMIN" ? next() : res.status(403).json({ error: "Admin only" })));
}
