#!/bin/bash
# Vaults Research — vault health eval + audit scans
# Usage:
#   vaults-research.sh eval <vault>              # full health score, exit 0 ok / 2 drift
#   vaults-research.sh orphan|deadlink|moc|frontmatter|atomicity|verification <vault>
#   vaults-research.sh history <vault>           # append result to 00-meta/eval-history.md
# bash 3.2 compatible, zero dependencies.

VERSION="1.0.0"
if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
    B="$(tput bold)"; R="$(tput setaf 1)"; G="$(tput setaf 2)"; Y="$(tput setaf 3)"; C="$(tput setaf 6)"; X="$(tput sgr0)"
else B=""; R=""; G=""; Y=""; C=""; X=""; fi
ok()   { printf "%s[+]%s %s\n" "$G" "$X" "$1"; }
bad()  { printf "%s[x]%s %s\n" "$R" "$X" "$1"; }
warn() { printf "%s[!]%s %s\n" "$Y" "$X" "$1"; }
hdr()  { printf "\n%s%s%s\n" "$B$C" "$1" "$X"; }

MODE="${1:-eval}"; VAULT="${2:-$HOME/notes}"
[ -d "$VAULT" ] || { bad "vault not found: $VAULT"; exit 1; }
cd "$VAULT" || exit 1

# ---------------------------------------------------------------- helpers
all_notes() { find . -name '*.md' -not -path './.*' -not -path './.trash/*' | sed 's|^\./||'; }
count() { wc -l | tr -d ' '; }

# atlas = durable knowledge layer (evergreen + concepts + literature + research)
atlas_notes() {
    { find 30-atlas -name '*.md' 2>/dev/null; find 20-research -name '*.md' 2>/dev/null; find 50-learnings -name '*.md' 2>/dev/null; } | sed 's|^\./||'
}

# ---------------------------------------------------------------- scans
scan_orphan() {
    hdr "ORPHAN (zero inbound link)"
    grep -rhoE '\[\[[^]|#^]+' --include='*.md' . 2>/dev/null | sed 's/^\[\[//;s|.*/||' | sort -u > /tmp/vr-linked.txt
    local orphans=0
    while IFS= read -r p; do
        case "$p" in 00-meta/*|01-inbox/*|02-journal/*|99-templates/*|90-archive/*) continue ;; esac
        [ -f "$p" ] || continue
        base=$(basename "$p" .md)
        grep -qxF "$base" /tmp/vr-linked.txt || grep -qxF "$p" /tmp/vr-linked.txt || { echo "  ORPHAN: $p"; orphans=$((orphans+1)); }
    done < <(all_notes)
    echo "  total: $orphans"
}

scan_deadlink() {
    hdr "DEADLINK (wikilink -> missing file)"
    grep -rhoE '\[\[[^]|#^]+' --include='*.md' . 2>/dev/null | sed 's/^\[\[//' | sort -u > /tmp/vr-links.txt
    local dead=0
    while IFS= read -r l; do
        # skip template placeholders and example links
        case "$l" in *'<'*|*'...'*|MOC-...*|*slug*|x|wikilink*) continue ;; esac
        base="${l##*/}"
        [ -f "$l.md" ] || find . -name "$base.md" -not -path './.*' | grep -q . || { echo "  DEAD: [[$l]]"; dead=$((dead+1)); }
    done < /tmp/vr-links.txt
    echo "  total: $dead"
}

scan_frontmatter() {
    hdr "FRONTMATTER (title+created+tags)"
    local missing=0
    while IFS= read -r f; do
        case "$f" in MOC-*.md|AGENTS.md|AGENT-BRIEFING.md|CLIENT-HOOKS.md|README.md|SYNC.md|00-meta/*|99-templates/*) continue ;; esac
        [ "$(head -c 3 "$f")" = "---" ] || { echo "  NO_FM: $f"; missing=$((missing+1)); continue; }
        fm=$(awk '/^---$/{n++; next} n==1' "$f")
        echo "$fm" | grep -q '^title:'   || { echo "  NO_TITLE: $f";   missing=$((missing+1)); }
        echo "$fm" | grep -q '^created:' || { echo "  NO_CREATED: $f"; missing=$((missing+1)); }
        echo "$fm" | grep -q '^tags:'    || { echo "  NO_TAGS: $f";    missing=$((missing+1)); }
    done < <(all_notes)
    echo "  missing fields: $missing"
}

scan_moc() {
    hdr "MOC COVERAGE (atlas notes indexed)"
    grep -hoE '\[\[[^]|#^]+' MOC-*.md 00-meta/MOC-*.md 2>/dev/null | sed 's/^\[\[//;s/.*\///' | sort -u > /tmp/vr-moc.txt
    [ -s /tmp/vr-moc.txt ] || { warn "no MOC files found (MOC-*.md / 00-meta/MOC-*.md)"; return 0; }
    local total=0 missing=0
    while IFS= read -r p; do
        [ -f "$p" ] || continue
        total=$((total+1))
        n=$(basename "$p" .md)
        grep -qxF "$n" /tmp/vr-moc.txt || { echo "  NOT_IN_MOC: $p"; missing=$((missing+1)); }
    done < <(atlas_notes)
    [ "$total" -gt 0 ] && echo "  coverage: $(( (total-missing)*100/total ))% ($((total-missing))/$total)"
}

scan_atomicity() {
    hdr "ATOMICITY (notes > 300 lines)"
    local big=0
    while IFS= read -r f; do
        lines=$(wc -l < "$f" | tr -d ' ')
        [ "$lines" -gt 300 ] && { echo "  BIG(${lines}L): $f"; big=$((big+1)); }
    done < <(all_notes)
    echo "  oversized: $big"
}

scan_verification() {
    hdr "VERIFICATION & FRESHNESS"
    local nover=0 stale=0
    while IFS= read -r f; do
        [ "$(head -c 3 "$f")" = "---" ] || continue
        fm=$(awk '/^---$/{n++; next} n==1' "$f")
        echo "$fm" | grep -q '^verification:' || { nover=$((nover+1)); }
        ra=$(echo "$fm" | grep -oE '^review_after: ?"?([0-9]{4}-[0-9]{2}-[0-9]{2})' | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
        if [ -n "$ra" ]; then
            today=$(date +%Y%m%d); rd=$(printf '%s' "$ra" | tr -d '-')
            [ "$rd" -lt "$today" ] && { echo "  STALE(review_after): $f ($ra)"; stale=$((stale+1)); }
        fi
    done < <(all_notes)
    echo "  no-verification-field: $nover"
    echo "  overdue-review_after: $stale"
}

# ---------------------------------------------------------------- full eval
cmd_eval() {
    hdr "VAULT HEALTH EVAL — $VAULT ($(date +%F))"
    local total=0 fails=0
    pass() { ok "PASS  $1 = $2 (target $3)"; }
    fail() { bad "FAIL  $1 = $2 (target $3)"; fails=$((fails+1)); }
    metric() { # name value target cmp
        total=$((total+1))
        case "$4" in
            ge) [ "$2" -ge "$3" ] 2>/dev/null && pass "$1" "$2" "$3+" || fail "$1" "$2" "$3+" ;;
            le) [ "$2" -le "$3" ] 2>/dev/null && pass "$1" "$2" "$3-" || fail "$1" "$2" "$3-" ;;
        esac
    }

    local notes; notes=$(all_notes | count)
    echo "notes: $notes"

    # 1. connectivity: notes (non-meta/template/journal) with >=2 outbound wikilinks
    local linked=0 considered=0
    while IFS= read -r f; do
        case "$f" in MOC-*.md|AG*.md|CLIENT*|README.md|SYNC.md|00-meta/*|99-templates/*|01-inbox/*|02-journal/*|90-archive/*) continue ;; esac
        considered=$((considered+1))
        n=$(grep -oE '\[\[[^]]+\]\]' "$f" 2>/dev/null | grep -cvE '\[\[(<|\.\.\.|slug|MOC-\.\.\.)' || true)
        [ "${n:-0}" -ge 2 ] && linked=$((linked+1))
    done < <(all_notes)
    [ "$considered" -gt 0 ] && metric connectivity "$(( linked*100/considered ))" 60 ge

    # 2. MOC coverage
    grep -hoE '\[\[[^]|#^]+' MOC-*.md 00-meta/MOC-*.md 2>/dev/null | sed 's/^\[\[//;s/.*\///' | sort -u > /tmp/vr-moc.txt
    local atotal=0 amiss=0
    while IFS= read -r p; do
        [ -f "$p" ] || continue
        atotal=$((atotal+1))
        n=$(basename "$p" .md)
        grep -qxF "$n" /tmp/vr-moc.txt || amiss=$((amiss+1))
    done < <(atlas_notes)
    [ "$atotal" -gt 0 ] && metric moc-coverage "$(( (atotal-amiss)*100/atotal ))" 100 ge

    # 3. orphan rate
    grep -rhoE '\[\[[^]|#^]+' --include='*.md' . 2>/dev/null | sed 's/^\[\[//;s|.*/||' | sort -u > /tmp/vr-linked.txt
    local orphans=0 ototal=0
    while IFS= read -r p; do
        case "$p" in MOC-*.md|AG*.md|CLIENT*|README.md|SYNC.md|00-meta/*|99-templates/*|01-inbox/*|02-journal/*|90-archive/*) continue ;; esac
        [ -f "$p" ] || continue
        ototal=$((ototal+1))
        base=$(basename "$p" .md)
        grep -qxF "$base" /tmp/vr-linked.txt || grep -qxF "$p" /tmp/vr-linked.txt || orphans=$((orphans+1))
    done < <(all_notes)
    [ "$ototal" -gt 0 ] && metric orphan-rate "$(( orphans*100/ototal ))" 5 le

    # 4. deadlink rate
    grep -rhoE '\[\[[^]|#^]+' --include='*.md' . 2>/dev/null | sed 's/^\[\[//' | sort -u > /tmp/vr-links.txt
    local dead=0
    while IFS= read -r l; do
        case "$l" in *'<'*|*'...'*|MOC-...*|*slug*|x|wikilink*) continue ;; esac
        base="${l##*/}"
        [ -f "$l.md" ] || find . -name "$base.md" -not -path './.*' | grep -q . || dead=$((dead+1))
    done < /tmp/vr-links.txt
    metric deadlinks "$dead" 0 le

    # 5. distill ratio: evergreen / (evergreen + raw research)
    local ev=0 rs=0
    ev=$( { find 30-atlas/evergreen 50-learnings -name '*.md' 2>/dev/null; } | count)
    rs=$( { find 30-atlas/research 30-atlas/literature 20-research 90-literature -name '*.md' 2>/dev/null; } | count)
    total=$((total+1))
    if [ "$(( ev+rs ))" -gt 0 ]; then
        dr="$(( ev*100/(ev+rs) ))"
        echo "  distill-ratio: ${dr}% (evergreen $ev / raw $rs) — target: naik antar eval"
        grep -q "distill-ratio: ${dr}%" 00-meta/eval-history.md 2>/dev/null && ok "PASS  distill-ratio stable at ${dr}%" || ok "INFO  distill-ratio = ${dr}% (catat baseline, target naik)"
    else
        echo "  distill-ratio: n/a (tidak ada folder evergreen/research)"
    fi

    # 6. verification coverage
    local nover=0 vtotal=0
    while IFS= read -r f; do
        case "$f" in AG*.md|CLIENT*|README.md|SYNC.md|99-templates/*|01-inbox/*|02-journal/*) continue ;; esac
        vtotal=$((vtotal+1))
        [ "$(head -c 3 "$f")" = "---" ] || { nover=$((nover+1)); continue; }
        awk '/^---$/{n++; next} n==1' "$f" | grep -q '^verification:' || nover=$((nover+1))
    done < <(all_notes)
    [ "$vtotal" -gt 0 ] && metric verification "$(( (vtotal-nover)*100/vtotal ))" 90 ge

    # 7. freshness
    local stale=0 today rd
    today=$(date +%Y%m%d)
    while IFS= read -r f; do
        [ "$(head -c 3 "$f")" = "---" ] || continue
        ra=$(awk '/^---$/{n++; next} n==1' "$f" | grep -oE 'review_after: ?"?([0-9]{4}-[0-9]{2}-[0-9]{2})' | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
        [ -n "$ra" ] && { rd=$(printf '%s' "$ra" | tr -d '-'); [ "$rd" -lt "$today" ] && stale=$((stale+1)); }
    done < <(all_notes)
    metric freshness-overdue "$stale" 0 le

    # 8. atomicity
    local big=0
    while IFS= read -r f; do
        [ "$(wc -l < "$f" | tr -d ' ')" -gt 300 ] && big=$((big+1))
    done < <(all_notes)
    [ "$notes" -gt 0 ] && metric oversized-notes-pct "$(( big*100/notes ))" 10 le

    # 9. frontmatter completeness
    local fmiss=0
    while IFS= read -r f; do
        case "$f" in MOC-*.md|AG*.md|CLIENT*|README.md|SYNC.md|00-meta/*|99-templates/*|01-inbox/*) continue ;; esac
        [ "$(head -c 3 "$f")" = "---" ] && awk '/^---$/{n++; next} n==1' "$f" | grep -q '^title:' || fmiss=$((fmiss+1))
    done < <(all_notes)
    [ "$notes" -gt 0 ] && metric frontmatter-title "$(( (notes-fmiss)*100/notes ))" 95 ge

    echo
    if [ "$fails" -eq 0 ]; then ok "HEALTH: $total metrics, all pass"; exit 0
    else bad "HEALTH: $fails/$total metrics failed"; exit 2; fi
}

cmd_history() {
    H="00-meta/eval-history.md"
    mkdir -p 00-meta
    [ -f "$H" ] || printf -- "---\ntitle: Eval History\ntags: [meta, eval]\ncreated: %s\n---\n\n# Eval History\n\n<!-- source:generated:start id=vault-eval tool=vaults-research.sh -->\n| date | pass/fail | metrics |\n|---|---|---|\n<!-- source:generated:end id=vault-eval -->\n" "$(date +%F)" > "$H"
    # run eval silently, capture summary
    out=$(cmd_eval 2>&1); rc=$?
    summary=$(printf '%s' "$out" | grep "HEALTH:" | tail -1)
    line="| $(date +%F) | $( [ $rc -eq 0 ] && echo "PASS" || echo "FAIL" ) | ${summary#HEALTH: } |"
    awk -v line="$line" '
        /source:generated:end/ { print line; print; next }
        { print }
    ' "$H" > "$H.tmp" && mv "$H.tmp" "$H"
    echo "history updated: $line"
    exit $rc
}

case "$MODE" in
    eval)        cmd_eval ;;
    orphan)      scan_orphan ;;
    deadlink)    scan_deadlink ;;
    moc)         scan_moc ;;
    frontmatter) scan_frontmatter ;;
    atomicity)   scan_atomicity ;;
    verification) scan_verification ;;
    history)     cmd_history ;;
    *) sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//'; echo "usage: $0 {eval|orphan|deadlink|moc|frontmatter|atomicity|verification|history} [vault]"; exit 1 ;;
esac
