#!/usr/bin/env bash
# Set descriptions and topics on the public burnoutlabs repositories.
#
# Every repo gets `rocketry` and `high-power-rocketry` plus area topics. Topics
# are only added, never removed. A description is only changed where it
# differs from the one below.
#
# Dry run by default: it reads each repo's current description and topics and
# prints the gh commands it would run. Pass --apply to run them. Running it
# again after --apply plans nothing, so it is safe to repeat.
#
# Archived repos cannot be edited, so run this before archiving any of them.
# Private repos are not listed here; give them the same pass by hand.
#
# Usage: scripts/repo-metadata.sh [--apply]
set -euo pipefail
shopt -s inherit_errexit

ORG=burnoutlabs
BASE_TOPICS="rocketry,high-power-rocketry"

# repo|description|area topics (comma-separated)
REPOS=(
  "airbrakes-SR|Airbrakes (DMATS) for a 10k ft sounding rocket: WE Rocketry 2023-24 capstone. Standalone copy of werocketry/airbrakes-SR. Never deployed in flight.|airbrakes,kicad"
  "Hyperion-II|Hyperion-II (2024-25) design, sims, avionics schematics and flight data. Standalone copy of werocketry/Hyperion-II.|openrocket,kicad"
  "HPR-Flight-Computer|Working flight-computer firmware for Teensy: a 2024 restructure of SparkyVT's HPR Rocket Flight Computer V4.6. The clean upstream fork is HPR-Rocket-Flight-Computer.|flight-computer,teensy"
  "HPR-Rocket-Flight-Computer|Clean fork of SparkyVT's HPR Rocket Flight Computer, kept to follow upstream. The working firmware is HPR-Flight-Computer.|flight-computer,teensy"
  "ESP-LaunchController|Wireless model rocket launch controller based on the ESP32. In progress; not yet safe to use.|esp32"
  "ORKtoSCAD|Convert OpenRocket files to OpenSCAD geometry. Fork of bdureau/OpenRocketToOpenScad; the contribution here was merged upstream in 2024.|openscad,openrocket"
  "eChargeSCAD|OpenSCAD script for the calculation and generation of ejection charges|openscad"
  "rocketry-flight-logs|Superseded by burnoutlabs/post-flight-analysis, which holds the flight logs and the analysis tools.|flight-data"
  "screw-switch|Screw-actuated safety switch for arming high-power rocket electronics.|kicad"
  "blue-raven-cli|CLI for operating the Featherweight Blue Raven over USB, with reliable data downloads, structured outputs, and extensible configuration and testing capabilities.|flight-computer"
  "post-flight-analysis|pfa: parse, normalise and analyse altimeter/flight-computer logs. Standalone copy of werocketry/post-flight-analysis.|flight-data,python"
  "rocket-altitude-ekf|Offline EKF estimating rocket altitude, vertical velocity and accelerometer bias from IMU and barometer logs (MATLAB).|flight-data,kalman-filter,matlab"
  "cubesat-payload|Modular, data-driven CubeSat-form-factor rocketry payload (chassis, frame, electronics substrate) in OpenSCAD. IREC and Launch Canada.|openscad,cubesat"
  ".github|Org profile and shared configuration for burnoutlabs.|"
)

APPLY=0
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    -h|--help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
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

for entry in "${REPOS[@]}"; do
  IFS='|' read -r name want_desc area <<<"$entry"
  repo="$ORG/$name"

  # One line each: archived flag, description, then topics space-separated.
  current=$(gh repo view "$repo" --json isArchived,description,repositoryTopics \
    --jq '"\(.isArchived)\n\(.description)\n\([(.repositoryTopics // [])[].name] | join(" "))"')
  # $(...) drops trailing empty lines, so missing fields default to empty.
  mapfile -t fields <<<"$current"
  archived=${fields[0]:-}
  have_desc=${fields[1]:-}
  have_topics=${fields[2]:-}

  if [[ "$archived" == "true" ]]; then
    echo "skip $repo: archived (unarchive to edit, or edit before archiving)"
    continue
  fi

  args=()
  if [[ "$have_desc" != "$want_desc" ]]; then
    args+=(--description "$want_desc")
  fi

  missing=()
  IFS=',' read -r -a want_topics <<<"$BASE_TOPICS${area:+,$area}"
  for t in "${want_topics[@]}"; do
    [[ " $have_topics " == *" $t "* ]] || missing+=("$t")
  done
  if (( ${#missing[@]} )); then
    args+=(--add-topic "$(IFS=,; echo "${missing[*]}")")
  fi

  if (( ${#args[@]} )); then
    run repo edit "$repo" "${args[@]}"
  else
    echo "ok   $repo"
  fi
done

if (( APPLY )); then
  echo "applied $planned change(s)"
else
  echo "dry run: $planned change(s) planned; rerun with --apply to make them"
fi
