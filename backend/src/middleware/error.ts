import { Request, Response, NextFunction } from "express";
import { ZodError } from "zod";
import { MulterError } from "multer";
import { Prisma } from "@prisma/client";

export class HttpError extends Error { constructor(public status: number, msg: string) { super(msg); } }
export const ah = (fn: (req: Request, res: Response, next: NextFunction) => Promise<unknown>) =>
  (req: Request, res: Response, next: NextFunction) => fn(req, res, next).catch(next);

export function errorHandler(err: unknown, _req: Request, res: Response, _next: NextFunction) {
  if (err instanceof ZodError) {
    const first = err.issues[0];
    const field = first?.path.join(".");
    const message = first?.message && first.message !== "Required" ? first.message : `Check the ${field || "form"} field`;
    return res.status(400).json({ error: message, field, details: err.flatten() });
  }
  if (err instanceof HttpError) return res.status(err.status).json({ error: err.message });
  if (err instanceof MulterError) {
    return res.status(400).json({ error: err.code === "LIMIT_FILE_SIZE" ? "That image is over 8 MB. Choose a smaller one." : "That upload didn't work. Try another image." });
  }
  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    if (err.code === "P2025") return res.status(404).json({ error: "That item no longer exists." });
    if (err.code === "P2002") return res.status(409).json({ error: "That value is already in use." });
  }
  console.error(err);
  res.status(500).json({ error: "Something went wrong on our side. Try again." });
}
