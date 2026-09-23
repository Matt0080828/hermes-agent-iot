#!/usr/bin/env bash
# Regenerate the hashed per-profile Pi2 install locks from uv.lock.
#
# These locks are what setup-pi2-minimal.sh feeds to
# `pip install --require-hashes -r "$LOCK_FILE"` on the Pi, so their contents must
# be installable on armv7/armv6 — not merely resolvable on a desktop.
#
# uvloop is excluded from every Pi2 lock even though the fork's all/full profiles
# opt into it (upstream's [uvloop] extra, kept on purpose for desktop/server
# hosts): there is no armv7 wheel and libuv does not build on Termux, so a Pi2
# lock that listed it could never install. The policy is asserted in both
# directions by scripts/check_pi2_install_guards.py.
#
# Usage:
#   scripts/regen_pi2_locks.sh                 # rewrite requirements/pi2/*.lock
#   scripts/regen_pi2_locks.sh /tmp/pi2-check  # verify into a scratch dir first
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${1:-$REPO_DIR/requirements/pi2}"
UV="${UV:-uv}"
PROFILES=(minimal iot rag full dev)
# Packages no Pi2 lock may contain, mirroring the guard's Pi2-hostile list for the
# members that can still reach these profiles through an extra.
EXCLUDED_PACKAGES=(uvloop)

mkdir -p "$OUT_DIR"

for profile in "${PROFILES[@]}"; do
  output="$OUT_DIR/$profile.lock"
  echo "==> exporting Pi2 lock for profile '$profile' -> $output"
  args=(
    export
    --format requirements-txt
    --no-header
    --no-emit-project
    --extra "$profile"
    --output-file "$output"
  )
  for package in "${EXCLUDED_PACKAGES[@]}"; do
    args+=(--no-emit-package "$package")
  done
  "$UV" "${args[@]}"
done

echo "==> verifying no excluded package leaked into a Pi2 lock"
if grep -nE '^[A-Za-z0-9][A-Za-z0-9._-]*(==|\[)' "$OUT_DIR"/*.lock \
  | grep -E '(^|[: ])(uvloop|pillow-heif)(==|\[| )' ; then
  echo "FAILED: a Pi2 lock lists a package that cannot install on armv7/armv6" >&2
  exit 1
fi
echo "==> Pi2 locks regenerated and verified in $OUT_DIR"
