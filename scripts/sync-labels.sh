#!/usr/bin/env bash
# Apply the shared burnoutlabs label set to every repository in the org.
#
# For each non-archived repo:
#   - create any shared label that is missing,
#   - fix the colour or description of a shared label that differs,
#   - delete GitHub's default labels that no issue or pull request uses,
#   - report (never delete) default labels still in use and any other labels.
#
# Dry run by default: it reads the current labels and prints the gh commands it
# would run. Pass --apply to run them. Running it again after --apply plans
# nothing, so it is safe to repeat.
#
# Usage: scripts/sync-labels.sh [--apply] [repo ...]
#   repo  limit the run to these repos (names inside the org); default is all.
set -euo pipefail
shopt -s inherit_errexit

ORG=burnoutlabs

# name|colour|description
SHARED_LABELS=(
  "type:bug|d73a4a|Something is broken"
  "type:enhancement|a2eeef|New capability or design work"
  "type:docs|0075ca|Documentation"
  "type:content|fbca04|Material to import, sift or curate"
  "type:chore|cfd3d7|Housekeeping: repo, licence, metadata, CI"
  "type:research|d4c5f9|Open question or investigation"
  "area:airbrakes|1d76db|Airbrakes / DMATS"
  "area:flight-computer|0e8a16|Flight computer firmware and hardware"
  "area:data|c5def5|Flight logs and datasets"
  "area:hardware|bfd4f2|Electronics and mechanical hardware"
  "area:tools|5319e7|Software tools and libraries"
  "area:org|000000|Org-wide setup and housekeeping"
)

# Labels GitHub creates in a new repository.
DEFAULT_LABELS=(
  "accessibility" "bug" "documentation" "duplicate" "enhancement"
  "good first issue" "help wanted" "invalid" "question" "wontfix"
)

APPLY=0
REPOS=()
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    -h|--help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "unknown option: $arg" >&2; exit 2 ;;
    *) REPOS+=("$arg") ;;
  esac
done

planned=0
# Print a mutating gh command; run it only with --apply.
run() {
  planned=$((planned + 1))
  if (( APPLY )); then
    printf '+ gh'; printf ' %q' "$@"; printf '\n'
    gh "$@"
  else
    printf 'DRY-RUN gh'; printf ' %q' "$@"; printf '\n'
  fi
}

is_default() {
  local name=$1 d
  for d in "${DEFAULT_LABELS[@]}"; do [[ "$name" == "$d" ]] && return 0; done
  return 1
}

is_shared() {
  local name=$1 entry
  for entry in "${SHARED_LABELS[@]}"; do [[ "${entry%%|*}" == "$name" ]] && return 0; done
  return 1
}

# Count issues plus pull requests (any state) carrying a label.
label_uses() {
  local repo=$1 label=$2 issues prs
  issues=$(gh issue list --repo "$repo" --label "$label" --state all --limit 1000 --json number --jq length)
  prs=$(gh pr list --repo "$repo" --label "$label" --state all --limit 1000 --json number --jq length)
  echo $((issues + prs))
}

if (( ${#REPOS[@]} == 0 )); then
  # Command substitution (not a pipe) so that a failing gh stops the script.
  active=$(gh repo list "$ORG" --limit 1000 --json name,isArchived \
    --jq '.[] | select(.isArchived | not) | .name')
  archived=$(gh repo list "$ORG" --limit 1000 --json name,isArchived \
    --jq '.[] | select(.isArchived) | .name')
  mapfile -t REPOS < <(sort <<<"$active" | sed '/^$/d')
  while read -r a; do
    [[ -n "$a" ]] && echo "skip $ORG/$a: archived (labels cannot be changed)"
  done < <(sort <<<"$archived")
  if (( ${#REPOS[@]} == 0 )); then
    echo "no repositories found in $ORG" >&2; exit 1
  fi
fi

declare -A have_colour=() have_desc=()

for name in "${REPOS[@]}"; do
  repo="$ORG/$name"
  echo "== $repo"

  have_colour=() have_desc=()
  current=$(gh label list --repo "$repo" --limit 1000 --json name,color,description \
    --jq '.[] | [.name, .color, .description] | @tsv')
  while IFS=$'\t' read -r lname lcolour ldesc; do
    [[ -z "$lname" ]] && continue
    have_colour["$lname"]=$lcolour
    have_desc["$lname"]=$ldesc
  done <<<"$current"

  for entry in "${SHARED_LABELS[@]}"; do
    IFS='|' read -r lname lcolour ldesc <<<"$entry"
    if [[ -z "${have_colour[$lname]+x}" ]]; then
      run label create "$lname" --repo "$repo" --color "$lcolour" --description "$ldesc"
    elif [[ "${have_colour[$lname],,}" != "$lcolour" || "${have_desc[$lname]}" != "$ldesc" ]]; then
      run label edit "$lname" --repo "$repo" --color "$lcolour" --description "$ldesc"
    fi
  done

  while read -r lname; do
    [[ -z "$lname" ]] && continue
    is_shared "$lname" && continue
    if is_default "$lname"; then
      uses=$(label_uses "$repo" "$lname")
      if (( uses == 0 )); then
        run label delete "$lname" --repo "$repo" --yes
      else
        echo "keep  '$lname': default label used by $uses issue(s)/PR(s); relabel them, then rerun"
      fi
    else
      echo "note  '$lname': not in the shared set and not a GitHub default; left alone"
    fi
  done < <(printf '%s\n' "${!have_colour[@]}" | sort)
done

if (( APPLY )); then
  echo "applied $planned change(s)"
else
  echo "dry run: $planned change(s) planned; rerun with --apply to make them"
fi
