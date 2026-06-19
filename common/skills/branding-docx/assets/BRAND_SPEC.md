# Brand Specification (placeholder — the client fills this in)

Source of truth for visual identity in client-facing `.docx` deliverables. Reference from `SKILL.md`.

This file is a **template**: every `«…»` placeholder below is a value *you* (the client) substitute with your own
brand. Keep the structure; replace the values. Hex colors, fonts, sizes, and layout numbers shown are illustrative
defaults — overwrite them with your brand's. The actual binary assets (template, logo, fonts) are listed in
`README.md` and live alongside this file in `assets/`.

## Colors

Fill in your brand palette. Add or remove rows as your brand requires.

| Name | Hex | Usage |
|------|-----|-------|
| Primary | `«#000000»` | Title text, heading text, primary brand color |
| Accent | `«#000000»` | Accent color, separators, highlights |
| Secondary accent | `«#000000»` | Secondary accent (decorative shapes) |
| Gray | `«#999999»` | Footer text, secondary info |
| Heading 3 gray | `«#434343»` | Heading 3 text |
| Heading 4–6 gray | `«#666666»` | Heading 4–6 text |

## Typography

Fill in your brand fonts and sizes. «Heading font» and «Body font» are the two fonts the client supplies as font
files in `assets/`.

| Element | Font | Size | Weight | Color |
|---------|------|------|--------|-------|
| Cover project name | «Heading font» | 26pt (52 half-pt) | SemiBold | `«primary»` |
| Cover document type | «Heading font» | 18pt (36 half-pt) | Regular | `«primary»` |
| Cover metadata labels | «Body font» | 11pt | Bold | `«primary»` |
| Cover metadata values | «Body font» | 11pt | Regular | `«#333333»` |
| Body text | «Body font» | 11pt (22 half-pt) | Regular | black |
| Heading 1 | «Body font» | 20pt (40 half-pt) | Bold | `«primary»` |
| Heading 2 | «Body font» | 16pt (32 half-pt) | Regular | `«primary»` |
| Heading 3 | «Body font» | 14pt (28 half-pt) | Regular | `«#434343»` |
| Heading 4 | «Body font» | 12pt (24 half-pt) | Regular | `«#666666»` |
| Footer text | «Heading font» | 11pt | Regular | `«gray»` |
| Footer separator | «Heading font» | 11pt | Bold | `«accent»` |

**Font fallback**: place your brand TTF/OTF files in this skill's `assets/`. If embedding fails, fall back to a safe
system font (e.g. Arial). The template-based generation path embeds the fonts correctly.

## Page setup

Adjust to your brand's paper standard.

- Paper size: «US Letter (12240 × 15840 DXA)» or «A4 (11906 × 16838 DXA)»
- Margins: «1 inch all sides (1440 DXA)»
- Header margin: «720 DXA»
- Footer margin: «720 DXA»
- Line spacing: «1.15 (276 twentieths of a point)»

## Document structure

Always two sections:

1. **Cover page** — no header/footer (or `first-page-different`)
2. **Content pages** — header + footer

## Cover page layout

**Top section (upper third):**

```
[Logo — top left, ~«100×52»px, inline]

[~4 empty spacer lines]

      PROJECT NAME           ← «Heading font» SemiBold 26pt, «primary», center
      Document Type Name     ← «Heading font» 18pt, «primary», center
```

Project name MUST be short (3–5 words). Centered.

**Bottom section (lower third):**

```
[~14 empty lines pushing metadata to bottom]

Klient:      Firstname Lastname, Company   ← «Body font» 11pt, label bold, left-aligned
Dodavatel:   Firstname Lastname, «Org»     ← tab stop ~2500 DXA (~4.3cm)

Vytvořeno:   12. března 2026
Revize:      12. března 2026
Platnost do: 11. dubna 2026
```

Use a `nextPage` section break so content starts on page 2.

## Localization

Cover-page metadata labels and date formats follow the document body language.

| Field | Czech | English |
|-------|-------|---------|
| Client | `Klient:` | `Client:` |
| Supplier | `Dodavatel:` | `Supplier:` |
| Created | `Vytvořeno:` | `Created:` |
| Revision | `Revize:` | `Revision:` |
| Valid until | `Platnost do:` | `Valid until:` |
| Date format | `12. března 2026` | `March 12, 2026` |

## Header (content pages only)

**Line 1 (text):**
- Left-aligned: `CONFIDENTIAL & PROPRIETARY` — «Body font» 9pt, gray `«gray»`, all caps
- Right-aligned (tab stop): `Revision: {revision_date}` — «Body font» 9pt, gray `«gray»`

**Line 2 (imagery, behind text):**
- Logo top-left, ~«100×52»px
- Optional decorative shape top-right (e.g. «20% opacity, rotated», behind text)

Header is mandatory on every content page.

## Footer (content pages only)

Right-aligned text:
`«contact@your-org»` (gray `«gray»`, underlined, hyperlink) + ` ` +
`/ ` (bold, accent `«accent»`) +
`«www.your-org»` (gray `«gray»`, underlined, hyperlink) + ` ` +
`/ ` (bold, accent `«accent»`) +
`page: X/Y` (gray `«gray»`)

- Font: «Heading font», 11pt
- Page numbers: Word fields `PAGE` + `NUMPAGES`
- Optional decorative shapes in corners, behind text

## Text alignment

- Body text: justified (block)
- Headings: left-aligned

## Em dashes

NEVER use em dashes (`—`) anywhere. Use regular dashes with spaces (` - `), commas, parentheses, or restructure the
sentence. Applies to all content: cover, headings, body, bullets, metadata.

## Page breaks before H1

Every H1 starts on a new page (`<w:pageBreakBefore/>` in paragraph properties). Exception: the first H1 after the
cover, which already starts on page 2 via section break.

## Heading numbering

Hierarchical: H1 = `1.`, H2 = `1.1.`, H3 = `1.1.1.`, etc. Implemented via Word multi-level list numbering — never
manually typed.

## Tables

- Full-width (9360 DXA)
- Header row: shading `«primary»`, white text, bold
- Body rows: alternating white / `«#F5F0FA»` (a light tint of your primary)
- Border: `«#CCCCCC»`, single, thin
- Cell padding: top/bottom 80, left/right 120

## Lists

- Proper numbering config (never unicode bullets)
- Indent: 720 DXA, hanging: 360

## Horizontal rules

Markdown `---` renders as a paragraph with a bottom border in accent `«accent»`, 6pt thickness.
