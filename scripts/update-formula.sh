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
  # each release archive has a sibling .sha256 asset; checksum is field 1
  curl -fsSL "$BASE/agent-store-$TAG-$1.sha256" | awk '{print $1}'
}

SHA_MAC_ARM=$(fetch_sha aarch64-apple-darwin)
SHA_MAC_X64=$(fetch_sha x86_64-apple-darwin)
SHA_LINUX=$(fetch_sha x86_64-unknown-linux-musl)

# bump version
sed -i.bak -E "s/^  version \".*\"/  version \"$VERSION\"/" "$FORMULA"

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
rm -f "$FORMULA.bak"

ruby -c "$FORMULA" >/dev/null 2>&1 || echo "warning: ruby -c failed or ruby missing"

echo "Updated $FORMULA to $VERSION"
echo "  aarch64-apple-darwin:        $SHA_MAC_ARM"
echo "  x86_64-apple-darwin:         $SHA_MAC_X64"
echo "  x86_64-unknown-linux-musl:   $SHA_LINUX"
echo "Next: git commit -am 'agent-store $VERSION' && git push"
