import express from "express";
import cors from "cors";
import { env } from "./config/env";
import { errorHandler } from "./middleware/error";
import auth from "./modules/auth/auth.routes";
import categories from "./modules/categories/categories.routes";
import products from "./modules/products/products.routes";
import cart from "./modules/cart/cart.routes";
import orders from "./modules/orders/orders.routes";
import tryon from "./modules/tryon/tryon.routes";
import wishlist from "./modules/wishlist/wishlist.routes";
import settings from "./modules/settings/settings.routes";
import admin from "./modules/admin/admin.routes";

export const app = express();
app.use(cors());
app.use(express.json({ limit: "1mb" }));
app.use("/uploads", express.static(env.uploadDir, { maxAge: "7d" }));

app.use("/api/auth", auth);
app.use("/api/categories", categories);
app.use("/api/products", products);
app.use("/api/cart", cart);
app.use("/api/orders", orders);
app.use("/api/tryon", tryon);
app.use("/api/wishlist", wishlist);
app.use("/api/settings", settings);
app.use("/api/admin", admin);

app.get("/api/health", (_req, res) => res.json({ ok: true }));
app.use("/api", (_req, res) => res.status(404).json({ error: "Not found" }));
app.use(errorHandler);
