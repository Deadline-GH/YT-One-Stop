# MarketPulse V4 — UI Design Specification

## Design Language

**Aesthetic:** Professional quantitative trading terminal — high information density,
dark background, color-coded signals. Not a consumer app. Every pixel earns its place.

**Technology stack:** Electron + React + TradingView Lightweight Charts
**Styling:** Tailwind CSS + custom CSS variables for the dark theme tokens
**Charts:** TradingView Lightweight Charts (candlestick, line, histogram)

---

## Color Palette

| Role | Token | Value |
|---|---|---|
| Background (deep) | `--bg-deep` | `#0d0f14` |
| Background (card) | `--bg-card` | `#13161e` |
| Background (elevated) | `--bg-elevated` | `#1a1d28` |
| Border | `--border` | `#252836` |
| Text primary | `--text-primary` | `#e8eaf0` |
| Text secondary | `--text-muted` | `#6b7280` |
| Profit / Long | `--green` | `#22c55e` |
| Loss / Short | `--red` | `#ef4444` |
| Accent (AI / signal) | `--teal` | `#14b8a6` |
| Warning / ATR | `--amber` | `#f59e0b` |
| Neutral | `--blue` | `#3b82f6` |

---

## Layout — Three-Panel Shell

```
┌─────────────────────────────────────────────────────────────────┐
│  TOP BAR: Session P&L · Win Rate · Open Risk · Latency · Toggle │
├──────────────────┬───────────────────────┬──────────────────────┤
│                  │                       │                      │
│  WATCHLIST /     │   MAIN CHART          │  AGENT PANEL         │
│  APPROVAL CARDS  │   (TradingView LC)    │  (Vibe-Trading       │
│                  │                       │   signal output)     │
│  • Ticker        │   Candlestick +       │                      │
│  • Signal score  │   Bollinger Bands     │  • Reasoning text    │
│  • Confidence %  │                       │  • Confidence score  │
│  • Stop / Target │   Sub-panels:         │  • Stop loss price   │
│  • Approve btn   │   KD · MACD · Vol     │  • ATR value         │
│                  │                       │  • Latency badge     │
│                  ├───────────────────────┤  • Approve / Reject  │
│                  │  INDICATOR STRIP      │                      │
│                  │  RSI · EMA · ATR      │                      │
└──────────────────┴───────────────────────┴──────────────────────┘
│  BOTTOM STATUS BAR: Connection status · Ollama model · OpenD    │
└─────────────────────────────────────────────────────────────────┘
```

---

## Panel 1 — Top Stat Bar
**Reference:** Image 1 (backtesting dashboard top row)

Cards displayed left-to-right:
- **Session Net P&L** — large green/red number, +% below
- **Win Rate** — `W / (W+L)` with win/loss count (e.g. `12W × 8L`)
- **Open Risk** — sum of `(entry - stop_loss) × qty` across active positions
- **Max Drawdown** — session low watermark
- **Profit Factor** — `gross_profit / gross_loss`
- **Autonomous Mode Toggle** — prominent pill switch, red when ON

---

## Panel 2 — Watchlist / Approval Cards
**Reference:** Image 4 (VCP screener card grid)

Each card contains:
```
┌─────────────────────────────────┐
│ AAPL              [🔥 87]       │  ← ticker + signal score badge
│ Apple Inc.        NASDAQ        │
│ $213.40  +1.24%                 │
├─────────────────────────────────┤
│ ATR 0.92x  Vol 1.15x  RSI 64   │
│ Entry  $213.40                  │
│ Stop   $209.80  (-1.7%)        │  ← ATR-based stop
│ Target $221.00  (+3.6%)        │
│ R:R    2.1x                    │
├─────────────────────────────────┤
│ [APPROVE ✓]      [REJECT ✗]    │
└─────────────────────────────────┘
```

Signal score badge colors:
- 70–100: `--green` (fire icon) — Strong signal
- 55–69: `--teal` (eye icon) — Watching
- < 55: `--text-muted` — Weak / informational

**Latency chip:** shown on card if `latency > 5s` (amber), hidden if fresh, card greyed-out if `> 10s` (rejected automatically).

---

## Panel 3 — Main Chart
**Reference:** Images 2/3 (Taiwanese terminal main view)

- **Primary chart:** Candlestick with Bollinger Bands overlay (20,2)
- **Sub-panel 1:** KD (9,3,3) — stochastic
- **Sub-panel 2:** MACD (12,26,9) — histogram + signal line
- **Sub-panel 3:** Volume bars, colored green/red by candle direction

Chart controls (top-right of panel):
- Timeframe pills: `1m · 5m · 15m · 1H · 1D`
- Indicator toggle chips

---

## Panel 4 — Agent Output Panel
**Reference:** Image 2 right column (AI signal + institution data)

Sections stacked vertically:

**Signal Summary**
```
SIGNAL: LONG  ·  AAPL
Confidence:  ████████░░  87%
Reasoning:   "Bollinger squeeze + RSI 64 momentum..."
Created at:  14:23:07.341  (latency: 1.2s ✓)
```

**Risk Block**
```
Entry:      $213.40
Stop Loss:  $209.80   (2× ATR = $1.84)
Target:     $221.00
Position:   50 shares  ($10,670 notional)
```

**AI Probability Gauges** (inspired by the 42/45/13 layout)
```
  UP   ██████████ 52%
  DOWN ████████   42%
  FLAT ██         6%
```

**Approve / Reject** buttons (large, full-width) — only shown when Autonomous Mode is OFF.

---

## Panel 5 — Panic Close Button
**Reference:** Design plan §3.4

- Positioned bottom-right, always visible
- Red, slightly translucent button with skull / emergency icon
- **Requires 1-second long-press** to fire (prevents accidental tap)
- On activation: shows modal listing positions to be closed with quantity and estimated fill
- Confirmation required before executing market sells

---

## Panel 6 — Session Report / Equity Curve (separate tab)
**Reference:** Image 1 (full backtesting dashboard)

A "Session" tab that mirrors the backtest report aesthetic:
- Equity curve (TradingView area chart) with drawdown fill
- Returns table: All / Long / Short breakdown
- Profit structure bar chart (Gross Profit / Gross Loss / Commission / Net P&L)
- P&L distribution histogram
- Risk-adjusted stats: Sharpe, Sortino, Max Runup

---

## Typography

| Usage | Font | Size | Weight |
|---|---|---|---|
| Ticker symbol | `JetBrains Mono` | 16px | 700 |
| Price / P&L | `JetBrains Mono` | 24px | 700 |
| Labels | `Inter` | 11px | 500 |
| Body / reasoning text | `Inter` | 13px | 400 |
| Status chips | `JetBrains Mono` | 11px | 600 |

---

## Glassmorphism Details

Applied to floating panels (Agent Output, Panic Close modal):
```css
background: rgba(19, 22, 30, 0.75);
backdrop-filter: blur(20px) saturate(1.4);
border: 1px solid rgba(255, 255, 255, 0.06);
box-shadow: 0 8px 32px rgba(0, 0, 0, 0.48);
```

Electron `vibrancy` option: `'dark'` on macOS; CSS fallback on Windows.

---

## Phase Gate

This spec is **locked in** but **not implemented** until `verify_baseline.sh` reports all Phase 1 checks passing. Phase 4 (Electron Command Shell) is the implementation target.
