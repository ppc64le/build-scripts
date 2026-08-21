# openrag ppc64le Build Script

Build and installation verification script for [openrag](https://github.com/langflow-ai/openrag) v0.5.1 on IBM Power (ppc64le), tested on UBI 10.0.

## Prerequisites

- A ppc64le machine (Power9 or Power10) running Linux
- Podman or Docker installed
- Internet access to:
  - `registry.access.redhat.com` (UBI 10 base image — no auth required)
  - `https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/` (ppc64le devpi index — no auth required)
  - `https://github.com/afsanjar/openrag` (source repo — public)

## Usage

Clone the build-scripts repo and run the script inside a UBI 10 container, which mirrors the CI environment exactly:

```bash
git clone https://github.com/ppc64le/build-scripts
cd build-scripts

podman run --rm -it \
  -v $(pwd)/o/openrag/openrag_v0.5.1_ubi_10.0.sh:/build/openrag_v0.5.1_ubi_10.0.sh:z \
  registry.access.redhat.com/ubi10/ubi:10.0 \
  bash /build/openrag_v0.5.1_ubi_10.0.sh
```

Alternatively, run directly on a UBI 10 ppc64le host:

```bash
bash openrag_v0.5.1_ubi_10.0.sh
```

## Extracting the built wheel

The build script runs inside a `--rm` container, so the wheel is destroyed when
the container exits. To keep it, mount a host output directory:

```bash
mkdir -p ~/openrag-dist

podman run --rm -it \
  -v $(pwd)/o/openrag/openrag_v0.5.1_ubi_10.0.sh:/build/openrag_v0.5.1_ubi_10.0.sh:z \
  -v ~/openrag-dist:/output:z \
  registry.access.redhat.com/ubi10/ubi:10.0 \
  bash -c "bash /build/openrag_v0.5.1_ubi_10.0.sh && cp /openrag/dist/openrag-0.5.1-py3-none-any.whl /output/"

ls ~/openrag-dist/
# openrag-0.5.1-py3-none-any.whl
```

The wheel is pure Python (`py3-none-any`) — it is architecture-neutral and can
be built on any platform (Mac, x86, ppc64le) and installed on any other.

## Expected output

A passing run ends with:

```
------------------openrag:build_and_install_success----------
openrag | https://github.com/afsanjar/openrag | 0.5.1 | "Red Hat Enterprise Linux 10.0 (Coughlan)" | GitHub | Pass | Build_and_Install_Success
```

## What the script does

| Phase | Details |
|---|---|
| System deps | Installs `git`, `curl`, `gcc`, `gcc-c++`, `make`, `openblas-devel` via `dnf` |
| uv + Python | Installs [uv](https://docs.astral.sh/uv/), then fetches a standalone Python 3.13 ppc64le build via `uv python install 3.13` |
| Clone | Clones the `ppc64le-0.5.1` branch from `https://github.com/afsanjar/openrag` |
| Build | Runs `uv build --python 3.13` with the ppc64le devpi index for compatible wheels |
| Install | Creates a fresh venv at `/tmp/openrag-venv`, installs the wheel and all dependencies |
| Verify | Runs `import tui.main` against the venv Python to confirm the entry point is importable |

## ppc64le-specific notes

- **`python3.13` is not in UBI 10's dnf repos.** The script uses `uv python install 3.13` instead, which downloads a pre-built standalone CPython 3.13 ppc64le binary — no compilation required.

- **ppc64le devpi index.** Several packages on PyPI have no ppc64le wheel and fail to build from source (tiktoken, grpcio, and ~30 others). The script sets `UV_EXTRA_INDEX_URL` to `https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/` which provides pre-built ppc64le wheels for all of them.

- **Patched source branch.** The `ppc64le-0.5.1` branch on `afsanjar/openrag` carries a set of patches over the upstream `langflow-ai/openrag` `refactor-image-config` branch. The full diff is available as `ppc64le-consolidated.patch` in that branch. Key changes:
  - `pyproject.toml`: pins `tiktoken<0.13.0` and `grpcio==1.80.0`; adds `[tool.uv.sources]` to pull those from the ppc64le index
  - `docker-compose.yml`: replaces fixed image tags with overridable env vars (`OPENSEARCH_IMAGE`, `LANGFLOW_IMAGE`, `DASHBOARDS_IMAGE`) for ppc64le-compatible images; reduces `stop_grace_period` from 2m to 30s
  - `src/tui/main.py`: replaces Alpine container chown with native `os.chown` (avoids `docker.io` pull on air-gapped hosts)
  - `src/tui/managers/docling_manager.py`: pins `docling-serve==1.20.0`, adds `ray`, `kfp`, `av`, `pyarrow`, `scipy` pins, constrains `opencv-python-headless<5` and `pillow<12` on ppc64le

## Installing the wheel directly (alternative to the tarball)

After extracting the wheel above, you can install and run OpenRAG without the
full embedded install script. This is useful for iterative testing:

```bash
# Copy wheel to the target Power machine
scp ~/openrag-dist/openrag-0.5.1-py3-none-any.whl root@<power-machine>:~/

# On the Power machine
uv venv --python 3.13 ~/openrag-venv
source ~/openrag-venv/bin/activate
uv pip install ~/openrag-0.5.1-py3-none-any.whl \
  --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/ \
  --index-strategy unsafe-best-match
openrag
```

Note: the direct wheel install skips container image pulls and `.env` setup.
You still need to configure `~/.openrag/tui/.env` and start the stack manually
via the TUI.

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Build, install, and import verification all passed |
| `1` | Clone, build, or install step failed |
| `2` | Import verification failed (package installed but not importable) |

## Maintainer

Kamryn Schock — kamrynschock@ibm.com
