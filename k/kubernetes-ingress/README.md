# kubernetes-ingress v5.6.3 — build script and e2e tests (ppc64le, UBI 10.2)

Build script: [`kubernetes-ingress_v5.6.3_ubi10.2.sh`](kubernetes-ingress_v5.6.3_ubi10.2.sh)

## What the script runs

| Mode | What runs |
|---|---|
| Default (CI) | Go build, `hack/secrets-gen`, unit tests (`make cover`) and the e2e test patch. |
| `RUN_E2E=true` | Everything above, then the docker/Kind based e2e tests. |

The e2e tests need a Kind cluster and the host docker daemon (docker-in-docker), which CI does not
support, so they are skipped unless `RUN_E2E=true` is set.

> **Status:** the e2e test results and the image validation will be posted in
> [isv-ecosystem issue #159](https://github.ibm.com/ppc64le-automation/isv-ecosystem/issues/159).

## E2E tests (opt-in: `RUN_E2E=true`)

The e2e tests use the host docker daemon through the mounted socket.

Without `RUN_E2E=true` (for example in CI), only the build, unit tests and patch check run.

### Prerequisites for `RUN_E2E=true`

Run these once on the VM host before executing the script:

1. Build the IC image from `Dockerfiles/5.6.3_ubi_10.2/Dockerfile`:

   ```bash
   docker build --build-arg IC_VERSION=v5.6.3 --target local \
     -t nginx/nginx-ingress-ppc64le:5.6.3-ubi \
     -f Dockerfile .
   ```

   If you use the image built by CI instead, retag it to the name the script expects:

   ```bash
   docker tag icr.io/ppc64le-oss/kubernetes-ingress-ppc64le:v5.6.3 nginx/nginx-ingress-ppc64le:5.6.3-ubi
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

4. Place the script and the patch file next to each other (or at `/`).

Then run:

```bash
RUN_E2E=true ./kubernetes-ingress_v5.6.3_ubi10.2.sh
```

## Test suites that are NOT run, and why

The batches in the script mirror the upstream `.github/data/matrix-smoke-oss.json` at v5.6.3.

- **`test_oidc*.py` (`--ignore-glob`)**: nothing is lost.
  - Every test class in all 8 files (10 in total) is marked `skip_for_nginx_oss` (Plus only).
  - Apart from that marker, the files carry only the `oidc` / `native_oidc` markers, which no OSS
    batch in `matrix-smoke-oss.json` selects.
  - Six of the 8 files import `playwright`, which is not installed, so collecting them would raise
    a collection error and abort the pytest run.
- **Not selected by any upstream OSS smoke batch either:**
  - `dos*` (needs a `-dos` image).
  - `batch_start`.
  - `multi_ns` (perf/metrics collection).
  - `upgrade` (creates resources for upgrade testing; not part of the smoke matrix).
  - every test marked `skip_for_nginx_oss` (NGINX Plus / App Protect only).