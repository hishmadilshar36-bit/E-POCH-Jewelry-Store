import { lkr } from "../api/format";

// One series of bars (sales per period). Hover or focus a bar to see its value; a hidden table
// gives screen readers the same numbers.
type Bar = { key: string; label: string; fullLabel: string; value: number; orders: number; highlight?: boolean };

const short = (n: number) => (n >= 1_000_000 ? `${Math.round(n / 100_000) / 10}M` : n >= 1000 ? `${Math.round(n / 100) / 10}k` : String(n));

export default function BarChart({ bars, caption, height = 240 }: { bars: Bar[]; caption: string; height?: number }) {
  const max = Math.max(...bars.map((b) => b.value), 1);
  const dense = bars.length > 14;
  return (
    <>
      <div className={`bars ${dense ? "bars-dense" : ""}`} style={{ height, gridTemplateColumns: `repeat(${bars.length}, minmax(0, 1fr))` }}
        role="img" aria-label={`${caption}. Values are in the table that follows.`}>
        <div className="bars-grid" aria-hidden="true">
          <span>{short(max)}</span>
          <span>{short(Math.round(max / 2))}</span>
          <span>0</span>
        </div>
        {bars.map((b, i) => (
          <div key={b.key} className="bar-col" tabIndex={0} aria-label={`${b.fullLabel}: ${lkr(b.value)}, ${b.orders} orders`}>
            <div className="bar-track">
              <div className={`bar ${b.highlight ? "is-highlight" : ""}`} style={{ height: `${(b.value / max) * 100}%` }} />
              <div className={`bar-tip ${i > bars.length * 0.7 ? "tip-left" : i < bars.length * 0.3 ? "tip-right" : ""}`} role="tooltip">
                <strong>{lkr(b.value)}</strong>
                <span>{b.orders} {b.orders === 1 ? "order" : "orders"} · {b.fullLabel}</span>
              </div>
            </div>
            <span className="bar-label">{dense && i % 5 !== 0 && i !== bars.length - 1 ? "" : b.label}</span>
          </div>
        ))}
      </div>
      <div className="sr-only">
        <table>
          <caption>{caption}</caption>
          <thead><tr><th>Period</th><th>Sales</th><th>Orders</th></tr></thead>
          <tbody>{bars.map((b) => <tr key={b.key}><td>{b.fullLabel}</td><td>{lkr(b.value)}</td><td>{b.orders}</td></tr>)}</tbody>
        </table>
      </div>
    </>
  );
}
