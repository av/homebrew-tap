#!/bin/sh
# update-formula.sh — refresh Formula/agent-store.rb in the av/homebrew-tap repo
# after a new agent-store release. Run from the tap repo root:
#   ./scripts/update-formula.sh v0.1.0
set -eu

TAG="${1:?usage: update-formula.sh vX.Y.Z}"
VERSION="${TAG#v}"
FORMULA="${2:-Formula/agent-store.rb}"
BASE="https://github.com/av/agent-store/releases/download/$TAG"

fetch_sha() {
  # each release archive has a sibling .sha256 asset; checksum is field 1.
  # Fail (and leave the formula untouched) if the asset is missing or malformed.
  out=$(curl -fsSL "$BASE/agent-store-$TAG-$1.sha256") || {
    echo "error: cannot fetch $BASE/agent-store-$TAG-$1.sha256 (are the $TAG release assets uploaded?)" >&2
    exit 1
  }
  sha=$(printf '%s\n' "$out" | awk 'NR == 1 {print $1}')
  case "$sha" in
    *[!0-9a-f]* | "") echo "error: bad sha256 for $1: '$sha'" >&2; exit 1 ;;
  esac
  [ "${#sha}" -eq 64 ] || { echo "error: bad sha256 for $1: '$sha'" >&2; exit 1; }
  echo "$sha"
}

SHA_MAC_ARM=$(fetch_sha aarch64-apple-darwin)
SHA_MAC_X64=$(fetch_sha x86_64-apple-darwin)
SHA_LINUX=$(fetch_sha x86_64-unknown-linux-musl)
SHA_LINUX_ARM=$(fetch_sha aarch64-unknown-linux-musl)

# bump the version inside the four url lines (the formula has no separate
# `version` line: brew audit --strict reads it from the url)
sed -i.bak -E "s#/download/v[^/]*/agent-store-v[^/]*-(aarch64|x86_64)-#/download/$TAG/agent-store-$TAG-\1-#" "$FORMULA"

# replace the sha256 following each target's url line (placeholders or old values)
replace_sha() { # $1=target $2=sha
  awk -v tgt="$1" -v sha="$2" '
    /url .*-/ { pending = index($0, tgt) > 0 }
    pending && /sha256 / { sub(/sha256 "[^"]*"/, "sha256 \"" sha "\""); pending = 0 }
    { print }
  ' "$FORMULA" > "$FORMULA.tmp" && mv "$FORMULA.tmp" "$FORMULA"
}

replace_sha aarch64-apple-darwin "$SHA_MAC_ARM"
replace_sha x86_64-apple-darwin "$SHA_MAC_X64"
replace_sha x86_64-unknown-linux-musl "$SHA_LINUX"
replace_sha aarch64-unknown-linux-musl "$SHA_LINUX_ARM"
rm -f "$FORMULA.bak"

ruby -c "$FORMULA" >/dev/null 2>&1 || echo "warning: ruby -c failed or ruby missing"

echo "Updated $FORMULA to $VERSION"
echo "  aarch64-apple-darwin:        $SHA_MAC_ARM"
echo "  x86_64-apple-darwin:         $SHA_MAC_X64"
echo "  x86_64-unknown-linux-musl:   $SHA_LINUX"
echo "  aarch64-unknown-linux-musl:  $SHA_LINUX_ARM"
echo "Next: git commit -am 'agent-store $VERSION' && git push"
