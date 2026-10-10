---
name: aksor-templates
description: Write, fix and use report templates for Aksor Khmer BI — Word (.docx), Excel (.xlsx) and HTML templates with Jinja2 placeholders that render to PDF, PNG, DOCX or XLSX with correctly wrapped Khmer text. Use this whenever someone builds or debugs an Aksor template or report (line-item tables, {%tr %} / {%p %} tags, blank rows, "'x' is undefined", totals, number and date formatting, Khmer digits, charts, images, fonts, Khmer words splitting in the wrong place), sets up filters or a data source (REST API, database query), or calls the Aksor API to render, run, batch or embed a report — even if they just say "my invoice template" or "the Khmer text breaks badly".
---

# Aksor report templates

Aksor fills a template with JSON and produces a document. Khmer is written without spaces, so most tools can't wrap
it; Aksor word-segments every Khmer string automatically before rendering, so long Khmer text wraps and justifies
correctly with nothing to do in the template.

Answer with something the person can type: the exact placeholder or tag, where it goes (which paragraph, cell or
row), the JSON that goes with it, and how to check the result. When a rule would surprise them, say why in one line
— most template bugs come from not knowing which piece of Word a tag controls.

For full syntax, every format's quirks, charts, images, filters and troubleshooting, read
**`references/authoring.md`**. The project's own guides are the source of truth; link the relevant section:

- Create a template (formats, registering, Jinja cheat sheet, docx/xlsx/html, use cases, troubleshooting):
  https://github.com/Aksor-Khmer-SoluTech/aksor-khmer-bi/blob/main/docs/create-a-template.md
- Charts, images, long tables, batches, filters, data sources, embedding, API clients:
  https://github.com/Aksor-Khmer-SoluTech/aksor-khmer-bi/blob/main/docs/building-a-report.md
- A Khmer word split wrongly: https://github.com/Aksor-Khmer-SoluTech/aksor-khmer-bi/blob/main/docs/protected-terms-guide.md
- Signing in from scripts: https://github.com/Aksor-Khmer-SoluTech/aksor-khmer-bi/blob/main/docs/authentication.md

## Pick the format

| Need | Template | Renders to |
|---|---|---|
| Letter, certificate, invoice, form laid out in Word | `.docx` — the default: most features, anyone can edit it | docx, pdf, png |
| A spreadsheet the recipient keeps working in | `.xlsx` | xlsx only |
| Precise print layout with CSS | `.html` | pdf, png |

Charts and images work in `.docx` only.

## The five things that cause most problems

1. **Which tag form (docx).** `{% %}` works on text *inside one paragraph or cell*. `{%p %}` repeats or hides
   *whole paragraphs* and must sit alone in its own paragraph. `{%tr %}` repeats or hides *whole table rows* and must
   sit alone in its own row. A plain `{% for %}` placed in a row or paragraph of its own leaves a blank row/line
   around every repeat — that is the symptom `{%p %}` / `{%tr %}` exist to remove.
2. **Marker rows are deleted whole.** A `{%tr %}` row disappears from the output with *everything* typed in it — a
   "Total" written next to `{%tr endfor %}` vanishes. Put headers above the opening marker row and totals in their
   own row below the closing one. Open and close with the same form.
3. **Missing nested data errors.** A missing top-level field renders blank, but reading a property of something
   absent (`{{ discount.amount }}` with no `discount`) stops the render: `'discount' is undefined`. Guard it:
   `{{ discount.amount if discount else "" }}`, or hide the row with `{%tr if discount %}` … `{%tr endif %}`.
   `default()` doesn't help there — the error happens first.
4. **Word splits tags.** If formatting changes mid-tag or autocorrect touches it, Word stores the tag in pieces and it
   prints literally. Retype it in one go (or paste as plain text) and turn off smart quotes — Jinja needs straight
   `"`.
5. **Khmer needs a Khmer font, not spaces.** Never add spaces or invisible characters to make Khmer wrap. Set a Khmer
   font (e.g. *Khmer OS Siemreap*, *Khmer OS Muol Light* for headings) and justify long Khmer paragraphs and cells. A
   word split in the wrong place — usually a transliterated name, brand or loanword — is fixed by adding it as a
   **protected term** (portal: Manage → Protected terms, attached to the report), not by changing the template.

## A line-item table (docx), the right way

| Row | Cell 1 | Cell 2 | Cell 3 |
|---|---|---|---|
| header | `No.` | `Item` | `Amount` |
| marker | `{%tr for it in items %}` | | |
| body | `{{ loop.index }}` | `{{ it.name }}` | `{{ "{:,.2f}".format(it.qty * it.price) }}` |
| marker | `{%tr endfor %}` | | |
| total | `Total` | | `{{ "{:,.2f}".format(total) }}` |

```json
{"items": [{"name": "Pen", "qty": 2, "price": 1.5}, {"name": "សៀវភៅ", "qty": 1, "price": 10}], "total": 13}
```

## Checking a template

In the portal: register it (Templates → New), open the **Placeholders** tab (the fields it found, and the fonts it
names marked Installed / Added / Substituted / Missing), then **Preview** with a sample payload and save it — try
every branch (empty list, missing optional object, very long Khmer text). The **Integration** tab gives ready-made
curl / JavaScript / Python calls with the report's real id or code.

From a script (HTTP Basic is fine for scripts on HTTPS; see the authentication guide for tokens):

```bash
curl -u USER:PASSWORD -X POST "https://aksor.example.com/api/v1/reports/<id-or-code>/render?format=pdf" \
  -H "Content-Type: application/json" -d @sample.json -o out.pdf
```

Give a template a **code** (e.g. `invoice`) when anything integrates with it, so callers don't depend on the random
id. Replacing the file keeps the old versions; add a version label and a note each time.
