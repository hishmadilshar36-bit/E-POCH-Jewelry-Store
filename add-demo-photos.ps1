# E-POCH Jewelry Store - adds demo products with photos.
# Save in C:\E-POCH-Jewelry-Store-main, then run:
#   powershell -ExecutionPolicy Bypass -File .\add-demo-photos.ps1

$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)
if (-not (Test-Path (Join-Path $here 'backend'))) { Write-Host 'Put this script in the folder that contains backend and frontend, then run it again.'; exit 1 }
function Write-ProjectFile($rel, $content) {
  $path = Join-Path $here $rel
  $dir = Split-Path $path -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
  [System.IO.File]::WriteAllText($path, (($content -replace "`r`n", "`n") + "`n"), $utf8)
}

Write-ProjectFile 'backend\package.json' @'
{
  "name": "jewellery-backend",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "seed": "tsx prisma/seed.ts",
    "seed:demo": "tsx prisma/seed-demo.ts"
  },
  "dependencies": {
    "@prisma/client": "^5.20.0",
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.21.0",
    "jsonwebtoken": "^9.0.2",
    "multer": "^1.4.5-lts.1",
    "zod": "^3.23.8"
  },
  "devDependencies": {
    "@types/bcryptjs": "^2.4.6",
    "@types/cors": "^2.8.17",
    "@types/express": "^4.17.21",
    "@types/jsonwebtoken": "^9.0.7",
    "@types/multer": "^1.4.12",
    "@types/node": "^22.7.0",
    "prisma": "^5.20.0",
    "tsx": "^4.19.0",
    "typescript": "^5.6.0"
  }
}
'@

Write-ProjectFile 'backend\prisma\seed-demo.ts' @'
// Demo products with real photos so the shop looks complete while you set it up.
//   npm run seed:demo            add (or refresh) the demo products, model photos and category images
//   npm run seed:demo -- --remove   take all demo content out again
//
// Photos are free Unsplash photos (https://unsplash.com/license), loaded straight from Unsplash.
// They show jewellery you may not stock, so replace them with your own pieces before you open the shop.
import { PrismaClient, JewelleryType } from "@prisma/client";
const db = new PrismaClient();

const img = (id: string, w = 900) => `https://images.unsplash.com/photo-${id}?w=${w}&q=80&auto=format&fit=crop`;
const PREFIX = "DEMO-";

type Demo = { code: string; name: string; cat: string; type: JewelleryType; price: number; stock: number; style: string; colour: string; photos: string[]; isNew?: boolean; description: string };

const products: Demo[] = [
  { code: "ER01", name: "Temple jhumka earrings", cat: "earrings", type: "EARRINGS", price: 2800, stock: 8, style: "Traditional", colour: "Gold", photos: ["1762686130435-897de4b26aac"], isNew: true, description: "Bell-shaped jhumkas with fine filigree and tiny hanging beads. Lightweight for all-day wear." },
  { code: "ER02", name: "Classic gold drop earrings", cat: "earrings", type: "EARRINGS", price: 3200, stock: 6, style: "Modern", colour: "Gold", photos: ["1727990865600-91f8cb8b0168"], isNew: true, description: "Simple gold-finish drops that work with office wear and sarees alike." },
  { code: "ER03", name: "Ruby kundan earrings", cat: "earrings", type: "EARRINGS", price: 3900, stock: 4, style: "Traditional", colour: "Red", photos: ["1653227907864-560dce4c252d"], isNew: true, description: "Kundan-style studs with deep red stones and a gold frame." },
  { code: "ER04", name: "Two-tone statement earrings", cat: "earrings", type: "EARRINGS", price: 2400, stock: 10, style: "Modern", colour: "Silver", photos: ["1714733831162-0a6e849141be"], description: "Silver and gold tones together for an easy everyday sparkle." },
  { code: "ER05", name: "Pearl drop earrings", cat: "earrings", type: "EARRINGS", price: 2100, stock: 12, style: "Modern", colour: "Gold", photos: ["1701777892740-88419a701472"], description: "Soft pearl drops on a slim gold hook." },
  { code: "BG01", name: "Antique bangle stack", cat: "bangles", type: "BANGLE", price: 4500, stock: 5, style: "Traditional", colour: "Gold", photos: ["1758995116383-f51775896add"], isNew: true, description: "A set of ornate gold-finish bangles to wear together or split." },
  { code: "BG02", name: "Polished gold bangle pair", cat: "bangles", type: "BANGLE", price: 3500, stock: 7, style: "Modern", colour: "Gold", photos: ["1690175867343-2af70ea57537"], description: "A smooth, high-shine pair for everyday wear." },
  { code: "BG03", name: "Textured inlay bangles", cat: "bangles", type: "BANGLE", price: 3800, stock: 3, style: "Modern", colour: "Gold", photos: ["1787769499046-8a94b2de1f62"], description: "Hammered gold bangles with dark oval inlays." },
  { code: "BR01", name: "Stone-set tennis bracelet", cat: "bracelets", type: "BRACELET", price: 5200, stock: 4, style: "Modern", colour: "Gold", photos: ["1611598935678-c88dca238fce"], isNew: true, description: "A line of sparkling stones set in gold for special occasions." },
  { code: "BR02", name: "Beaded charm bracelets", cat: "bracelets", type: "BRACELET", price: 1900, stock: 15, style: "Modern", colour: "Gold", photos: ["1626784215013-13322cb0e471"], description: "Mix-and-match beaded bracelets in gold and silver tones." },
  { code: "CH01", name: "Everyday gold chain", cat: "chains", type: "CHAIN", price: 4200, stock: 9, style: "Modern", colour: "Gold", photos: ["1611107683227-e9060eccd846"], isNew: true, description: "A fine gold-finish chain to wear alone or with a pendant." },
  { code: "CH02", name: "Heart pendant chain", cat: "chains", type: "CHAIN", price: 3600, stock: 6, style: "Modern", colour: "Gold", photos: ["1623321673989-830eff0fd59f"], description: "A delicate chain with a small gold heart charm." },
  { code: "NK01", name: "Amethyst bead necklace", cat: "necklaces", type: "NECKLACE", price: 6800, stock: 3, style: "Traditional", colour: "Purple", photos: ["1601121141461-9d6647bca1ed"], isNew: true, description: "Gold beads with purple stones in a classic collar shape." },
  { code: "NK02", name: "Ruby bead necklace", cat: "necklaces", type: "NECKLACE", price: 7200, stock: 4, style: "Traditional", colour: "Red", photos: ["1600862754152-80a263dd564f"], description: "Rich red beads strung with gold spacers." },
  { code: "NK03", name: "Pearl and gold necklace", cat: "necklaces", type: "NECKLACE", price: 8500, stock: 2, style: "Traditional", colour: "Gold", photos: ["1721103418312-b0057a8c31c2"], description: "Layers of pearls framed in gold for weddings and festivals." },
  { code: "NK04", name: "Gold bead collar necklace", cat: "necklaces", type: "NECKLACE", price: 5900, stock: 5, style: "Modern", colour: "Gold", photos: ["1599475211349-f4c81b3216bc"], description: "Rounded gold and white beads in a short collar length." },
  { code: "LC01", name: "Long layered chain", cat: "long-chains", type: "LONG_CHAIN", price: 7500, stock: 4, style: "Traditional", colour: "Gold", photos: ["1705326454924-f6777522b030"], description: "A long statement chain that falls to mid-chest." },
  { code: "RG01", name: "Diamond-cut cocktail ring", cat: "rings", type: "RING", price: 2600, stock: 8, style: "Modern", colour: "Gold", photos: ["1611955167811-4711904bb9f8"], description: "A bright cluster of stones on a slim gold band." },
  { code: "RG02", name: "Amethyst solitaire ring", cat: "rings", type: "RING", price: 2900, stock: 5, style: "Traditional", colour: "Purple", photos: ["1603561596973-8166e9e089d1"], description: "A single purple stone in a raised gold setting." },
  { code: "RG03", name: "Stone-studded band", cat: "rings", type: "RING", price: 2300, stock: 9, style: "Modern", colour: "Gold", photos: ["1626784213922-d9f1e050cf8f"], description: "A comfortable band set with small sparkling stones." },
  { code: "AN01", name: "Gold chain anklet", cat: "anklets", type: "ANKLET", price: 1500, stock: 12, style: "Modern", colour: "Gold", photos: ["1744722091259-ed1cf11ac97f"], description: "A fine chain anklet for everyday wear." },
  { code: "BJ01", name: "Bridal necklace and earring set", cat: "bridal-jewellery", type: "NECKLACE", price: 18500, stock: 2, style: "Traditional", colour: "Gold", photos: ["1722410180687-b05b50922362"], isNew: true, description: "A matching bridal necklace and earrings for the big day." },
  { code: "HA01", name: "Jewelled tiara", cat: "hair-accessories", type: "HAIR", price: 6500, stock: 3, style: "Traditional", colour: "Purple", photos: ["1603974372039-adc49044b6bd"], description: "A gold tiara set with purple stones for brides and special events." },
  { code: "FJ01", name: "Party jewellery trio", cat: "fancy-jewellery", type: "OTHER", price: 2200, stock: 7, style: "Modern", colour: "Gold", photos: ["1641290748359-1d944fc8359a"], description: "Three easy pieces to dress up any outfit." },
];

const categoryPhotos: Record<string, string> = {
  earrings: "1762686130435-897de4b26aac", bangles: "1758995116383-f51775896add", chains: "1611107683227-e9060eccd846",
  "long-chains": "1705326454924-f6777522b030", necklaces: "1601121141461-9d6647bca1ed", rings: "1611955167811-4711904bb9f8",
  bracelets: "1611598935678-c88dca238fce", anklets: "1744722091259-ed1cf11ac97f", "bridal-jewellery": "1722410180687-b05b50922362",
  "hair-accessories": "1603974372039-adc49044b6bd", "fancy-jewellery": "1641290748359-1d944fc8359a",
};

const models = [
  { name: "Demo model 1", photo: "1763578590148-fbac0711f3b2" },
  { name: "Demo model 2", photo: "1779475546066-742c9a580de1" },
  { name: "Demo model 3", photo: "1688382654723-a7366006519b" },
  { name: "Demo model 4", photo: "1620656798579-1984d9e87df7" },
];

const slugify = (s: string) => s.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");

async function add() {
  let added = 0, skipped = 0;
  for (const p of products) {
    const cat = await db.category.findUnique({ where: { slug: p.cat } });
    if (!cat) { console.warn(`Skipped ${p.name}: category "${p.cat}" not found. Run npm run seed first.`); skipped++; continue; }
    const code = PREFIX + p.code;
    const data = {
      name: p.name, description: p.description, price: p.price, stock: p.stock, style: p.style, colour: p.colour,
      jewelleryType: p.type, categoryId: cat.id, isActive: true, isNewArrival: !!p.isNew, tryOnEnabled: true,
    };
    const product = await db.product.upsert({ where: { code }, update: data, create: { ...data, code, slug: `${slugify(p.name)}-${slugify(code)}` } });
    await db.productImage.deleteMany({ where: { productId: product.id } });
    await db.productImage.createMany({ data: p.photos.map((id, i) => ({ productId: product.id, url: img(id), sort: i })) });
    added++;
  }

  for (const [slug, photo] of Object.entries(categoryPhotos)) {
    await db.category.updateMany({ where: { slug, imageUrl: null }, data: { imageUrl: img(photo, 300) } });
  }

  for (const m of models) {
    const existing = await db.aiModel.findFirst({ where: { name: m.name } });
    if (existing) await db.aiModel.update({ where: { id: existing.id }, data: { imageUrl: img(m.photo, 800), isActive: true } });
    else await db.aiModel.create({ data: { name: m.name, imageUrl: img(m.photo, 800) } });
  }

  const bangles = await db.category.findUnique({ where: { slug: "bangles" } });
  if (bangles && !(await db.offer.findFirst({ where: { title: "Demo offer: bangles week" } }))) {
    const now = new Date();
    await db.offer.create({ data: { title: "Demo offer: bangles week", percentOff: 15, startsAt: now, endsAt: new Date(now.getTime() + 14 * 864e5), categoryId: bangles.id } });
  }

  console.log(`Demo content ready: ${added} products${skipped ? ` (${skipped} skipped)` : ""}, ${models.length} AI models, category photos and one offer.`);
  console.log("Remove it later with: npm run seed:demo -- --remove");
}

async function remove() {
  const demo = await db.product.findMany({ where: { code: { startsWith: PREFIX } }, select: { id: true, _count: { select: { orderItems: true, tryOnItems: true } } } });
  let deleted = 0, hidden = 0;
  for (const p of demo) {
    await db.cartItem.deleteMany({ where: { productId: p.id } });
    await db.wishlistItem.deleteMany({ where: { productId: p.id } });
    if (p._count.orderItems || p._count.tryOnItems) {
      // Keep products that appear in orders or try-ons so history stays intact; just hide them.
      await db.product.update({ where: { id: p.id }, data: { isActive: false } });
      hidden++;
    } else {
      await db.offer.deleteMany({ where: { productId: p.id } });
      await db.product.delete({ where: { id: p.id } });
      deleted++;
    }
  }
  const demoCatUrls = Object.values(categoryPhotos).map((id) => img(id, 300));
  await db.category.updateMany({ where: { imageUrl: { in: demoCatUrls } }, data: { imageUrl: null } });
  for (const m of models) {
    const existing = await db.aiModel.findFirst({ where: { name: m.name }, include: { _count: { select: { tryOns: true } } } });
    if (!existing) continue;
    if (existing._count.tryOns) await db.aiModel.update({ where: { id: existing.id }, data: { isActive: false } });
    else await db.aiModel.delete({ where: { id: existing.id } });
  }
  await db.offer.deleteMany({ where: { title: "Demo offer: bangles week" } });
  console.log(`Demo content removed: ${deleted} products deleted, ${hidden} hidden because they appear in orders or try-ons.`);
}

(process.argv.includes("--remove") ? remove() : add())
  .catch((e) => { console.error("Demo seed failed:", e); process.exit(1); })
  .finally(() => db.$disconnect());
'@

Write-ProjectFile 'frontend\src\pages\Home.tsx' @'
import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../api/client";
import type { Category, Product } from "../api/types";
import { lkr } from "../api/format";
import { useSettings } from "../context/SettingsContext";
import ProductCard from "../components/ProductCard";
import Icon from "../components/Icon";
import JewelIcon from "../components/JewelIcon";
import { ProductImage } from "../components/ui";

function ProductRow({ items, loading, emptyText }: { items: Product[]; loading: boolean; emptyText: string }) {
  if (loading) return <div className="pgrid">{[0, 1, 2, 3].map((i) => <div key={i} className="skeleton skeleton-card" />)}</div>;
  if (!items.length) return <p className="empty-note">{emptyText}</p>;
  return <div className="pgrid">{items.map((p) => <ProductCard key={p.id} p={p} />)}</div>;
}

export default function Home() {
  const s = useSettings();
  const [cats, setCats] = useState<Category[]>([]);
  const [fresh, setFresh] = useState<Product[]>([]);
  const [sale, setSale] = useState<Product[]>([]);
  const [heroPhoto, setHeroPhoto] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      api.categories().then(setCats),
      api.products({ newArrivals: 1, limit: 8 }).then(async (r) => {
        // Fall back to the newest pieces when nothing is marked as a new arrival.
        setFresh(r.items.length ? r.items : (await api.products({ limit: 8 })).items);
      }),
      api.products({ onSale: 1, limit: 4 }).then((r) => setSale(r.items)),
      api.aiModels().then((m) => setHeroPhoto(m[0]?.imageUrl ?? null)),
    ]).catch(() => undefined).finally(() => setLoading(false));
  }, []);

  const heroPick = fresh.find((p) => p.tryOnEnabled) ?? fresh[0];

  return (
    <>
      <section className="hero">
        <div className="hero-inner">
          <div className="hero-copy">
            <h1>Discover your perfect jewellery</h1>
            <p>Earrings, bangles, chains, necklaces, rings and more. See any piece on a model or on your own photo before you order.</p>
            <div className="hero-actions">
              <Link to="/shop" className="btn btn-gold btn-lg">Shop now</Link>
              <Link to={heroPick?.tryOnEnabled ? `/try-on?products=${heroPick.id}` : "/shop?tryOn=1"} className="btn btn-outline-light btn-lg">
                <Icon name="sparkle" size={18} />Try it on with AI
              </Link>
            </div>
          </div>
          <div className="hero-visual" aria-hidden={!heroPick}>
            <div className="hero-arch">
              {heroPhoto || heroPick?.images[0] ? <img src={heroPhoto ?? heroPick!.images[0].url} alt="" /> : <JewelIcon type={heroPick?.jewelleryType ?? "EARRINGS"} size={140} strokeWidth={1} />}
            </div>
            <span className="hero-chip"><Icon name="sparkle" size={14} />AI preview</span>
            {heroPick && (
              <Link to={`/product/${heroPick.slug}`} className="hero-card">
                <span className="hero-card-img"><ProductImage url={heroPick.images[0]?.url} alt="" type={heroPick.jewelleryType} iconSize={34} /></span>
                <span>
                  <span className="hero-card-name">{heroPick.name}</span><br />
                  <span className="muted">{lkr(heroPick.salePrice ?? heroPick.price)}</span>
                </span>
              </Link>
            )}
          </div>
        </div>
      </section>

      <section className="home-section" aria-labelledby="cat-title">
        <div className="section-head">
          <h2 id="cat-title">Shop by category</h2>
          <Link to="/shop">View all</Link>
        </div>
        <div className="cat-grid">
          {cats.map((c) => (
            <Link key={c.id} to={`/shop/${c.slug}`} className="cat-tile">
              <span className="cat-circle">{c.imageUrl ? <img src={c.imageUrl} alt="" /> : <JewelIcon slug={c.slug} size={52} />}</span>
              <span className="cat-name">{c.name}</span>
            </Link>
          ))}
        </div>
      </section>

      <section className="home-section" aria-labelledby="new-title">
        <div className="section-head">
          <h2 id="new-title">New arrivals</h2>
          <Link to="/shop?newArrivals=1">See all new pieces</Link>
        </div>
        <ProductRow items={fresh} loading={loading} emptyText="New pieces are on their way. Check back soon." />
      </section>

      {sale.length > 0 && (
        <section className="home-section" aria-labelledby="sale-title">
          <div className="section-head">
            <h2 id="sale-title">On offer now</h2>
            <Link to="/shop?onSale=1">See all offers</Link>
          </div>
          <ProductRow items={sale} loading={false} emptyText="" />
        </section>
      )}

      <section className="home-section" aria-labelledby="look-title">
        <div className="look-band" style={{ marginTop: 8 }}>
          <div className="look-copy">
            <h2 id="look-title">Create your look</h2>
            <p>Pick earrings, a necklace and bangles, then see the whole set on an AI model before you order. Mix any pieces you like.</p>
            <Link to="/build-look" className="btn btn-primary btn-lg">Start your look</Link>
          </div>
          <ol className="look-steps">
            <li className="look-step"><span className="look-step-num">1</span><span className="look-step-art"><JewelIcon type="EARRINGS" size={46} /></span><span className="look-step-name">Choose earrings</span></li>
            <li className="look-step"><span className="look-step-num">2</span><span className="look-step-art"><JewelIcon type="NECKLACE" size={46} /></span><span className="look-step-name">Choose a necklace</span></li>
            <li className="look-step"><span className="look-step-num">3</span><span className="look-step-art"><JewelIcon type="BANGLE" size={46} /></span><span className="look-step-name">Choose bangles</span></li>
            <li className="look-step look-step-final"><span className="look-step-num"><Icon name="sparkle" size={16} /></span><span className="look-step-art"><Icon name="model" size={40} /></span><span className="look-step-name">See it on with AI</span></li>
          </ol>
        </div>
      </section>

      <section className="trust" aria-label="Why shop with us">
        <div className="trust-item"><span className="trust-icon"><Icon name="truck" /></span><span><strong>Islandwide delivery</strong><span>{s.freeDeliveryOver ? `Free over ${lkr(s.freeDeliveryOver)}, otherwise ${lkr(s.deliveryFee)}` : `Delivered to your door for ${lkr(s.deliveryFee)}`}</span></span></div>
        {s.codEnabled && <div className="trust-item"><span className="trust-icon"><Icon name="cash" /></span><span><strong>Cash on delivery</strong><span>{s.bankEnabled ? "Or pay by bank transfer" : "Pay when it arrives"}</span></span></div>}
        <div className="trust-item"><span className="trust-icon"><Icon name="chat" /></span><span><strong>Help on WhatsApp</strong><span>Ask about any piece or order</span></span></div>
        {s.pickupEnabled && <div className="trust-item"><span className="trust-icon"><Icon name="store" /></span><span><strong>Store pickup</strong><span>{s.address ? `Collect from ${s.address}` : "Collect from our shop"}</span></span></div>}
      </section>
    </>
  );
}
'@

Write-Host 'Updated 3 files.'
Write-Host 'Next, in backend:  npm run seed:demo'
