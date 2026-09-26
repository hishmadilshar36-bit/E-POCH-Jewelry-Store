import "dotenv/config";
import process from "process";
export const env = {
  port: Number(process.env.PORT ?? 4000),
  jwtSecret: process.env.JWT_SECRET ?? "dev",
  uploadDir: process.env.UPLOAD_DIR ?? "uploads",
  publicUrl: process.env.PUBLIC_URL ?? "http://localhost:4000",
  aiProvider: process.env.AI_PROVIDER ?? "mock",
  aiApiKey: process.env.AI_API_KEY ?? "",
  aiEndpoint: process.env.AI_ENDPOINT ?? "",
  deliveryFee: Number(process.env.DELIVERY_FEE ?? 450),
};