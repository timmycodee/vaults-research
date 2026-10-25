---
name: vaults-research
description: "Strategy and rituals for an agent-grounded Obsidian knowledge vault — dual-layer PARA structure, atomic evergreen notes, link generation + evolution, verification model, and an eval script scoring vault health (connectivity, MOC coverage, orphans, deadlinks, distill ratio). Use when building, auditing, revamping, or syncing a research/learning vault, or running vault health evals."
---

# Vaults Research

Strategi + ritual memakai Obsidian vault sebagai **grounding knowledge untuk agent**: knowledge saling terhubung, research bisa dilanjutkan lintas sesi, learning curve terukur. Berbasis riset 2026-10-25: A-Mem (arXiv 2502.12110 — atomic notes + link generation + memory evolution), evergreen principles (Matuschak), PARA dual-layer + verification model (obsidian-agentic-second-brain), GraphRAG vs vector (graph menang multi-hop), Smart Connections CLI (semantic search dari terminal).

## 5 pilar strategi

1. **Dual-layer** — actionable layer (projects/areas/sessions, file by actionability) + Knowledge Atlas (evergreen/concepts, navigasi via link + MOC, JANGAN folder topik). Knowledge paksa masuk folder topik = struktur mati.
2. **Atomic + concept-oriented** — 1 klaim per note; judul = klaim lengkap (bukan topik). `never-private-key-in-chat` bukan "Chat Security Notes".
3. **Link generation + evolution** — note baru wajib ≥2 wikilink ke note lama (grounding ke knowledge existing); saat note baru nyambung, update `summary`/tags note lama (evolution — ablation A-Mem: ini gain kedua terbesar setelah linking).
4. **Verification & freshness** — frontmatter `verification: unverified|verified|stale` (default unverified utk note agent), `review_after: YYYY-MM-DD` untuk claims time-sensitive. Agent grounding fail-closed: klaim tanpa note verified = "I don't have grounded info".
5. **Eval-driven** — health score tiap minggu via `vaults-research.sh eval` (di bawah). Struktur bukan tebakan — angka.

## Struktur folder (actionability ordering)

```
00-meta/        conventions, templates, dashboards (methodology note = system_of_record)
01-inbox/       capture cepat, proses di weekly review
02-journal/     daily/weekly/review notes
10-projects/    time-bound + outcome (aktif/incubating/on-hold)
20-areas/       tanggung jawab berkelanjutan tanpa end date
30-atlas/       Knowledge: concepts/ evergreen/ literature/ research/ (by TYPE bukan topik)
40-operations/  executable: runbooks/ decisions/ checklists/ incidents/
50-sessions/    log sesi agent (hasil + bukti + follow-up)
90-archive/     dormant, keep untuk retrieval
```

Migration dari struktur lama `00-inbox → 90-literature`: research notes → `30-atlas/research/`, learnings → `30-atlas/evergreen/`, decisions → `40-operations/decisions/`, sessions → `50-sessions/`. MOC jadi `30-atlas/MOC-*.md`.

## Frontmatter standar (agent-readable)

```yaml
---
title: <klaim lengkap atau judul deskriptif>
tags: [domain/subdomain]
created: YYYY-MM-DD
source: <url|path|internal>
verification: unverified   # unverified|verified|generated|stale
review_after: null          # YYYY-MM-DD kalau claims bisa basi
summary: <1-2 baris, agent bisa skim tanpa baca body>
related: "[[note-a]], [[note-b]]"
---
```

## Ritual agent (tiap sesi riset)

1. **OPEN**: sebelum research baru, query vault dulu (rg + MOC + smart-connections kalau ada `.smart-env/`). Learning curve = jangan temukan ulang.
2. **CAPTURE** hasil riset → `30-atlas/research/` (source-grounded) — bukan langsung final; itu literature note.
3. **DISTILL**: insight yang tahan lama → `30-atlas/evergreen/` ATOMIC, own words, judul = klaim. (Anti Collector's Fallacy: simpan ≠ belajar.)
4. **LINK**: note baru ≥2 wikilink ke note lama. Cari kandidat via `rg` judul/MOC. Kalau tidak ada yang nyambung → mungkin catat terlalu dini.
5. **EVOLVE**: kalau note baru mengubah pemahaman note lama → patch `summary`/body note lama + tambah link balik.
6. **CLOSE**: session note `50-sessions/` (tujuan/hasil/bukti/keputusan/follow-up) + update MOC + git sync.

## Eval (health score — jalan mingguan / CI)

`vaults-research.sh eval <vault>` menghitung:

| Metric | Rumus | Target | Kenapa |
|---|---|---|---|
| connectivity | notes dengan ≥2 outbound link / total | > 60% | A-Mem: linking = gain terbesar |
| MOC coverage | notes terindeks ≥1 MOC / total atlas | 100% | navigability untuk agent |
| orphan rate | zero inbound link | < 5% | knowledge reachable |
| deadlink rate | wikilink → file nggak ada | 0% | retrieval fail |
| distill ratio | evergreen / (evergreen + raw research) | naik | anti Collector's Fallacy |
| verification | % note dgn `verification` field | > 90% | grounding jujur |
| freshness | notes lewat `review_after` | 0 overdue | anti stale claims |
| atomicity | notes > 300 baris | < 10% | atomic = retrievable |
| frontmatter | notes dengan title+created+tags | 100% | machine-parseable |

Exit code 0 = semua target tercapai; 2 = ada drift (print metrik gagal). Trend disimpan `00-meta/eval-history.md` (generated block) — delta mingguan = learning curve vault.

## Tools

- `vaults-research.sh eval` — semua metric di atas (bash 3.2, zero dep, lihat script di skill dir).
- `vaults-research.sh orphan|deadlink|moc|frontmatter` — audit per-scan.
- Smart Connections plugin + `smart-connections-cli` (npm) — semantic search via `.smart-env/` embeddings; opsional tapi recommended utk vault > 200 notes.

## Sync

Vault = git repo. `notes-sync "<pesan>"` tiap close-out. Repo GitHub vault = backup + cross-machine; skill `vaults-research` di repo sendiri (`vaults-research` repo GitHub) supaya portable.
