#!/usr/bin/env bash
# Usage: scripts/add_day.sh N                     (uploads /workspace/shorts/dayN/clip*.mp4 to dayN/)
#        scripts/add_day.sh <folder> <src_dir>    (e.g. day1v /workspace/shorts/day1_voice; use a NEW folder
#                                                  name for replacements so the Pages CDN never serves stale copies)
#        CLIP_GLOB='*.mp4' scripts/add_day.sh lux20261007 /workspace/shorts/luxury/2026-10-07
#                                                 (CLIP_GLOB overrides the default 'clip*.mp4' file pattern)
# Copies clips into dayN/, commits, pushes to main, waits for the GitHub Pages build,
# verifies each public URL (HTTP 200, video/mp4, size + MD5) and writes /workspace/shorts/dayN/urls.txt
set -euo pipefail
ARG="${1:?day number or folder name required}"
if [[ "$ARG" =~ ^[0-9]+$ ]]; then DEST="day${ARG}"; SRC="${2:-/workspace/shorts/day${ARG}}"; else DEST="$ARG"; SRC="${2:?src dir required}"; fi
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OWNER_REPO="sadamdirvi-tech/dubai-life-shorts"
BASE="https://sadamdirvi-tech.github.io/dubai-life-shorts"
cd "$REPO_DIR"
git pull --ff-only origin main
mkdir -p "$DEST"
shopt -s nullglob
CLIP_GLOB="${CLIP_GLOB:-clip*.mp4}"
clips=()
for f in "$SRC"/$CLIP_GLOB; do [[ "$(basename "$f")" == *_tiktok* ]] || clips+=("$f"); done   # TikTok-safe copies are hosted separately (tiktokYYYYMMDD/)
[ ${#clips[@]} -gt 0 ] || { echo "no clips in $SRC"; exit 1; }
for f in "${clips[@]}"; do
  sz=$(stat -c%s "$f"); [ "$sz" -lt 100000000 ] || { echo "$f is >=100MB (GitHub limit)"; exit 1; }
  cp "$f" "$DEST/"
done
git add "$DEST"
git commit -m "Add $DEST Shorts" || echo "nothing new to commit"
git push origin main
SHA=$(git rev-parse HEAD)
echo "waiting for Pages build of $SHA ..."
for i in $(seq 1 60); do
  read -r st commit < <(gh api "repos/${OWNER_REPO}/pages/builds/latest" --jq '.status+" "+.commit')
  [ "$commit" = "$SHA" ] && [ "$st" = "built" ] && break
  [ "$st" = "errored" ] && { echo "Pages build errored"; exit 1; }
  sleep 10
done
out="$SRC/urls.txt"; : > "$out"; ok=1
for f in "${clips[@]}"; do
  name=$(basename "$f"); url="$BASE/$DEST/$name"
  for try in $(seq 1 30); do
    code=$(curl -s -o /dev/null -w '%{http_code}' -I "$url"); [ "$code" = 200 ] && break; sleep 10
  done
  hdr=$(curl -sI "$url")
  ctype=$(echo "$hdr" | tr -d '\r' | awk -F': ' 'tolower($1)=="content-type"{print $2}')
  clen=$(echo "$hdr" | tr -d '\r' | awk -F': ' 'tolower($1)=="content-length"{print $2}')
  rmd5=$(curl -s "$url" | md5sum | cut -d' ' -f1); lmd5=$(md5sum "$f" | cut -d' ' -f1); lsz=$(stat -c%s "$f")
  echo "$name code=$code type=$ctype len=$clen/$lsz md5=$rmd5/$lmd5"
  if [ "$code" = 200 ] && [ "$ctype" = "video/mp4" ] && [ "$clen" = "$lsz" ] && [ "$rmd5" = "$lmd5" ]; then
    echo "$url" >> "$out"
  else ok=0; fi
done
[ $ok = 1 ] && echo "all verified -> $out" || { echo "VERIFICATION FAILED"; exit 1; }
