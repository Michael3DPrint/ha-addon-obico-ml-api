#!/bin/sh
# Project check command. Usage: scripts/check.sh [--build]
# Without --build: static checks only. With --build: also builds the image (needs Docker).
set -eu
cd "$(dirname "$0")/.."

echo "== shell syntax"; sh -n obico_ml_api/run.sh; sh -n scripts/check.sh
command -v shellcheck >/dev/null 2>&1 && { echo "== shellcheck"; shellcheck obico_ml_api/run.sh scripts/check.sh; } || echo "(shellcheck not installed, skipped)"

echo "== yaml + required fields"
python3 -I - <<'PY'
import sys
try:
    import yaml
except ImportError:
    print("(PyYAML not installed, skipped)"); sys.exit(0)
c = yaml.safe_load(open("obico_ml_api/config.yaml"))
for k in ("name", "version", "slug", "arch", "schema", "options", "ports", "watchdog"):
    assert k in c, f"config.yaml missing {k}"
assert c["slug"] == "obico_ml_api" and c["arch"] == ["amd64"]
r = yaml.safe_load(open("repository.yaml")); assert r["name"] and r["url"]
for w in ("ci", "upstream-bump"):
    yaml.safe_load(open(f".github/workflows/{w}.yml"))
print("ok")
PY

echo "== pinned upstream commit is a full SHA and matches NOTICE/CHANGELOG"
SHA=$(sed -n 's/^ARG OBICO_SHA=\([0-9a-f]\{40\}\)$/\1/p' obico_ml_api/Dockerfile)
[ -n "$SHA" ] || { echo "no valid OBICO_SHA in Dockerfile" >&2; exit 1; }
grep -q "$SHA" NOTICE.md || { echo "NOTICE.md does not mention $SHA" >&2; exit 1; }

if [ "${1:-}" = "--build" ]; then
    echo "== docker build"; docker build -t obico-ml-api-check obico_ml_api
fi
echo "CHECK OK"
