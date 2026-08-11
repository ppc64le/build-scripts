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
3. Please mention in notes that, whether the script is made for root user or non-root user.
4. Always keep the package version/commitID in variable. Try to take version as parameter otherwise take a default version number you are working on. Below is the example:
	``` shell
	VERSION=${1:-v5.0.2}
	# v5.0.2 is the default version, in case of no parameter passed to the script.
	```
5. Check if package/component directory already exists and add new file into it. If not, create a directory for new package/component and place LICENSE file into it.
6. Package name & Filenames must be in **lowercase**.
7. Get Legal approvals incase of any code change/patch. 
8. Build script templates can be found [here](https://github.com/ppc64le/build-scripts/tree/master/templates).
9. Make sure to include test step for package so build get validated with available test's in source.
10. Test the build script on clean UBI container before raising PR. Include test logs as part of PR.
11. Try to create a branch on your forked repo for each PR.

---

## PR Workflow Overview (Simplified)

### Trigger
- Pull Request
- Manual workflow dispatch

---

### Pipeline Stages

#### 1. Preparation Stage (`build_info`)
- Validate build scripts using CI checks:
  - Shebang must be present
  - Mandatory header fields must exist
  - Naming conventions must be followed
  - Directory structure must be correct
- Identify changed files in the PR
- Locate and parse `build_info.json`
- Extract flags:
  - `wheel_build`
  - `docker_build`

---

#### 2. Build Stage (Always Runs)
- Build the package using `gha-script/build_package.sh`
- The build must:
  - Successfully install/build the package
  - Include test steps for validation

---

#### 3. Conditional Execution (Parallel Jobs)

**Wheel Build**
- Runs only if:
  - `wheel_build = true`
  - Build script (`.sh`) is modified
- Builds wheels across multiple Python versions (3.10 – 3.14)

**Docker Build**
- Runs only if:
  - `docker_build = true`
  - `Dockerfile` is modified
- Builds Docker image and stores it as artifact

---

### Execution Logic Summary

| Change Type            | Wheel Build | Docker Build |
|----------------------|------------|--------------|
| Build script changed | Yes        | No           |
| Dockerfile changed   | No         | Yes          |
| Both changed         | Yes        | Yes          |
| Only config changes  | No         | No           |
| Irrelevant changes   | No         | No           |

---

### Artifacts
- `package-cache` (environment variables and metadata)
- Build logs (available in case of failures)

---

### Notes
- CI will fail if validation checks do not pass
- Ensure `build_info.json` is complete and correct
- Enable `wheel_build` / `docker_build` only when required
- Test scripts locally before raising a PR


---

### Pipeline Flow

Preparation → Build → (Wheel Build + Docker Build in Parallel if applicable)

