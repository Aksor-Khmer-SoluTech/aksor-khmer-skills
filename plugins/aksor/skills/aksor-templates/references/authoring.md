# Aksor templates — authoring reference

Condensed from the project's guides, where every rule was checked against the real engines (docxtpl for docx, xltpl
for xlsx, Jinja2 + WeasyPrint for html): [Create a template](https://github.com/Aksor-Khmer-SoluTech/aksor-khmer-bi/blob/main/docs/create-a-template.md) and
[Charts, images and data](https://github.com/Aksor-Khmer-SoluTech/aksor-khmer-bi/blob/main/docs/building-a-report.md). Link those when you answer; use this file to get the answer
right.

## Contents
- Pick the format
- Workflow
- Jinja basics and missing data
- docx: the three tag forms
- xlsx
- html
- Charts, images, long tables, batches
- Khmer text and fonts
- Filters and data sources
- Troubleshooting
- Checklist

## Pick the format

| Need | Template | Renders to |
|---|---|---|
| Letter, certificate, invoice, form laid out in Word | `.docx` (default choice: most features, anyone can edit it) | docx, pdf, png |
| A spreadsheet the recipient keeps working in / data export | `.xlsx` | xlsx only |
| Pixel-precise print layout with CSS (cards, badges, columns) | `.html` | pdf, png |

Charts and images are **docx only**. pdf/png from docx go through LibreOffice (native Khmer justify, matches Word);
from html through WeasyPrint.

## Workflow

Write placeholders → register (portal *Templates*, or `POST /api/v1/reports` with `file` + `name`, optionally a
`code`) → check the **Placeholders** tab (fields found, fonts named and whether the server has them) → **Preview**
with a sample payload and save it → **Integration** tab gives curl/JS/Python with the real id or code → replace the
file to iterate (versions are kept; label them, e.g. `1.0.1`, with a note).

Render: `POST /api/v1/reports/<id-or-code>/render?format=pdf` with the JSON body. `/run` instead fetches the
report's own data source for the signed-in user. `/render/batch` renders a list of contexts into one ZIP.

## Jinja basics and missing data

`{{ name }}`, `{{ customer.name }}`, `{{ items[0].label }}`, `{{ qty * price }}`, `{{ a ~ " " ~ b }}` (join text;
`+` is numbers only), filters such as `default("N/A", true)`, `length`, `sum(attribute="line")`,
`map(attribute="x") | join(", ")`, `round(2)`, `round(0, "ceil") | int`, `upper`, `truncate(80)`.

- Numbers: `{{ "{:,.2f}".format(amount) }}` → `1,234.50`; zero-padded `{{ "{:05d}".format(n) }}`. Plain `round`
  and `"{:.2f}"` round halves to even; round with `round(2, "ceil")` first if the rule matters.
- Dates arrive as ISO text and there is no date filter — slice: `{{ d[8:10] }}/{{ d[5:7] }}/{{ d[:4] }}`, or send
  them pre-formatted.
- Khmer digits: `.translate("".maketrans("0123456789", "០១២៣៤៥៦៧៨៩"))` (define once with `{% set kh = … %}`; in docx
  as `{%p set kh = … %}` alone in a paragraph).

**Missing data** is the most common surprise:

| Template | When absent | Result |
|---|---|---|
| `{{ nothing }}` | field missing | blank, no error |
| `{{ issuer.name }}` | `issuer` missing | **render error** `'issuer' is undefined` |
| `{{ issuer.name if issuer else "" }}` | `issuer` missing | blank |
| `{{ note \| default("—", true) }}` | missing, null or `""` | `—` |

Guard every optional *nested* field.

## docx: the three tag forms

A Word file is XML; a control tag must say which piece of Word it controls.

| Form | Controls | Where to type it | The tag's own paragraph/row |
|---|---|---|---|
| `{% … %}` | text inside **one paragraph** (or one cell) | inline, with what it wraps | kept |
| `{%p … %}` | **whole paragraphs** (body, cells, headers, footers) | **alone** in its own paragraph, above and below what repeats | deleted |
| `{%tr … %}` | **whole table rows** | **alone** in its own row, above and below the repeating row | deleted — with anything else typed in that row |

Line items (header row above the markers):

| Row | Cell 1 | Cell 2 | Cell 3 |
|---|---|---|---|
| header | `No.` | `Item` | `Qty` |
| marker | `{%tr for it in items %}` | | |
| body | `{{ loop.index }}` | `{{ it.n }}` | `{{ it.q }}` |
| marker | `{%tr endfor %}` | | |

Open and close with the **same** form (`{%tr for %}` … `{%tr endfor %}`). A plain `{% for %}` in paragraphs or rows of
its own leaves blank lines/empty rows — that gap is what `{%p %}`/`{%tr %}` remove. Two `{%p %}` tags in one
paragraph break each other (`unknown tag 'endfor'`). Conditions work the same way: `{%p if x %}` … `{%p endif %}`,
`{%tr if it.q > 1 %}` … `{%tr endif %}`.

Type each tag in one go: if Word splits it into several formatting runs (formatting changed mid-tag, autocorrect),
the tag prints literally. Turn off smart quotes — Jinja needs straight `"`.

## xlsx

- Same `{{ }}` in cells. Loops are plain `{% for %}` / `{% endfor %}` each in **its own row** (three-row shape); the
  marker rows stay in the output as empty rows, so make them 1 pt high and hidden.
- Never `{%- for %}` (xltpl's docs show it; the loop variable ends up unbound).
- A cell holding **only** `{{ x }}` is written as a real number; anything with surrounding text or `.format()` becomes
  text. Keep numeric cells bare and set the number format (`#,##0.00`) in Excel.
- No charts or images. LibreOffice's own PDF preview of Khmer xlsx cells is garbled; the returned `.xlsx` is correct.

## html

- Ordinary HTML/CSS with Jinja; print CSS (`@page`, `page-break-*`) for layout. Loops wrap whatever repeats.
- Output is escaped; `|safe` only for markup you control, never user data.
- No external URLs or relative paths: every `href`/`src` must be exactly `{{ resource('name') }}`, mapped at
  registration to an uploaded image/stylesheet. Rendering never touches the network.

## Charts, images, long tables, batches

Charts and images are an ordinary `{{ field }}` placeholder — the JSON *value* tells Aksor to draw it:

```json
{
  "sales_chart": {"chart": "bar", "title": "ការលក់ 2026", "labels": ["មករា", "កុម្ភៈ"],
                  "series": [{"name": "ឆ្នាំនេះ", "values": [100, 150]}], "width_mm": 150, "height_mm": 90},
  "logo": {"image_id": "77438b0d3b93", "width_mm": 40}
}
```

`chart` is `bar`, `line` or `pie`; Khmer and Latin labels mix correctly; a spec may name `"font"`. `image_id` comes
from uploading to Resources (`POST /api/v1/images`); height follows the aspect ratio.

A repeating table over `MAX_ROWS_PER_FILE` rows (1,000 by default) is rendered as several equal files in one ZIP
(`X-Report-Parts` header; `part=N` fetches one). Batch rendering is bounded per format (see
`GET /api/v1/reports/batch-limits`).

## Khmer text and fonts

- Segmentation is automatic for every string that contains Khmer — nothing to do in the template or the data; dates,
  numbers and IDs arrive untouched, so slicing a date works. Don't insert spaces or
  zero-width characters by hand.
- A Khmer word split in the wrong place (usually a transliterated name, brand or loanword) → a **protected term**:
  per organization in the portal (Manage → Protected terms, attached to the report) or per deployment; procedure in
  [protected-terms-guide.md](https://github.com/Aksor-Khmer-SoluTech/aksor-khmer-bi/blob/main/docs/protected-terms-guide.md).
- Set a Khmer font in the template (e.g. *Khmer OS Siemreap*, *Khmer OS Muol Light* for headings) and justify long
  Khmer paragraphs/cells. `KhmerOSSiemreap.ttf` has no Latin glyphs, so Latin text falls back to another font.
- Templates name fonts; the server's installed fonts draw them. The Placeholders tab marks each named font
  Installed / Added / Substituted / Missing. A missing font is substituted silently and the layout moves — add it
  under Manage → Resources → Fonts (whole server, no restart) after checking its Khmer coverage and license.

## Filters and data sources

On the template's **Parameters** and **Data source** tabs (they save together):

- Filters are free text (text, number, date, date & time, time) or a choice list (fixed lines `value | label`, or a
  REST API read with JSONPath: items path like `$.data[*]`, value and label per item). Shown in the listed order.
- Date defaults: a literal, `now()`, `firstDayOfMonth()`, `lastDayOfMonth()` (API/embedded runs read them in
  `REPORT_TIMEZONE`).
- Data source kinds: **sample data** (fixed JSON, to design before real data exists), **REST API** (URL may use
  `{{ filter }}`; auth through a Connection + Secret), **Database** (one read-only `SELECT` with `:name` parameters on
  PostgreSQL, MySQL, MariaDB, Oracle, SQL Server or Db2; the rows are exposed to the template).
- Access Privilege can limit which choices a person may pick.
- Embedding: a report can run inside another app by parameters; API clients (client id + secret) can run specific
  reports. Details: [building-a-report.md](https://github.com/Aksor-Khmer-SoluTech/aksor-khmer-bi/blob/main/docs/building-a-report.md).

## Troubleshooting

| Symptom | Fix |
|---|---|
| `'x' is undefined` | guard `x.y` with `if x` or `default` |
| `{{ field }}` printed literally | retype the tag in one go; straight quotes |
| blank line / empty row around each repeat | use `{%p %}` / `{%tr %}` instead of plain tags in their own paragraph/row |
| text in a marker row disappeared | `{%tr %}` deletes the whole row — move it to a row above |
| `unknown tag 'endfor'` / `Unexpected end of template` | unbalanced or mixed tag forms; two `{%p %}` in one paragraph |
| loop prints nothing | field isn't a list / wrong key or case |
| xlsx numbers can't be summed | cell has text around `{{ }}` or uses `.format()` |
| xlsx loop variable unbound | `{%- for %}` → use `{% for %}` |
| Khmer wraps badly in a cell | Khmer font + justify on that cell/paragraph |
| Khmer word split wrongly | protected term |
| html shows `&lt;b&gt;` | escaping is on purpose; `|safe` only for trusted markup |
| html registration rejects `href`/`src` | use `{{ resource('name') }}` and map an uploaded resource |
| `400` on render for a format | xlsx → xlsx only; html → pdf/png only; charts/images docx only |
| `409` on register | the code is taken |

## Checklist

Tags typed in one go with straight quotes · every `for`/`if` closed with the same form · optional nested fields
guarded · number and date formatting decided · Khmer font set and long Khmer text previewed · registered with a code
if anything integrates with it · filed in a folder (shortcut if it belongs in several) · sample payload saved and
every branch previewed · version note on each replacement.
