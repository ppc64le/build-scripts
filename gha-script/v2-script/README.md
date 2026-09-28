# PowerCore Fetch, Install & Destroy (`fetch-and-install-powercore.sh`)

Automates retrieving configuration secrets from **IBM Cloud Secrets Manager**, downloading the target installer wheel from **IBM Cloud Object Storage (COS)**, and deploying **PowerCore** on a local or staging environment. Also supports tearing down an existing setup via `--destroy`.

> **Note**: Container images are **not** built during this setup phase; required container images are pulled dynamically during deep scan runs.

---

## What the Script Does

### Install path
1. **Authenticates** with IBM Cloud IAM using the provided Service ID API Key.
2. **Resolves the secret** based on `--env`:
   - `local` → `powercore-config-secrets-local` (Secret ID: `76de1f61-c731-e419-d78e-90125be548de`)
   - `staging` → `powercore-config-secrets-staging` (Secret ID: `7384e6e0-3ce1-aaca-e68a-bbfe5e2cf010`)
   - Both use Instance ID: `e04a4ffa-e1fc-419f-85ec-5dcb512d2d1c` (`us-east`)
3. **Generates `powercore-config.env`** with all secret key-value pairs, injects/overrides `POWERCORE_WHEEL_VERSION` and `GITHUB_TOKEN`, and automatically maps the user API key to:
   - `COS_API_KEY`, `ICR_API_KEY`, `IBMCLOUD_API_KEY`, `IAM_WRITER_API_KEY`
4. **Downloads `powercore_installer` wheel** for the target version from COS (`powercore-wheels-staging`).
5. **Installs PowerCore** non-interactively via `powercore-install`.
6. **Deletes `powercore-config.env`** from disk immediately after a successful install to avoid leaving credentials at rest.

### Destroy path
When `--destroy` is passed, the script:
1. Runs `powercore-uninstall --non-interactive` (or `powercore stop`) if available.
2. Uninstalls `powercore` and `powercore_installer` Python packages.
3. Removes `powercore-install` / `powercore` binaries from `/usr/local/bin` and `/usr/bin`.
4. Deletes local artefacts: `powercore-config.env` and `powercore-wheels/`.

No other flags are required for destroy mode.

---

## Prerequisites

- **Required packages**: `curl`, `jq`, `python3` (or `python3.12`), `sudo`
- **IAM API Key**: A Service ID API key with **Reader** access to:
  - IBM Cloud Secrets Manager (`us-east`)
  - IBM Cloud Object Storage (`powercore-wheels-staging` bucket)
- **GitHub Token**: Personal access token or GitHub Actions token for repository access during scan workflows.

---

## Usage

Make the script executable:
```bash
chmod +x fetch-and-install-powercore.sh
```

### Install — Option 1: Command-Line Flags

```bash
./fetch-and-install-powercore.sh \
  --api-key "<YOUR_IAM_API_KEY>" \
  --powercore-version "<VERSION>" \
  --github-token "<YOUR_GITHUB_TOKEN>" \
  --env <local|staging>
```

**Examples:**
```bash
# Local environment
./fetch-and-install-powercore.sh \
  --api-key "abC123XyZ_API_KEY" \
  --powercore-version "0.6.0" \
  --github-token "ghp_EXAMPLE_TOKEN" \
  --env local

# Staging environment
./fetch-and-install-powercore.sh \
  --api-key "abC123XyZ_API_KEY" \
  --powercore-version "0.6.0" \
  --github-token "ghp_EXAMPLE_TOKEN" \
  --env staging
```

### Install — Option 2: Positional Arguments

```bash
./fetch-and-install-powercore.sh "<API_KEY>" "<VERSION>" "<GITHUB_TOKEN>"
```
> Positional mode does not support `--env`; set `POWERCORE_ENVIRONMENT` as an environment variable instead.

### Install — Option 3: Environment Variables

```bash
export IAM_API_KEY="<YOUR_IAM_API_KEY>"
export POWERCORE_WHEEL_VERSION="0.6.0"
export GITHUB_TOKEN="<YOUR_GITHUB_TOKEN>"
export POWERCORE_ENVIRONMENT="local"   # or "staging"

./fetch-and-install-powercore.sh
```

Supported variable aliases:
| Variable | Aliases |
| :--- | :--- |
| API Key | `IAM_API_KEY`, `IBMCLOUD_API_KEY`, `GHA_CURRENCY_SERVICE_ID_API_KEY` |
| Version | `POWERCORE_VERSION`, `POWERCORE_WHEEL_VERSION` |
| GitHub Token | `GITHUB_TOKEN`, `GH_TOKEN` |
| Environment | `POWERCORE_ENVIRONMENT` |

### Destroy — Remove the setup

```bash
./fetch-and-install-powercore.sh --destroy
```

No API key, version, token, or `--env` flag is needed.

---

## CLI Reference

| Flag | Positional / Env var | Required | Description |
| :--- | :--- | :--- | :--- |
| `--api-key` | Pos 1 / `IAM_API_KEY` | Yes (install) | IBM Cloud IAM Service ID API Key |
| `--powercore-version` | Pos 2 / `POWERCORE_WHEEL_VERSION` | Yes (install) | Target PowerCore version (e.g. `0.6.0`) |
| `--github-token` | Pos 3 / `GITHUB_TOKEN` | Yes (install) | GitHub Token for repository operations |
| `--env` | `POWERCORE_ENVIRONMENT` | Yes (install) | Secret to use: `local` or `staging` |
| `--destroy` | — | No | Tear down PowerCore and remove all local artefacts |
| `-h`, `--help` | — | No | Show usage instructions |

---

## Output & Verification

Upon successful installation, verify with:
```bash
# Check installed powercore packages
python3 -m pip list | grep -i powercore

# Verify powercore user creation
id powercore
```

> `powercore-config.env` is automatically deleted after a successful install. It will not be present on disk after the script completes.
