# Vaults Research

Strategi + ritual memakai Obsidian vault sebagai **grounding knowledge untuk agent**: knowledge saling terhubung, research bisa dilanjutkan lintas sesi, learning curve terukur.

Riset 2026-10-25: [A-Mem](https://arxiv.org/abs/2502.12110) (Zettelkasten agentic memory — atomic notes + link generation + memory evolution; multi-hop +2×, token −85%), [evergreen principles](https://notes.andymatuschak.org/Evergreen_notes) (Matuschak — atomic / concept-oriented / densely-linked), [obsidian-agentic-second-brain](https://github.com/pogii123/obsidian-agentic-second-brain) (PARA dual-layer + verification/freshness model), GraphRAG-vs-vector literature (graph menang multi-hop), [smart-connections-cli](https://github.com/samboyd/smart-connections-cli) (semantic search via `.smart-env/`).

## 5 pilar strategi

1. **Dual-layer** — actionable layer (projects/areas/sessions, file by *actionability*) + Knowledge Atlas (evergreen/concepts, navigasi via **link + MOC**, JANGAN folder topik).
2. **Atomic + concept-oriented** — 1 klaim per note; judul = klaim lengkap (bukan topik).
3. **Link generation + evolution** — note baru wajib ≥2 wikilink ke note lama; note baru yang nyambung → evolve `summary`/tags note lama.
4. **Verification & freshness** — frontmatter `verification: unverified|verified|generated|stale`, `review_after` untuk claims time-sensitive. Grounding fail-closed.
5. **Eval-driven** — health score mingguan; struktur bukan tebakan.

## Struktur folder (actionability ordering)

```
00-meta/        conventions, templates, dashboards, eval-history
01-inbox/       capture cepat, diproses di weekly review
02-journal/     daily/weekly/reviews
10-projects/    time-bound + outcome
20-areas/       tanggung jawab berkelanjutan
30-atlas/       Knowledge: concepts/ evergreen/ literature/ research/ (by TYPE bukan topik)
40-operations/  runbooks/ decisions/ checklists/ incidents/
50-sessions/    log sesi agent (tujuan/hasil/bukti/follow-up)
90-archive/     dormant
```

Struktur legacy (`00-inbox → 90-literature`) tetap didukung evaluator: research→`30-atlas/research/` atau `20-research/`, evergreen→`50-learnings/`+`30-atlas/evergreen`, sessions→`50-sessions/`+`70-sessions/`, decisions→`40-operations/decisions/`+`60-decisions/`.

## Frontmatter standar (agent-readable)

```yaml
---
title: <klaim lengkap>
tags: [domain/subdomain]
created: YYYY-MM-DD
verification: unverified   # unverified|verified|generated|stale
review_after: null          # YYYY-MM-DD utk claims time-sensitive
summary: <1-2 baris — agent bisa skim tanpa baca body>
related: "[[note-a]], [[note-b]]"
---
```

## Ritual sesi (OPEN → CAPTURE → DISTILL → LINK → EVOLVE → CLOSE)

1. **OPEN**: query vault dulu (`rg` + MOC; `smart-connections-cli` kalau ada `.smart-env/`). Jangan temukan ulang = learning curve.
2. **CAPTURE** hasil riset → research note (source-grounded).
3. **DISTILL** insight tahan lama → evergreen ATOMIC, own words. (Anti Collector's Fallacy: simpan ≠ belajar.)
4. **LINK** ≥2 wikilink ke note lama. Nggak ada yang nyambung → terlalu dini dicatat.
5. **EVOLVE** note lama yang pemahamannya berubah (patch summary/body + backlink).
6. **CLOSE**: session note + update MOC + git sync.

## Eval

```bash
./vaults-research.sh eval <vault>        # 9 metrics, exit 0 pass / 2 drift
./vaults-research.sh orphan|deadlink|moc|frontmatter|atomicity|verification <vault>
./vaults-research.sh history <vault>     # append ke 00-meta/eval-history.md
```

| Metric | Target | Kenapa |
|---|---|---|
| connectivity (≥2 outbound link) | >60% | A-Mem: linking = gain terbesar |
| MOC coverage | 100% | navigability agent |
| orphan rate | <5% | knowledge reachable |
| deadlinks | 0 | retrieval tak gagal |
| distill ratio (evergreen/(evergreen+raw)) | naik antar eval | anti Collector's Fallacy |
| verification coverage | >90% | grounding jujur |
| freshness overdue (review_after) | 0 | anti stale |
| oversized notes (>300 baris) | <10% | atomic = retrievable |
| frontmatter (title+created+tags) | >95% | machine-parseable |

Trend di `00-meta/eval-history.md` (generated block) — delta mingguan = learning curve vault.

## Quick start (Mac lain)

```bash
git clone https://github.com/timmycodee/vaults-research
cd vaults-research
./vaults-research.sh eval ~/notes
```

MIT. Not affiliated with Obsidian.
