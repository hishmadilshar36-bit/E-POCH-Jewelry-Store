import { ElementType, ReactNode, useEffect, useRef, useState } from "react";

// Fades a block in once when it scrolls into view. CSS skips the effect for visitors
// who prefer reduced motion, so the content is simply shown.
export default function Reveal({ as: Tag = "div", index = 0, className = "", children, ...rest }: {
  as?: ElementType; index?: number; className?: string; children: ReactNode; [key: string]: unknown;
}) {
  const ref = useRef<HTMLElement>(null);
  const [shown, setShown] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    if (typeof IntersectionObserver === "undefined") { setShown(true); return; }
    const io = new IntersectionObserver((entries) => {
      if (entries.some((e) => e.isIntersecting)) { setShown(true); io.disconnect(); }
    }, { rootMargin: "0px 0px -10% 0px" });
    io.observe(el);
    return () => io.disconnect();
  }, []);

  return (
    <Tag ref={ref} className={`reveal ${shown ? "is-in" : ""} ${className}`} style={{ "--i": index } as React.CSSProperties} {...rest}>
      {children}
    </Tag>
  );
}
