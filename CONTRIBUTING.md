## A special note to contributors

Please follow the below rules while contributing your build script to this repo.

1. Always start your build-script with shabang statement (#!/bin/bash or #!/bin/sh or #!/bin/ksh). Shabang statement should be at **first line** of your build-script, otherwise, ci check will fail with `exec user process caused "exec format error"` error.
2. Below header is mandatory for the build-script:
	```
	# -----------------------------------------------------------------------------
	#
	# Package	: <Package-Name>
	# Version	: <Default package version current build-script is going to support/validate>
	# Source repo	: <Package source repo URL>
	# Tested on	: <Linux OS distribution details on which build-script implemented/validated>
	# Language      : <Programming language in which Package is implemented>
	# Ci-Check  : <True: If build-script can be validated via ci build on docker container.>
	# Script License: Apache License, Version 2 or later
	# Maintainer	: <Maintainer name along with official email-id>
	#
	# Disclaimer: This script has been tested in **root/non-root** mode on given
	# ==========  platform using the mentioned version of the package.
	#             It may not work as expected with newer versions of the
	#             package and/or distribution. In such case, please
	#             contact "Maintainer" of this script.
	#
	# ----------------------------------------------------------------------------
	```
   **If the build-script doesn't contain any of the field in above header, that leads to  `ValueError` in ci check.**
3. The `# Tested on` header field is **mandatory** and must declare the target UBI version in the format `UBI:<major>.<minor>` (e.g. `# Tested on : UBI:10.2`). CI will hard-block the PR if this field is absent or unrecognisable.
4. Please mention in notes that, whether the script is made for root user or non-root user.
5. Always keep the package version/commitID in variable. Try to take version as parameter otherwise take a default version number you are working on. Below is the example:
	``` shell
	VERSION=${1:-v5.0.2}
	# v5.0.2 is the default version, in case of no parameter passed to the script.
	```
6. Check if package/component directory already exists and add new file into it. If not, create a directory for new package/component and place LICENSE file into it.
7. Package name & Filenames must be in **lowercase**.
8. Get Legal approvals incase of any code change/patch. 
9. Build script templates can be found [here](https://github.com/ppc64le/build-scripts/tree/master/templates).
10. Make sure to include test step for package so build get validated with available test's in source.
11. Test the build script on clean UBI container before raising PR. Include test logs as part of PR.
12. Try to create a branch on your forked repo for each PR.

---

## `build_info.json` — Version Block Key Rules

The `version` field in `build_info.json` (e.g. `"version": "v2.11.0"`) and the version block keys nested inside the file (e.g. `"v2.11.0": { ... }`) **must match exactly**.

- A mismatch (e.g. key `"1.5.4"` vs field `"v1.5.4"`) will cause CI to block the PR with an error such as:
  ```
  ERROR: version block key '1.5.4' does not match the 'version' field value 'v1.5.4' in build_info.json.
  ```
- The wildcard key `"*"` is intentionally excluded from this check — it is a catch-all fallback.
- Each version block must list **separate build scripts per UBI major** (UBI8, UBI9, UBI10) so that CI can route each script to the correct build job automatically.

---

## PR Workflow Overview

### Trigger
- Pull Request targeting `master` or `replica-master`
- Manual `workflow_dispatch` (re-trigger a failing PR build on a larger runner)

---

### Pipeline Stages

#### 0. Change Detection (`check_changes`)
- Runs on `ubuntu-latest` (lightweight, no ppc64le runner needed)
- Detects whether any relevant files changed: `build_info.json`, `.sh` scripts, or `Dockerfile`
- Excludes changes under `gha-script/`, `process_bom/`, `script/`, `templates/`, `travis-*` directories
- Sets `should_build=true/false` — downstream jobs are skipped entirely when `false`
- For `workflow_dispatch`, always sets `should_build=true`

---

#### 1. Preparation Stage (`build_info`)
- Runs on a ppc64le runner (`ubuntu-24.04-ppc64le-p10`)
- Validates build scripts using CI checks:
  - Shebang must be present
  - Mandatory header fields must exist (including `# Tested on`)
  - Naming conventions must be followed
  - Directory structure must be correct
- Locates and parses `build_info.json`:
  - Resolves the correct version block by matching changed `.sh` files against `build_script` arrays (best-overlap wins; `"*"` key is skipped)
  - Preserves the raw `.version` field as `PACKAGE_VERSION` (the real package version, e.g. `v2.11.0`) separately from the matched version block key (`VERSION`, e.g. `v2.10.*`)
  - Validates that the resolved version block key matches `PACKAGE_VERSION` exactly (unless the key contains `*`); mismatches cause a hard CI failure
- Runs `read_buildinfo.sh` to populate per-UBI script variables (`SCRIPT_UBI8`, `SCRIPT_UBI9`, `SCRIPT_UBI10`)
- For every changed `.sh` file enforces two hard rules:
  1. The script **must** have a `# Tested on` header
  2. The UBI slot for that script **must** already be populated by `read_buildinfo.sh`; an empty slot indicates a version block key mismatch and will block the PR
- Emits per-UBI outputs (`script_ubi8`, `script_ubi9`, `script_ubi10`) as `{script, tested_on}` JSON objects
- Extracts job control flags:
  - `wheel_build_enabled` — `true` when `wheel_build=true` **and** a `.sh` file changed
  - `docker_build_enabled` — `true` when `docker_build=true` **and** a `Dockerfile` changed
  - `build_package_enabled` — `true` when `build_info.json` or a `.sh` file changed
  - `has_sh_changes`, `has_dockerfile_changes`
- Archives `package-cache` artifact (environment variables and metadata) for downstream jobs

---

#### 2. Build Stage (Parallel, per UBI version)

Three independent build jobs run in parallel. Each job only runs when a script exists for that UBI version:

| Job | Condition |
|-----|-----------|
| `build_ubi8` | `build_package_enabled=true` and `script_ubi8` is non-empty |
| `build_ubi9` | `build_package_enabled=true` and `script_ubi9` is non-empty |
| `build_ubi10` | `build_package_enabled=true` and `script_ubi10` is non-empty |

Each job:
- Downloads the `package-cache` artifact
- Runs `execute_changed_scripts.py` filtered to only the script assigned to that UBI version
- Executes the build inside the correct UBI container

---

#### 3. Wheel Build Stage (Parallel, per UBI × Python version)

Runs only when `wheel_build_enabled=true`. Jobs are split by UBI version and Python version:

| Job | UBI | Python | `continue-on-error` |
|-----|-----|--------|---------------------|
| `wheel_build_ubi8_py311` | UBI8 | 3.11 | No |
| `wheel_build_ubi8_py312` | UBI8 | 3.12 | No |
| `wheel_build_ubi9_py310` | UBI9 | 3.10 | No |
| `wheel_build_ubi9_py311` | UBI9 | 3.11 | No |
| `wheel_build_ubi9_py312` | UBI9 | 3.12 | No |
| `wheel_build_ubi9_py313` | UBI9 | 3.13 | Yes (best-effort) |
| `wheel_build_ubi9_py314` | UBI9 | 3.14 | Yes (best-effort) |
| `wheel_build_ubi10_py312` | UBI10 | 3.12 | No |
| `wheel_build_ubi10_py313` | UBI10 | 3.13 | Yes (best-effort) |
| `wheel_build_ubi10_py314` | UBI10 | 3.14 | Yes (best-effort) |

> **UBI8 note:** Python 3.10, 3.13, and 3.14 are not supported on UBI8. Only py311 and py312 wheel jobs run.
>
> **UBI10 note:** Python 3.10 and 3.11 are not supported on UBI10. Only py312–py314 wheel jobs run.

Each wheel job:
- Runs `build_wheels.sh` with `ENABLE_CVE_SCAN=false` (PR builds do not publish)
- Post-processes the wheel (license injection, IBM classifier, RECORD update); version suffix addition is **skipped** in PR builds because COS credentials are absent
- Verifies that at least one `.whl` file was produced

---

#### 4. Docker Build Stage (`build_docker`)
- Runs only when `docker_build_enabled=true`
- Builds the Docker image using `build_docker.sh`
- Saves the image as a `.tar` artifact inside `package-cache`

---

### Execution Logic Summary

| Change Type              | Build (UBI8/9/10) | Wheel Build | Docker Build |
|--------------------------|:-----------------:|:-----------:|:------------:|
| Build script (`.sh`) changed | Yes (matching UBI) | Yes (if `wheel_build=true`) | No |
| `Dockerfile` changed     | No  | No | Yes (if `docker_build=true`) |
| Both changed             | Yes | Yes (if `wheel_build=true`) | Yes (if `docker_build=true`) |
| `build_info.json` only   | Yes | No | No |
| Only config/infra changes | No | No | No |

---

### Artifacts
- `package-cache` — environment variables, per-UBI script assignments, and metadata used by all downstream jobs
- Build logs — available in GitHub Actions UI on failure

---

### Notes
- CI will hard-block the PR if:
  - Any changed `.sh` file is missing the `# Tested on` header
  - The version block key in `build_info.json` does not exactly match the `version` field value (unless it contains `*`)
  - The UBI slot for a changed script is empty (version block not properly wired)
  - Validation checks (`validate_builds.py`) do not pass
- Ensure `build_info.json` is complete, correct, and that version block keys exactly match the `version` field
- Enable `wheel_build` / `docker_build` only when required
- Test scripts locally on a clean UBI container before raising a PR

---

### Pipeline Flow

```
check_changes
    └── build_info
            ├── build_ubi8      (parallel)
            ├── build_ubi9      (parallel)
            ├── build_ubi10     (parallel)
            ├── wheel_build_ubi8_py311   \
            ├── wheel_build_ubi8_py312    |
            ├── wheel_build_ubi9_py310    |
            ├── wheel_build_ubi9_py311    | all parallel
            ├── wheel_build_ubi9_py312    |
            ├── wheel_build_ubi9_py313    |
            ├── wheel_build_ubi9_py314    |
            ├── wheel_build_ubi10_py312   |
            ├── wheel_build_ubi10_py313   |
            ├── wheel_build_ubi10_py314  /
            └── build_docker    (parallel)
```
