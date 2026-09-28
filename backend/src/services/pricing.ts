import { db } from "../config/db";

type Offerish = { id: string; title: string; percentOff: number; productId: string | null; categoryId: string | null };
type Priceable = { id: string; categoryId: string; price: number };

export type Pricing = { salePrice: number | null; offerPercent: number | null; offerTitle: string | null };

export function getActiveOffers() {
  const now = new Date();
  return db.offer.findMany({
    where: { isActive: true, startsAt: { lte: now }, endsAt: { gte: now } },
    select: { id: true, title: true, percentOff: true, productId: true, categoryId: true },
  });
}

// Best offer wins: product-specific, category-wide or shop-wide.
export function priceFor(p: Priceable, offers: Offerish[]): Pricing {
  let best: Offerish | null = null;
  for (const o of offers) {
    const applies = o.productId ? o.productId === p.id : o.categoryId ? o.categoryId === p.categoryId : true;
    if (applies && (!best || o.percentOff > best.percentOff)) best = o;
  }
  if (!best) return { salePrice: null, offerPercent: null, offerTitle: null };
  return {
    salePrice: Math.round((p.price * (100 - best.percentOff)) / 100),
    offerPercent: best.percentOff,
    offerTitle: best.title,
  };
}

export const unitPrice = (p: Priceable, offers: Offerish[]) => priceFor(p, offers).salePrice ?? p.price;

export async function withPricing<T extends Priceable>(items: T[]): Promise<(T & Pricing)[]> {
  const offers = await getActiveOffers();
  return items.map((p) => ({ ...p, ...priceFor(p, offers) }));
}
