---
name: branding-docx
description:
  Converts a markdown file (with YAML frontmatter cover-page metadata) into a professionally branded Word document
  (.docx) using your organization's own template and brand assets. Use whenever the user wants to finalize, brandify,
  or hand over a client-facing document in the organization's visual identity. Triggers on: "vytvoř docx",
  "brandovaný dokument", "firemní dokument", "převeď do docx", "finalizuj dokument", "vytvoř branded dokument",
  "branded docx", "convert to docx", "finalize document", "create branded document", "formatted doc",
  "/common:branding-docx". This is the FORMATTING layer only — it expects markdown content as input. Do NOT use it to
  generate content; pair it with a content skill when the user starts from scratch.
---

# Branded Docx Generator

Take an input markdown file and produce a `.docx` in your organization's visual identity. This skill is a **formatting
scaffold**, not a source of branding: it does not ship any brand of its own. **The client supplies their own brand
assets** — a Word template, a logo, and brand fonts — by dropping them into `assets/` (see
`assets/README.md`). The skill renders markdown content into that template; what comes out is branded with *your*
identity, not anyone else's.

This skill is the final step of a content → formatting pipeline; content generation lives elsewhere.

## When to use

- User already has markdown content and wants the branded `.docx` deliverable.
- User finishes a content-generation skill (or ad-hoc markdown) and asks for the docx.

Do NOT use when the user is still drafting content — run the content step first.

## Prerequisites — client-supplied assets

Before this skill can produce branded output, the following must exist in `assets/` (the client provides them — see
`assets/README.md`):

- `assets/template.docx` — the client's branded Word template (headers, footers, styles, any decorative shapes).
- `assets/logo.png` — the client's logo (cover page + header).
- Brand font files (e.g. `.ttf`/`.otf`) referenced by the template, if the template embeds custom fonts.
- `assets/BRAND_SPEC.md` — records the client's brand values (colors, typography, layout). Treat it as the source of
  truth for any value the template doesn't already encode.

If `assets/template.docx` or `assets/logo.png` is missing, stop and ask the client to add them per `assets/README.md`
rather than inventing a look.

## Workflow

1. **Read input markdown** — from the file path the user provides, or the conversation. Validate YAML frontmatter
   exists; if missing, ask the user for: `project_name`, `document_type`, `client_name`, `client_company`,
   `supplier_name`, `created_date`, `revision_date`, `valid_until` (default: `revision_date + 30 days`).
2. **Read the brand specification** — see `assets/BRAND_SPEC.md` for colors, typography, page setup, cover layout, and
   header/footer rules. Do not invent values; the spec is the source of truth.
3. **Read the docx tooling docs first** — whatever docx library / `unpack` / `pack` / `validate` scripts your
   environment provides. They contain critical rules for the library and the scripts referenced below.
4. **Generate the docx via the template-based approach** (recommended, see Implementation Notes):
   - Unpack `assets/template.docx`
   - Replace `word/document.xml` body with the rendered content
   - Repack
5. **Validate** the output with your docx validation script (e.g. `validate.py <output>`).
6. **Save** to the workspace folder. Filename: `{project-name-kebab}-{document-type-kebab}.docx`.

## Markdown frontmatter

The input markdown MAY carry YAML frontmatter; if missing, prompt the user:

```yaml
---
project_name: "«Project Name»"
document_type: "Statement of Work"
client_name: "«Client Contact»"
client_company: "«Client Company»"
supplier_name: "«Your Contact»"
created_date: "«YYYY-MM-DD»"
revision_date: "«YYYY-MM-DD»"
valid_until: "«YYYY-MM-DD»"
---
```

`project_name` MUST be short (3–5 words) for the cover page. If frontmatter is longer, shorten to a concise title.

## Localization

Cover-page metadata labels and date formats follow the document body's language. See `assets/BRAND_SPEC.md` →
"Localization" for the exact CZ/EN label set and date format.

## Implementation notes

Two approaches:

- **Template-based (recommended)** — unpack `assets/template.docx`, inject content, repack. Preserves anchored
  images, decorative shapes, and exact font embedding. Uses your docx tooling's `unpack` / `pack` scripts.
- **Pure programmatic generation** — reproducible but loses decorative anchored images. Use only if the template
  approach fails.

For programmatic-generation specifics, refer to your docx library's documentation. If you don't already have an
unpack/pack workflow, a library such as `python-docx` (or your language's equivalent — e.g. Apache POI for Java) can
generate the `.docx` programmatically; adapt these steps to your environment's docx tooling. This skill provides the
scaffold and the brand spec only; the brand assets come from the client.

## Asset files

All brand assets live in `assets/`. The client supplies the binaries; this skill ships only the spec and the README.

| File | Source | Purpose |
|------|--------|---------|
| `template.docx` | **client-supplied** | Reference template — preserves headers, footers, anchored shapes, styles |
| `logo.png` | **client-supplied** | Logo (cover page + header) |
| brand font files (`.ttf`/`.otf`) | **client-supplied** | Heading / body / cover fonts referenced by the template |
| `BRAND_SPEC.md` | in skill (client fills in) | Brand specification — colors, typography, layout, header/footer |
| `README.md` | in skill | Lists exactly what the client must drop into `assets/` |

## Output

After generating the docx:

1. Save to the workspace (default: `./out/` or the directory of the input markdown).
2. Tell the user the output path and that they can open it in Word to review.
