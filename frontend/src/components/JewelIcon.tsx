import type { JewelleryType } from "../api/types";

// Simple line drawings of each kind of jewellery, used for category tiles and image placeholders.
type Kind = "earrings" | "stud" | "bangle" | "chain" | "necklace" | "longchain" | "ring" | "bracelet" | "anklet" | "bridal" | "hair" | "gem";

const shapes: Record<Kind, JSX.Element> = {
  earrings: <><circle cx="24" cy="7" r="3" /><path d="M24 10v6M15 26c0-6 4-10 9-10s9 4 9 10zM16 30h16" /><circle cx="24" cy="38" r="2.5" /></>,
  stud: <><path d="M24 14l8 10-8 10-8-10zM16 24h16" /></>,
  bangle: <><circle cx="24" cy="24" r="16" /><circle cx="24" cy="24" r="11" /></>,
  chain: <><ellipse cx="13" cy="24" rx="8" ry="5" /><ellipse cx="24" cy="24" rx="8" ry="5" /><ellipse cx="35" cy="24" rx="8" ry="5" /></>,
  necklace: <><path d="M8 8c0 16 7 24 16 24s16-8 16-24M20 32l4 8 4-8" /></>,
  longchain: <><path d="M8 6c0 20 7 30 16 30s16-10 16-30M24 36v6" /><circle cx="24" cy="44" r="1.5" /></>,
  ring: <><circle cx="24" cy="30" r="12" /><path d="M18 12l6-6 6 6-6 6z" /></>,
  bracelet: <><ellipse cx="24" cy="24" rx="18" ry="10" /><circle cx="10" cy="22" r="2" /><circle cx="24" cy="34" r="2" /><circle cx="38" cy="22" r="2" /></>,
  anklet: <><path d="M8 20c4 8 28 8 32 0" /><circle cx="16" cy="30" r="2" /><circle cx="24" cy="32" r="2" /><circle cx="32" cy="30" r="2" /></>,
  bridal: <><path d="M24 4v10M24 14l7 8-7 8-7-8zM24 30v6" /><circle cx="24" cy="40" r="2.5" /></>,
  hair: <><path d="M10 30c6-14 22-14 28 0M14 26l-4-6M24 22v-8M34 26l4-6" /><circle cx="24" cy="12" r="2" /></>,
  gem: <><path d="M14 10h20l6 9-16 19L8 19zM8 19h32M20 10l-2 9 6 19 6-19-2-9" /></>,
};

const byType: Record<JewelleryType, Kind> = {
  EARRINGS: "earrings", NECKLACE: "necklace", CHAIN: "chain", LONG_CHAIN: "longchain", BANGLE: "bangle",
  BRACELET: "bracelet", RING: "ring", ANKLET: "anklet", HAIR: "hair", OTHER: "gem",
};

const bySlug = (slug: string): Kind => {
  if (slug.includes("long")) return "longchain";
  if (slug.includes("earring")) return "earrings";
  if (slug.includes("bangle")) return "bangle";
  if (slug.includes("chain")) return "chain";
  if (slug.includes("necklace")) return "necklace";
  if (slug.includes("ring")) return "ring";
  if (slug.includes("bracelet")) return "bracelet";
  if (slug.includes("anklet")) return "anklet";
  if (slug.includes("bridal")) return "bridal";
  if (slug.includes("hair")) return "hair";
  return "gem";
};

type Props = { type?: JewelleryType; slug?: string; size?: number; strokeWidth?: number };

export default function JewelIcon({ type, slug, size = 48, strokeWidth = 1.6 }: Props) {
  const kind = type ? byType[type] : bySlug(slug ?? "");
  return (
    <svg width={size} height={size} viewBox="0 0 48 48" fill="none" stroke="currentColor" strokeWidth={strokeWidth}
      strokeLinecap="round" strokeLinejoin="round" aria-hidden="true" focusable="false">
      {shapes[kind]}
    </svg>
  );
}
