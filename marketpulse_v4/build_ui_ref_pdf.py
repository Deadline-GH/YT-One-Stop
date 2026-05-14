#!/usr/bin/env python3
"""Generates marketpulse_v4/UI_REFERENCE.pdf from the four design screenshots."""
import os
from pathlib import Path

from PIL import Image as PILImage
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm, mm
from reportlab.platypus import (
    Image, PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle,
)
from reportlab.lib.enums import TA_LEFT, TA_CENTER

# ── Paths ─────────────────────────────────────────────────────────────────────
UPLOAD_DIR = Path("/root/.claude/uploads/5a88cf53-d2d8-499f-871a-dbb6ed3b2f4a")
OUT_PATH   = Path(__file__).parent / "UI_REFERENCE.pdf"

IMAGES = [
    (
        UPLOAD_DIR / "16487953-1000085996.jpg",
        "Image 1 — Backtesting / Performance Dashboard",
        (
            "Target aesthetic for the Session Report tab. Note the top stat bar "
            "(Net P&L, Max DD, Win Rate, Profit Factor), equity curve with drawdown "
            "fill, profit structure horizontal bars, and P&L distribution histogram. "
            "Dark cards with tight typography — every number is actionable."
        ),
        [
            "Top stat bar → our Session P&L / Win Rate / Open Risk bar",
            "Equity curve → TradingView Lightweight Charts area series + DD fill",
            "Returns table (All / Long / Short) → Session Report tab breakdown",
            "P&L distribution histogram → end-of-session analytics panel",
        ],
    ),
    (
        UPLOAD_DIR / "15654371-1000084584.jpg",
        "Image 2 — Dense Multi-Panel Trading Terminal (main view)",
        (
            "Inspiration for the primary trading view. Three-column layout: "
            "candlestick chart with Bollinger Bands (left), KD + MACD sub-panels "
            "(center), and a right column with technical summary text, institution "
            "flow tables, AI signal badge (green '安全' = Safe, 76% win-rate gauge), "
            "and AI probability bars (Up 42% / Down 45% / Volatile 13%)."
        ),
        [
            "Candlestick + Bollinger Bands → main TradingView chart panel",
            "KD / MACD / Volume sub-panels → indicator strip below main chart",
            "Right-column AI signal badge → Agent Output panel confidence gauge",
            "Up/Down/Flat % bars → probability gauges in Agent Output panel",
            "Technical summary text → agent reasoning text block",
        ],
    ),
    (
        UPLOAD_DIR / "7637dfa0-1000084518.jpg",
        "Image 3 — Same Terminal (smaller / mobile view)",
        (
            "The same terminal at a compressed scale — useful reference for how the "
            "layout degrades gracefully when the Electron window is resized or when "
            "building the React Native mobile shell in Phase 5 (Android app)."
        ),
        [
            "Compact layout → responsive breakpoints for narrow Electron windows",
            "Main signal badge + % score stays prominent even at small size",
            "Guidance for the MarketPulse Mobile (Android) condensed layout",
        ],
    ),
    (
        UPLOAD_DIR / "d0dba980-1000086105.jpg",
        "Image 4 — VCP-Style Stock Screener / Watchlist Cards",
        (
            "Target for the Watchlist / Approval Cards panel. Each card shows: "
            "ticker, signal score badge (fire = strong, eye = watching), price + "
            "% change, ATR / Vol / RSI metrics, and key price levels (buy, stop, "
            "target) with an R:R ratio. Market environment header shows SPY/QQQ/IWM "
            "status with a Risk-On indicator."
        ),
        [
            "Card grid → Approval Card layout (one card per Vibe-Trading signal)",
            "VCP score badge → our signal confidence score (70-100 = fire, 55-69 = eye)",
            "ATR / Vol / RSI row → computed by our VPS IndicatorEngine",
            "Buy / Stop / Target levels → ATR-based stop from §3.3",
            "R:R ratio → displayed on each card, blocked if < 1.5",
            "Market environment header → top status bar (SPY + QQQ + IWM snapshots)",
        ],
    ),
]

# ── Styles ────────────────────────────────────────────────────────────────────
BG      = colors.HexColor("#0d0f14")
CARD    = colors.HexColor("#13161e")
BORDER  = colors.HexColor("#252836")
GREEN   = colors.HexColor("#22c55e")
TEAL    = colors.HexColor("#14b8a6")
AMBER   = colors.HexColor("#f59e0b")
WHITE   = colors.HexColor("#e8eaf0")
MUTED   = colors.HexColor("#6b7280")

styles = getSampleStyleSheet()

title_style = ParagraphStyle(
    "MPTitle",
    fontName="Helvetica-Bold",
    fontSize=22,
    textColor=GREEN,
    spaceAfter=4,
    alignment=TA_LEFT,
)
subtitle_style = ParagraphStyle(
    "MPSub",
    fontName="Helvetica",
    fontSize=11,
    textColor=MUTED,
    spaceAfter=2,
    alignment=TA_LEFT,
)
section_style = ParagraphStyle(
    "MPSection",
    fontName="Helvetica-Bold",
    fontSize=14,
    textColor=TEAL,
    spaceBefore=10,
    spaceAfter=6,
)
body_style = ParagraphStyle(
    "MPBody",
    fontName="Helvetica",
    fontSize=10,
    textColor=WHITE,
    spaceAfter=8,
    leading=15,
)
bullet_style = ParagraphStyle(
    "MPBullet",
    fontName="Helvetica",
    fontSize=9,
    textColor=WHITE,
    leftIndent=14,
    spaceAfter=3,
    leading=13,
    bulletIndent=4,
    bulletText="→",
)
caption_style = ParagraphStyle(
    "MPCaption",
    fontName="Helvetica-Oblique",
    fontSize=8,
    textColor=MUTED,
    alignment=TA_CENTER,
    spaceAfter=4,
)

# ── Helpers ───────────────────────────────────────────────────────────────────
PAGE_W, PAGE_H = A4
MARGIN = 1.8 * cm
USABLE_W = PAGE_W - 2 * MARGIN


def fit_image(path: Path, max_w: float, max_h: float) -> Image:
    """Return a ReportLab Image scaled to fit within max_w × max_h."""
    with PILImage.open(path) as im:
        iw, ih = im.size
    ratio = min(max_w / iw, max_h / ih)
    return Image(str(path), width=iw * ratio, height=ih * ratio)


# ── Build PDF ─────────────────────────────────────────────────────────────────
def build():
    doc = SimpleDocTemplate(
        str(OUT_PATH),
        pagesize=A4,
        leftMargin=MARGIN,
        rightMargin=MARGIN,
        topMargin=MARGIN,
        bottomMargin=MARGIN,
        title="MarketPulse V4 — UI Design Reference",
        author="MarketPulse V4",
    )

    story = []

    # ── Cover ────────────────────────────────────────────────────────────────
    story.append(Spacer(1, 1.5 * cm))
    story.append(Paragraph("MarketPulse V4", title_style))
    story.append(Paragraph("UI Design Reference — Phase 4 Electron Command Shell", subtitle_style))
    story.append(Spacer(1, 4 * mm))

    intro = (
        "This document captures the four reference screenshots that define the "
        "visual language and panel structure for the MarketPulse V4 Electron UI. "
        "Each image is annotated with the specific UI components it maps to. "
        "These references are locked in; implementation begins in Phase 4 once "
        "the Vibe-Trading baseline (Phase 1) is verified."
    )
    story.append(Paragraph(intro, body_style))
    story.append(Spacer(1, 5 * mm))

    # Key design principles table
    principles = [
        ["Principle", "Detail"],
        ["Dark theme", "#0d0f14 background — near-black, not grey"],
        ["Information density", "Every panel shows actionable numbers, no decorative whitespace"],
        ["Color semantics", "Green = profit/long, Red = loss/short, Teal = AI/signal, Amber = warning"],
        ["Typography", "JetBrains Mono for prices/tickers, Inter for labels and body text"],
        ["Glassmorphism", "Floating panels use backdrop-filter: blur(20px) with 6% white border"],
        ["Chart engine", "TradingView Lightweight Charts — candlestick, Bollinger, KD, MACD, Volume"],
    ]
    tbl = Table(principles, colWidths=[4.5 * cm, USABLE_W - 4.5 * cm])
    tbl.setStyle(TableStyle([
        ("BACKGROUND",   (0, 0), (-1, 0),  CARD),
        ("TEXTCOLOR",    (0, 0), (-1, 0),  TEAL),
        ("FONTNAME",     (0, 0), (-1, 0),  "Helvetica-Bold"),
        ("FONTSIZE",     (0, 0), (-1, 0),  9),
        ("BACKGROUND",   (0, 1), (-1, -1), BG),
        ("TEXTCOLOR",    (0, 1), (-1, -1), WHITE),
        ("FONTNAME",     (0, 1), (-1, -1), "Helvetica"),
        ("FONTSIZE",     (0, 1), (-1, -1), 8.5),
        ("GRID",         (0, 0), (-1, -1), 0.5, BORDER),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [BG, CARD]),
        ("TOPPADDING",   (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING",(0, 0), (-1, -1), 5),
        ("LEFTPADDING",  (0, 0), (-1, -1), 8),
    ]))
    story.append(tbl)
    story.append(PageBreak())

    # ── One page per image ───────────────────────────────────────────────────
    for img_path, heading, description, mappings in IMAGES:
        story.append(Paragraph(heading, section_style))
        story.append(Paragraph(description, body_style))

        # Image — fill most of the usable width, cap height to leave room for bullets
        img_rl = fit_image(img_path, USABLE_W, 13 * cm)
        story.append(img_rl)
        story.append(Paragraph(f"Reference: {img_path.name}", caption_style))
        story.append(Spacer(1, 3 * mm))

        story.append(Paragraph("Maps to MarketPulse V4:", ParagraphStyle(
            "SubHead", fontName="Helvetica-Bold", fontSize=9,
            textColor=AMBER, spaceAfter=4,
        )))
        for m in mappings:
            story.append(Paragraph(m, bullet_style))

        story.append(PageBreak())

    doc.build(story)
    print(f"PDF written → {OUT_PATH}")


if __name__ == "__main__":
    build()
