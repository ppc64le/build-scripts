# kubernetes-ingress v5.8.0 - build script and e2e tests (ppc64le, UBI 10.2)

Build script: [`kubernetes-ingress_v5.8.0_ubi10.2.sh`](kubernetes-ingress_v5.8.0_ubi10.2.sh)
(the v5.6.3 script and patch in this directory are unchanged).

## What the script runs

| Mode | What runs |
|---|---|
| Default (CI) | Go build, `hack/secrets-gen`, unit tests (`make cover`), the e2e test patch and the `utils` unit tests. |
| `RUN_E2E=true` | Everything above, then the docker/Kind based e2e tests. |

The e2e tests need a Kind cluster and the host docker daemon (docker-in-docker), which CI does not
support, so they are skipped unless `RUN_E2E=true` is set.

> **Status:** the e2e test results and the image validation will be posted in
> [isv-ecosystem issue #159](https://github.ibm.com/ppc64le-automation/isv-ecosystem/issues/159).

## E2E tests (opt-in: `RUN_E2E=true`)

The e2e tests use the host docker daemon through the mounted socket.

Without `RUN_E2E=true` (for example in CI), only the build, unit tests, patch and `utils` tests run.

### Prerequisites for `RUN_E2E=true`

Run these once on the VM host before executing the script:

1. Build the IC image from `Dockerfiles/5.8.0_ubi_10.2/Dockerfile`:

   ```bash
   docker build --build-arg IC_VERSION=v5.8.0 --target local \
     -t nginx/nginx-ingress-ppc64le:5.8.0-ubi \
     -f Dockerfile .
   ```

   If you use the image built by CI instead, retag it to the name the script expects:

   ```bash
   docker tag icr.io/ppc64le-oss/kubernetes-ingress-ppc64le:v5.8.0 nginx/nginx-ingress-ppc64le:5.8.0-ubi
   ```

2. Start the container with the host Docker socket mounted:

   ```bash
   docker run --privileged -v /var/run/docker.sock:/host-docker.sock \
     --name <container> ... sleep infinity
   ```

3. Copy the docker CLI binary into the container once:

   ```bash
   docker cp $(which docker) <container>:/usr/local/bin/docker
   ```

4. Make sure the test images are available on the host (Docker Hub rate limits can make the pulls fail;
   the script stops early if a required image is missing).

5. Place the script and the patch file next to each other (or at `/`).

Then run:

```bash
RUN_E2E=true ./kubernetes-ingress_v5.8.0_ubi10.2.sh
```

## Images built from source for the e2e tests

These have no ppc64le image, so the script builds the tag the test manifests use and loads it into Kind:

- **external-dns** (`vs_externaldns` batch).
- **Pebble and pebble-challtestsrv 2.10.3** (`acme` batch, new in v5.8.0). The `@sha256` digest pin in
  `tests/data/acme-pebble/pebble.yaml` is removed so the local image is used.

## What is new in v5.8.0

- `test_acme_http01.py` (marker `acme`) runs in the `VS 4/4` batch, as in the upstream matrix.
- `tests/suite/utils` (marker `utils`, no cluster needed) runs as its own step. Upstream runs it in `lint-format.yml`.
- cert-manager 1.21.3 (plus `cert-manager-acmesolver` v1.20.0), coredns 1.15.0 and external-dns v0.24.0.

## Test suites that are NOT run, and why

The batches in the script mirror the upstream `.github/data/matrix-smoke-oss.json` at v5.8.0.

- **`test_oidc*.py` (`--ignore-glob`)**: nothing is lost.
  - Every test class in these files is marked `skip_for_nginx_oss` (Plus only).
  - Apart from that marker, the files carry only the `oidc` / `native_oidc` markers, which no OSS
    batch in `matrix-smoke-oss.json` selects.
  - Several of the files import `playwright`, which is not installed, so collecting them would raise
    a collection error and abort the pytest run.
- **Not selected by any upstream OSS smoke batch either:**
  - `dos*` (needs a `-dos` image).
  - `batch_start`.
  - `multi_ns` (perf/metrics collection).
  - `upgrade` (creates resources for upgrade testing; not part of the smoke matrix).
  - every test marked `skip_for_nginx_oss` (NGINX Plus / App Protect only), including `test_app_protect_waf_plm_vs.py`.
