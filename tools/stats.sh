#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Thong ke "Muc A" cho MacViKey — doc tu ha tang phat hanh, app khong gui gi.
#
#   ./tools/stats.sh          bang tom tat
#   ./tools/stats.sh --json   du lieu tho
#
# Can: curl. Neu co `gh` va da dang nhap thi dung token cua gh de khong bi
# GitHub gioi han 60 request/gio.

set -euo pipefail

OWNER="${MVK_OWNER:-dohoangdat}"
REPO="${MVK_REPO:-MacViKey}"
CASK="${MVK_CASK:-macvikey}"

AUTH=()
if TOKEN="$(gh auth token 2>/dev/null)" && [ -n "$TOKEN" ]; then
  AUTH=(-H "Authorization: Bearer $TOKEN")
fi

api() {
  curl -fsSL "${AUTH[@]}" -H "Accept: application/vnd.github+json" \
       -H "User-Agent: macvikey-stats" "$1" 2>/dev/null || echo "null"
}

RELEASES="$(api "https://api.github.com/repos/$OWNER/$REPO/releases?per_page=100")"
REPOINFO="$(api "https://api.github.com/repos/$OWNER/$REPO")"
BREW="$(curl -fsSL -H 'User-Agent: macvikey-stats' \
         "https://formulae.brew.sh/api/cask/$CASK.json" 2>/dev/null || echo "null")"

if ! command -v jq >/dev/null; then
  echo "Can jq: brew install jq" >&2
  exit 1
fi

if [ "${1:-}" = "--json" ]; then
  jq -n --argjson r "$RELEASES" --argjson i "$REPOINFO" --argjson b "$BREW" '{
    generated_at: (now | todate),
    downloads_total: (if $r == null then null
                      else [$r[].assets[].download_count] | add // 0 end),
    stars: ($i.stargazers_count // null),
    forks: ($i.forks_count // null),
    homebrew_30d: ($b.analytics.install["30d"] // {} | to_entries[0].value // null),
    releases: (if $r == null then [] else
      [$r[] | {tag: .tag_name, published: .published_at,
               downloads: ([.assets[].download_count] | add // 0)}] end)
  }'
  exit 0
fi

TOTAL="$(jq -r 'if . == null then "—" else ([.[].assets[].download_count] | add // 0) end' <<<"$RELEASES")"
STARS="$(jq -r '.stargazers_count // "—"' <<<"$REPOINFO")"
FORKS="$(jq -r '.forks_count // "—"' <<<"$REPOINFO")"
BREW30="$(jq -r '.analytics.install["30d"] // {} | to_entries[0].value // "—"' <<<"$BREW")"

printf '\n  MacViKey — thống kê phát hành\n'
printf '  ─────────────────────────────────────────────\n'
printf '  Tổng lượt tải (GitHub)   %s\n' "$TOTAL"
printf '  Cài qua Homebrew (30d)   %s\n' "$BREW30"
printf '  Sao / Fork               %s / %s\n' "$STARS" "$FORKS"
printf '  ─────────────────────────────────────────────\n'

if [ "$BREW30" = "—" ]; then
  printf '  ! Homebrew chưa có số: cask chỉ được thống kê khi nằm trong\n'
  printf '    repo homebrew-cask chính thức, tap riêng thì không.\n\n'
fi

printf '  Theo từng bản phát hành\n'
jq -r 'if . == null then "  (không lấy được)" else
  .[] | "  \(.tag_name | . + (" " * (10 - length)))  \([.assets[].download_count] | add // 0)  \(.published_at[0:10])"
end' <<<"$RELEASES"
echo
