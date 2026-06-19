# `assets/` — drop your brand assets here

The `branding-docx` skill is a **formatting scaffold**. It ships no brand of its own. To produce branded `.docx`
output you must place **your organization's own** brand assets in this folder. The skill reads them by the exact
filenames below.

## What to add

| Filename | Required? | What it is |
|----------|-----------|------------|
| `template.docx` | **required** | Your branded Word template — headers, footers, paragraph/heading styles, and any decorative shapes. The skill unpacks this, injects the rendered content, and repacks it. |
| `logo.png` | **required** | Your logo, used on the cover page and in the header. |
| brand font files (`.ttf` / `.otf`) | required if your template embeds custom fonts | The heading and body fonts your template references. Name them whatever your template expects. |
| decorative images (`.png`) | optional | Any background/corner shapes your template uses. |

## What's already here

| Filename | Purpose |
|----------|---------|
| `BRAND_SPEC.md` | Records your brand values — primary color, accent color, heading font, body font, logo file, cover-page layout. Fill in every `«…»` placeholder with your own brand's values. |
| `README.md` | This file. |

## Notes

- The skill (`../SKILL.md`) references these client-supplied paths directly: `assets/template.docx` and
  `assets/logo.png`. Keep those two filenames as-is so the skill finds them.
- Do **not** commit anyone else's brand assets here. These files are yours.
- If `template.docx` or `logo.png` is missing, the skill will stop and ask you to add them rather than guess at a
  look.
