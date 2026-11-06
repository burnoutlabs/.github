# burnoutlabs

burnoutlabs is Cameron Brooks's high-power rocketry work: airbrakes, flight
computers, vehicle design, flight data, and the tools built along the way. Most
of it started on the Western Engineering Rocketry Team (WE Rocketry), and the
team's own repositories stay where they are, linked below rather than copied.
The name is tongue-in-cheek: burnout is the moment a rocket motor stops
pushing, and also the other kind.

## Design principles

These apply to every repository here, existing and new. Existing repos move
toward them as they are worked on; new repos start from them.

- **CAD is code.** Geometry is generated from source (parametric CAD-as-code),
  never hand-edited binaries as the source of truth. STEP, STL and 3MF are build
  outputs.
- **Modular and composable.** Designs are built from reusable parts and
  interfaces that combine (within reason), not one-off monoliths.
- **Data-driven.** Dimensions, requirements and configurations live as data
  (parameters, specs, configs) that the code consumes, so a variant is a data
  change rather than a rewrite.

## Repositories

| Area | Here | Elsewhere (linked, not copied) |
| --- | --- | --- |
| Airbrakes | [airbrakes-SR](https://github.com/burnoutlabs/airbrakes-SR): DMATS airbrakes from the 2023-24 capstone; never deployed in flight | [werocketry/RocketFlightSim](https://github.com/werocketry/RocketFlightSim), [werocketry/airbrakes-lookuptable-generator](https://github.com/werocketry/airbrakes-lookuptable-generator) |
| Vehicle | [Hyperion-II](https://github.com/burnoutlabs/Hyperion-II): 2024-25 rocket design, sims, avionics schematics and flight data | [werocketry/FinFlutterHandbook](https://github.com/werocketry/FinFlutterHandbook), [werocketry/FlightEnvironmentProperties](https://github.com/werocketry/FlightEnvironmentProperties) |
| Flight computer | [HPR-Flight-Computer](https://github.com/burnoutlabs/HPR-Flight-Computer): plain copy of SparkyVT's V4.6, restructured in 2024 <br> [HPR-Rocket-Flight-Computer](https://github.com/burnoutlabs/HPR-Rocket-Flight-Computer): fork of SparkyVT's V4.7.x, where new firmware work starts | [SparkyVT/HPR-Rocket-Flight-Computer](https://github.com/SparkyVT/HPR-Rocket-Flight-Computer) (upstream) |
| Flight data | [post-flight-analysis](https://github.com/burnoutlabs/post-flight-analysis): `pfa`, parsers and analysis for altimeter and flight-computer logs, and the flight datasets <br> [blue-raven-cli](https://github.com/burnoutlabs/blue-raven-cli): USB download tool for the Featherweight Blue Raven <br> [rocket-altitude-ekf](https://github.com/burnoutlabs/rocket-altitude-ekf): offline EKF for altitude, vertical velocity and accelerometer bias (MATLAB) <br> [rocketry-flight-logs](https://github.com/burnoutlabs/rocketry-flight-logs): earlier log repository, superseded by post-flight-analysis | |
| Simulation and CAD tools | [eChargeSCAD](https://github.com/burnoutlabs/eChargeSCAD): ejection-charge calculator and canister generator in OpenSCAD <br> [ORKtoSCAD](https://github.com/burnoutlabs/ORKtoSCAD): fork of an OpenRocket-to-OpenSCAD converter; the contribution was merged upstream in 2024 | [heibench/orlab](https://github.com/heibench/orlab): Python scripting for OpenRocket <br> [bdureau/OpenRocketToOpenScad](https://github.com/bdureau/OpenRocketToOpenScad) (upstream of ORKtoSCAD) |
| Hardware | [screw-switch](https://github.com/burnoutlabs/screw-switch): screw-actuated arming switch <br> [cubesat-payload](https://github.com/burnoutlabs/cubesat-payload): modular, data-driven CubeSat-form-factor payload in OpenSCAD | |
| Org | [.github](https://github.com/burnoutlabs/.github): this profile and org-wide setup | |

**Standalone copies.** airbrakes-SR, Hyperion-II and post-flight-analysis were
copied here from WE Rocketry with their history. The copies here are the ones
maintained; the originals are left as they were and are not kept in sync:
[werocketry/airbrakes-SR](https://github.com/werocketry/airbrakes-SR),
[werocketry/Hyperion-II](https://github.com/werocketry/Hyperion-II),
[werocketry/post-flight-analysis](https://github.com/werocketry/post-flight-analysis).

**Teammates' work.** The repositories in the right-hand column under
WE Rocketry are teammates' projects and stay with the team:

- RocketFlightSim is led by [chasgior214](https://github.com/chasgior214), with
  commits from [BrettMacdon](https://github.com/BrettMacdon) and Cameron.
- airbrakes-lookuptable-generator is led by chasgior214, with commits from
  [anwaralshamkhany](https://github.com/anwaralshamkhany) and Cameron.
- FlightEnvironmentProperties is chasgior214's.
- FinFlutterHandbook is [omshah23](https://github.com/omshah23)'s and
  chasgior214's.

airbrakes-SR itself is joint capstone work: most of its commits are
chasgior214's, alongside Cameron's and BrettMacdon's.

## Timeline

Dates are from git history (commit or repository creation dates).

- **2023-10 to 2024-04:** the airbrakes capstone (DMATS, Drag Modulation Apogee
  Targeting System) for WE Rocketry, in
  [chasgior214/airbrakes-capstone](https://github.com/chasgior214/airbrakes-capstone).
- **2024-04-09:** the capstone repository split into airbrakes-SR,
  RocketFlightSim and a flight-computer repository (a plain copy of SparkyVT
  V4.6, now HPR-Flight-Computer).
- **2024-06:** Spaceport America Cup 2024 and the Hyperion flight on 2024-06-21;
  eChargeSCAD written for packing the ejection charges.
- **2024-07:** ORKtoSCAD contribution, merged upstream on 2024-09-27.
- **2024-11-29:** orlab and Hyperion-II started. A concept for a student-researched-and-developed
  (SRAD) flight computer followed on 2024-12-31 and stayed at the block-diagram
  stage.
- **2025-07:** a clean fork of SparkyVT's flight computer (V4.7.x), and
  screw-switch.
- **2025-08-21:** Hyperion-II flew, logged by a Blue Raven and a TeleMega.
  blue-raven-cli followed the next day.
- **2026-06:** the `pfa` package in post-flight-analysis.
- **2026-07 to 2026-10:** orlab modernised (uv, CI, PyPI releases up to 0.10.0).
- **2026-11:** the work consolidated here in burnoutlabs, with
  rocket-altitude-ekf and cubesat-payload added.
