#!/usr/bin/env bash
# Offline tests for sync-labels.sh and repo-metadata.sh.
#
# A stub `gh` (tests/stub/gh) is put first on PATH. It serves a fixture, logs
# every call and applies label and repo edits to the fixture, so a dry run, an
# --apply and a second dry run can be checked end to end without GitHub.
#
# Usage: scripts/tests/run.sh
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
scripts=$(dirname "$here")
work=$(mktemp -d "${TMPDIR:-/tmp}/gh-stub-test.XXXXXX")
trap 'rm -rf "$work"' EXIT
export GH_STUB_STATE=$work
export PATH="$here/stub:$PATH"

failures=0
check() {  # check <description> <command...>
  local what=$1; shift
  if "$@"; then echo "PASS $what"; else echo "FAIL $what"; failures=$((failures + 1)); fi
}
mutations() { command grep -c -E '^(label (create|edit|delete)|repo edit) ' "$work/calls.log" || true; }
state_hash() { sha256sum "$work/state.json" | cut -d' ' -f1; }

# ---- sync-labels.sh -------------------------------------------------------
cat >"$work/state.json" <<'EOF'
{"repos": {
 "burnoutlabs/alpha": {"labels": [
   {"name": "bug", "color": "d73a4a", "description": "Something isn't working"},
   {"name": "wontfix", "color": "ffffff", "description": "This will not be worked on"},
   {"name": "good first issue", "color": "7057ff", "description": "Good for newcomers"},
   {"name": "priority:high", "color": "ff0000", "description": "custom"},
   {"name": "type:bug", "color": "d73a4a", "description": "Something is broken"},
   {"name": "type:docs", "color": "123456", "description": "Documentation"}],
  "uses": {"bug": {"issue": 2}, "good first issue": {"pr": 1}}},
 "burnoutlabs/beta": {"labels": []},
 "burnoutlabs/gamma": {"archived": true, "labels": []}
}}
EOF
: >"$work/calls.log"
before=$(state_hash)
out=$("$scripts/sync-labels.sh")
echo "$out" >"$work/labels-dry.txt"

check "labels dry run makes no mutating gh call" test "$(mutations)" -eq 0
check "labels dry run leaves the fixture unchanged" test "$(state_hash)" = "$before"
check "labels dry run plans 10 creates on alpha and 12 on beta" \
  test "$(command grep -c '^DRY-RUN gh label create' <<<"$out")" -eq 22
check "labels dry run fixes the wrong colour" \
  command grep -q -F "DRY-RUN gh label edit type:docs --repo burnoutlabs/alpha --color 0075ca --description Documentation" <<<"$out"
check "labels dry run deletes the unused default" \
  command grep -q -F "DRY-RUN gh label delete wontfix --repo burnoutlabs/alpha --yes" <<<"$out"
check "labels dry run keeps a default used by issues" \
  command grep -q -F "keep  'bug': default label used by 2 issue(s)/PR(s)" <<<"$out"
check "labels dry run keeps a default used by a PR" \
  command grep -q -F "keep  'good first issue': default label used by 1 issue(s)/PR(s)" <<<"$out"
check "labels dry run leaves a custom label alone" \
  command grep -q -F "note  'priority:high'" <<<"$out"
check "labels dry run skips archived repos" \
  command grep -q -F "skip burnoutlabs/gamma: archived" <<<"$out"
check "labels dry run touches nothing in the archived repo" \
  bash -c "! command grep -q 'burnoutlabs/gamma' '$work/calls.log'"
check "labels dry run reports the plan size" \
  command grep -q -F "dry run: 24 change(s) planned" <<<"$out"

: >"$work/calls.log"
"$scripts/sync-labels.sh" --apply >"$work/labels-apply.txt"
check "labels --apply makes the 24 planned calls" test "$(mutations)" -eq 24

: >"$work/calls.log"
out=$("$scripts/sync-labels.sh")
check "labels second dry run plans nothing" command grep -q -F "dry run: 0 change(s) planned" <<<"$out"
check "labels second dry run makes no mutating gh call" test "$(mutations)" -eq 0

: >"$work/calls.log"
out=$("$scripts/sync-labels.sh" beta)
check "labels repo argument limits the run" \
  bash -c "! command grep -q 'burnoutlabs/alpha' '$work/calls.log'"

# ---- repo-metadata.sh -----------------------------------------------------
python3 - "$work/state.json" <<'EOF'
import json, sys
names = ["airbrakes-SR", "Hyperion-II", "HPR-Flight-Computer", "HPR-Rocket-Flight-Computer",
         "ORKtoSCAD", "eChargeSCAD", "rocketry-flight-logs", "screw-switch", "blue-raven-cli",
         "post-flight-analysis", "rocket-altitude-ekf", "cubesat-payload", ".github"]
repos = {f"burnoutlabs/{n}": {"description": "", "topics": [], "labels": []} for n in names}
repos["burnoutlabs/screw-switch"]["topics"] = ["high-power-rocketry", "kicad", "pcb"]
repos["burnoutlabs/screw-switch"]["description"] = "Screw-actuated safety switch for arming high-power rocket electronics."
repos["burnoutlabs/ORKtoSCAD"]["archived"] = True
json.dump({"repos": repos}, open(sys.argv[1], "w"))
EOF
: >"$work/calls.log"
before=$(state_hash)
out=$("$scripts/repo-metadata.sh")
echo "$out" >"$work/metadata-dry.txt"

check "metadata dry run makes no mutating gh call" test "$(mutations)" -eq 0
check "metadata dry run leaves the fixture unchanged" test "$(state_hash)" = "$before"
check "metadata dry run plans an edit for 12 repos" \
  test "$(command grep -c '^DRY-RUN gh repo edit' <<<"$out")" -eq 12
check "metadata dry run adds only the missing topic and keeps a matching description" \
  command grep -q -x -F "DRY-RUN gh repo edit burnoutlabs/screw-switch --add-topic rocketry" <<<"$out"
check "metadata dry run skips an archived repo" \
  command grep -q -F "skip burnoutlabs/ORKtoSCAD: archived" <<<"$out"

: >"$work/calls.log"
"$scripts/repo-metadata.sh" --apply >"$work/metadata-apply.txt"
check "metadata --apply makes the 12 planned calls" test "$(mutations)" -eq 12

: >"$work/calls.log"
out=$("$scripts/repo-metadata.sh")
check "metadata second dry run plans nothing" command grep -q -F "dry run: 0 change(s) planned" <<<"$out"
check "metadata second dry run makes no mutating gh call" test "$(mutations)" -eq 0

# ---- failure handling -----------------------------------------------------
echo '{"repos": {}}' >"$work/state.json"
check "metadata stops when gh fails" bash -c "! '$scripts/repo-metadata.sh' >/dev/null 2>&1"
check "labels stops when the org has no repos" bash -c "! '$scripts/sync-labels.sh' >/dev/null 2>&1"

echo
if (( failures )); then echo "$failures check(s) failed"; exit 1; fi
echo "all checks passed"
