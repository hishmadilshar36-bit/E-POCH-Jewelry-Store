import { db } from "../../config/db";
import { aiProvider } from "./provider";

// Simple DB-polling queue. Swap for BullMQ + Redis when traffic grows.
let running = false;
let lastError = "";

async function processNext() {
  const job = await db.tryOn.findFirst({
    where: { status: "PENDING" }, orderBy: { createdAt: "asc" },
    include: { items: { include: { product: { include: { images: { take: 1, orderBy: { sort: "asc" } } } } } } },
  });
  if (!job) return false;

  const claimed = await db.tryOn.updateMany({ where: { id: job.id, status: "PENDING" }, data: { status: "PROCESSING" } });
  if (!claimed.count) return true;

  try {
    const resultUrl = await aiProvider.generate({
      personImageUrl: job.inputUrl,
      items: job.items.map((i) => ({ imageUrl: i.product.tryOnAssetUrl ?? i.product.images[0]?.url ?? "", type: i.product.jewelleryType })),
    });
    await db.tryOn.update({ where: { id: job.id }, data: { status: "DONE", resultUrl } });
  } catch (e) {
    await db.tryOn.update({ where: { id: job.id }, data: { status: "FAILED", error: String(e).slice(0, 500) } });
  }
  return true;
}

export function startTryOnWorker(intervalMs = 1500) {
  setInterval(async () => {
    if (running) return;
    running = true;
    try {
      while (await processNext());
      lastError = "";
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      if (msg !== lastError) console.error("[tryon worker]", msg);
      lastError = msg;
    } finally {
      running = false;
    }
  }, intervalMs);
}
