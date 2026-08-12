# Survey Paper Builder

A single-file, offline-capable tool for assembling a Q1 survey paper from a literature
database export. It stages a grounded reference library, generates per-section drafting
prompts, and checks every citation against that library before export.

**The rule the tool enforces:** nothing reaches the exported document unless it traces to a
reference you imported. Everything else — the section tagging, the unverified flags, the
export gates — exists to enforce that, or to show you where it could not be enforced.

## What it does

| Stage | What happens |
|---|---|
| Reference library | Imports CSV from Consensus, Scopus or Web of Science; also BibTeX, RIS, and PDF reference lists. Deduplicates on title similarity. |
| Section tagging | Assigns each reference to the sections where it belongs — by keyword match, by AI classification, or by balancing against proportional targets. Each is shown differently. |
| Research Intelligence | Converts a synthesis report into structured findings, gaps, theories and tables. |
| Comparison matrix | Fills Year / Venue / Citations / Quartile directly from the library; only interpretive columns go to a model. |
| Drafting | Builds a prompt per section containing only that section's tagged references, its word budget, its section number, and the citation keys it is permitted to use. |
| Assembly | Resolves `[REF:key]` markers into formatted citations, builds an alphabetical reference list, exports to Word, Markdown or PDF. |

## Running it

No build step, no server, no dependencies. Open `index.html` in a browser.

Everything you type is stored in your own browser's local storage. Nothing is uploaded
anywhere unless you explicitly configure an API key and press a Run button.

## AI Assist (optional)

The tool works fully without it. Every prompt has a Copy button.

If you add a Google Gemini API key, Run buttons appear on the mechanical tasks — report
extraction, matrix fill, section classification — and on drafting, one section at a time.
There is deliberately no "generate the whole paper" button.

**On free-tier keys and unpublished work:** Google's terms for the *unpaid* Gemini quota state
that submitted content and generated responses are used to improve Google products, and that
human reviewers may read API input and output. If you are sending drafts of an unpublished
manuscript, use a paid key, where Google states prompts are not used for training. Users in
the EEA, Switzerland and the UK get the paid data terms on the free tier automatically.

**The key is never stored in this repository.** It is held in memory by default and only
written to browser storage if you explicitly tick "remember on this device".

## Repository layout

```
index.html            markup only
css/styles.css        all styling
js/app.js             the entire application
vendor/*.js           bundled pdf.js — minified, do not edit
```

The tool is authored as a single HTML file and split mechanically, because three of its
script blocks are minified vendor libraries on single lines hundreds of kilobytes long.
Two scripts manage that:

- `split.bat` — single file → `docs/` with separate css, js and vendor
- `build.bat` — `docs/` → one self-contained HTML file again

Double-click either, or run the `.ps1` directly. The output folder is named `docs` because
GitHub Pages only publishes from the repository root or from a folder named exactly `/docs`.

**Edit the split files, not the single file.** Once you have split, `js/app.js` is the source
of truth and the single-file build is an output. Editing both means they drift, and the drift
is silent — a fix in one never reaches the other.

## Deploying to GitHub Pages

Full walkthrough in [DEPLOY.md](DEPLOY.md). Short version:

1. Double-click `split.bat`.
2. Open `docs/index.html` and import a PDF — that verifies the split before you publish.
3. Push the repository, then Settings → Pages → *Deploy from a branch* → `main` / `/docs`.

### Before you push

- **Never commit an API key.** Git history is permanent — removing a key in a later commit
  does not remove it from the repo. The tool never writes a key into the HTML, so this only
  becomes a risk if you hardcode one while debugging.
- **Do not commit saved project data.** Exported drafts, reference libraries and Word files
  are covered by `.gitignore`. Your work in progress lives in browser storage, not in files,
  so there is normally nothing to exclude.

### A note about shared origins

Every project site under `https://<username>.github.io/` is the **same browser origin**.
Local storage is scoped to the origin, not the path — so a second tool you host on that
account can read the API key and saved project this one stored, and vice versa.

That is harmless when you control everything on the account. It stops being harmless if you
ever host something there you did not write, or merge a pull request that adds JavaScript. If
that is a concern, put this on its own custom domain, or leave the "remember key" box
unticked so nothing sensitive is persisted.

### Plan limits

GitHub Pages on a free personal account only publishes from **public** repositories. A private
source repository requires GitHub Pro or higher — and even then the published site is still
public. A genuinely private site needs GitHub Enterprise Cloud, or a different host
(Cloudflare Pages and Netlify both offer access control on lower tiers).

The tool itself contains no data, so a public repository exposes the code and nothing about
your research. Decide based on whether you want the code public, not whether you want your
paper private.

## Limits worth knowing

- It checks that every citation points at a real paper you imported. It does **not** check
  that a source says what a draft claims it says.
- A green readiness panel means the mechanical checks passed. It does not mean the paper is
  right.
- Reference metadata is only as good as the export. A CSV without an abstract column leaves
  every reference without a snippet, which weakens section tagging and leaves the comparison
  matrix with nothing to read.
