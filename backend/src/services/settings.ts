import { db } from "../config/db";

// The shop has one settings row (id = 1). It is created with defaults the first time it is read.
export const getSettings = () => db.shopSettings.upsert({ where: { id: 1 }, update: {}, create: { id: 1 } });

export function deliveryFeeFor(settings: { deliveryFee: number; freeDeliveryOver: number | null }, subtotal: number) {
  if (settings.freeDeliveryOver && subtotal >= settings.freeDeliveryOver) return 0;
  return settings.deliveryFee;
}
