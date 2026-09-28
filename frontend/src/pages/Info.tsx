import { Link } from "react-router-dom";
import { lkr, phoneLink, whatsappLink } from "../api/format";
import { useSettings } from "../context/SettingsContext";
import Icon from "../components/Icon";
import JewelIcon from "../components/JewelIcon";

// Text marked [LIKE THIS] is a placeholder for the shop to replace with its own details.

export function About() {
  const s = useSettings();
  return (
    <div className="page page-narrow">
      <div className="page-head"><h1>About {s.shopName}</h1><p>{s.tagline}</p></div>
      <div className="prose">
        <p>[Tell your story here: when the shop started, who runs it and what kind of jewellery you love to sell.]</p>
        <h2>See it on before you buy</h2>
        <p>Choosing jewellery online is hard when you can't hold it up to yourself. That's why every piece that supports it can be tried on with AI, either on one of our models or on your own photo, before you order.</p>
        <h2>Order your way</h2>
        <p>Pay by cash on delivery or bank transfer, have it delivered anywhere in Sri Lanka, or collect it from our shop. If you have a question about a piece, message us on WhatsApp and we'll help.</p>
        <p><Link to="/shop" className="btn btn-primary">Browse jewellery</Link></p>
      </div>
    </div>
  );
}

export function Contact() {
  const s = useSettings();
  const cards = [
    s.whatsapp && { href: whatsappLink(s.whatsapp, "Hi, I have a question."), icon: "chat" as const, title: "WhatsApp", text: s.whatsapp, external: true },
    s.phone && { href: phoneLink(s.phone), icon: "phone" as const, title: "Call us", text: s.phone },
    s.email && { href: `mailto:${s.email}`, icon: "mail" as const, title: "Email", text: s.email },
  ].filter(Boolean) as { href: string; icon: "chat" | "phone" | "mail"; title: string; text: string; external?: boolean }[];

  return (
    <div className="page page-narrow">
      <div className="page-head"><h1>Contact us</h1><p>Questions about a piece, an order or a custom request? We're happy to help.</p></div>
      <div className="contact-grid">
        {cards.map((c) => (
          <a key={c.title} href={c.href} className="contact-card" {...(c.external ? { target: "_blank", rel: "noreferrer" } : {})}>
            <span className="contact-card-icon"><Icon name={c.icon} /></span>
            <strong>{c.title}</strong><span>{c.text}</span>
          </a>
        ))}
        <div className="contact-card">
          <span className="contact-card-icon"><Icon name="pin" /></span>
          <strong>Visit the shop</strong><span>{s.address || "[Shop address]"}</span>
        </div>
        <div className="contact-card">
          <span className="contact-card-icon"><Icon name="clock" /></span>
          <strong>Opening hours</strong><span>[Days and hours]</span>
        </div>
      </div>
      {!cards.length && <p className="muted" style={{ marginTop: 20 }}>Contact details will appear here once they're added in the admin settings.</p>}
    </div>
  );
}

export function Delivery() {
  const s = useSettings();
  return (
    <div className="page page-narrow">
      <div className="page-head"><h1>Delivery and returns</h1></div>
      <div className="prose">
        <h2>Delivery</h2>
        <p>We deliver anywhere in Sri Lanka for {lkr(s.deliveryFee)}{s.freeDeliveryOver ? `, and free on orders over ${lkr(s.freeDeliveryOver)}` : ""}. Most orders arrive within [X–Y] working days after we confirm them.</p>
        {s.pickupEnabled && <p>Prefer to collect? Choose store pickup at checkout. It's free, and we'll message you when your order is ready{s.address ? ` at ${s.address}` : ""}.</p>}
        <h2>Payment</h2>
        <p>{[s.codEnabled && "cash on delivery", s.bankEnabled && "bank transfer", s.onlineEnabled && "online card payment"].filter(Boolean).join(", ").replace(/^./, (c) => c.toUpperCase())}. For bank transfers, use your order number as the reference and send us the slip on WhatsApp.</p>
        <h2>Returns and exchanges</h2>
        <p>[Your return policy: how many days customers have, what condition items must be in, and which items can't be returned, for example earrings for hygiene reasons.]</p>
        <p>To start a return, <Link to="/contact">contact us</Link> with your order number.</p>
      </div>
    </div>
  );
}

const faqs = [
  { id: "order", q: "How do I place an order?", a: <>Add pieces to your cart and go to checkout. You can order as a guest or sign in. We'll contact you to confirm the order before it's sent.</> },
  { id: "try-on", q: "How does AI try-on work?", a: <>On any piece marked “Try on”, choose an AI model or upload a clear, front-facing photo of yourself. Our AI places the piece where it's worn, for example earrings on the earlobes and necklaces around the neck, and shows you a preview in a few seconds. Previews show how a piece may look; size and colour can vary slightly in real life.</> },
  { id: "photo", q: "What happens to my photo?", a: <>Your photo is only used to create your preview. If you're signed in, the preview is saved to your account so you can see it again.</> },
  { id: "look", q: "Can I try on a full set?", a: <>Yes. Use <Link to="/build-look">Create your look</Link> to pick earrings, a necklace and bangles, then preview them together.</> },
  { id: "track", q: "How do I track my order?", a: <>Go to <Link to="/track">Track your order</Link> and enter your order number and mobile number.</> },
  { id: "pay", q: "How can I pay?", a: <>Cash on delivery or bank transfer. See <Link to="/delivery">Delivery and returns</Link> for details.</> },
];

export function Faq() {
  return (
    <div className="page page-narrow">
      <div className="page-head"><h1>Questions and answers</h1></div>
      <div className="faq">
        {faqs.map((f) => (
          <details key={f.id} id={f.id} open={typeof window !== "undefined" && window.location.hash === `#${f.id}`}>
            <summary>{f.q}<Icon name="chevronDown" /></summary>
            <div>{f.a}</div>
          </details>
        ))}
      </div>
    </div>
  );
}

export function NotFound() {
  return (
    <div className="not-found">
      <span className="not-found-art"><JewelIcon type="OTHER" size={96} strokeWidth={1.2} /></span>
      <h1>Page not found</h1>
      <p>The page you're looking for doesn't exist or has moved.</p>
      <div className="card-actions"><Link to="/" className="btn btn-primary">Go to home</Link><Link to="/shop" className="btn btn-quiet">Browse jewellery</Link></div>
    </div>
  );
}
