import { JewelleryType } from "@prisma/client";
import { env } from "../../config/env";

export type TryOnRequest = {
  personImageUrl: string;                       // AI model image or customer photo
  items: { imageUrl: string; type: JewelleryType }[];
};
export interface TryOnProvider { generate(req: TryOnRequest): Promise<string /* result image URL */> }

// Where each jewellery type is placed — sent to the AI as guidance.
export const placement: Record<JewelleryType, string> = {
  EARRINGS: "on both earlobes", NECKLACE: "around the neck, resting on the collarbone",
  CHAIN: "around the neck", LONG_CHAIN: "around the neck, hanging to mid-chest",
  BANGLE: "on the wrist", BRACELET: "on the wrist", RING: "on the ring finger",
  ANKLET: "on the ankle", HAIR: "in the hair", OTHER: "where it is naturally worn",
};

export const buildPrompt = (r: TryOnRequest) =>
  "Photorealistic virtual try-on. Keep the person's face, skin tone, pose and background unchanged. Add: " +
  r.items.map((i, n) => `item ${n + 1} ${placement[i.type]}`).join("; ") +
  ". Match lighting and scale; keep the jewellery design exactly as in the reference images.";

class MockProvider implements TryOnProvider {
  async generate(r: TryOnRequest) {
    await new Promise((ok) => setTimeout(ok, 2000));
    return r.personImageUrl; // returns input so the UI flow can be built before the real AI is wired
  }
}

// Generic HTTP provider — adapt body/response to the image-editing API you choose.
class HttpProvider implements TryOnProvider {
  async generate(r: TryOnRequest) {
    const res = await fetch(env.aiEndpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${env.aiApiKey}` },
      body: JSON.stringify({ person_image: r.personImageUrl, reference_images: r.items.map((i) => i.imageUrl), prompt: buildPrompt(r) }),
    });
    if (!res.ok) throw new Error(`AI provider ${res.status}: ${await res.text()}`);
    const data = (await res.json()) as { output_url: string };
    return data.output_url;
  }
}

export const aiProvider: TryOnProvider = env.aiProvider === "http" ? new HttpProvider() : new MockProvider();
