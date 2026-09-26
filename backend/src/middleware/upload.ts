import multer from "multer";
import path from "path";
import fs from "fs";
import { env } from "../config/env";

fs.mkdirSync(env.uploadDir, { recursive: true });
export const upload = multer({
  storage: multer.diskStorage({
    destination: env.uploadDir,
    filename: (_r, f, cb) => cb(null, `${Date.now()}-${Math.round(Math.random() * 1e9)}${path.extname(f.originalname)}`),
  }),
  limits: { fileSize: 8 * 1024 * 1024 },
  fileFilter: (_r, f, cb) => cb(null, /image\/(jpeg|png|webp)/.test(f.mimetype)),
});
export const fileUrl = (filename: string) => `${env.publicUrl}/uploads/${filename}`;