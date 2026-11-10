# Test fixtures — digest, jobreqs, output

Sample data in the exact shapes ResumesUX reads and writes. Moved here from the vault
(`Projects/Work/ResumesUX/TestAssets/`, 2026-11-10) so the fixtures live with the code that
consumes them; the vault keeps only the real career corpus.

## `digest/<persona>/`

Per-persona digests — the input shape the `yaml_digest/` use cases read
(`config.yaml` → `digestPath`):

```
digest/<persona>/
  gigs/*.md       # one file per role; frontmatter title/concern/location/dates + bullets
  assets/**/*.md  # summary, skills, projects, education, certifications, contact
```

Personas: `software_engineer`, `data_scientist`, `heavy_equipment_operator`.

## `jobreqs/<Employer>/<Role>/`

Requisitions to tailor against. The filename convention is **not** uniform yet
(`job_req.md`, `software_engineer.md`, `data_scientist.md`) — known drift; consolidate to one
convention when real requisitions replace these.

## `output/`

Example generated resumes (one per digest persona) — the expected document shape.

## Provenance

All of this is **synthetic test data**. The real career corpus is NOT here and does not belong in
this repo — it lives in the vault at `~/Obsidian/Vault/Projects/Work/ResumesUX/Me/`.
