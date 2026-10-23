# NGINX Ingress Controller — ppc64le (Power10), UBI 10

Dockerfile: [`5.6.3_ubi_10.2/Dockerfile`](5.6.3_ubi_10.2/Dockerfile)
Version: `v5.6.3`

## Overview

All components are compiled from source, because packages.nginx.org does not publish ppc64le RPMs.

| Component | Version (build arg) |
|---|---|
| nginx OSS | `NGINX_OSS_VERSION=1.31.6` |
| njs (module and `njs` CLI) | `NJS_VERSION=1.0.1` |
| nginx-otel module | `NGINX_OTEL_VERSION=v0.1.2` |
| nginx-acme module (Rust) | `NGINX_ACME_VERSION=v0.4.1` |
| c-ares | `CARES_VERSION=v1.34.8` |
| nginx-agent | `NGINX_AGENT_VERSION=v3.12.0` |
| kubernetes-ingress | `IC_VERSION=v5.6.3` |

## ppc64le patch: `upstream-zone-size` 256k -> 2m

The default `upstream-zone-size` is patched from `256k` to `2m` in the Go source before compiling,
because ppc64le uses a 64KB page size (`getpagesize` = 65536).

The patch is `kubernetes-ingress_v5.6.3_dockerfile.patch`. The Dockerfile downloads it from GitHub
with `wget` (it is not copied from the build context). 

## Build

Run from `Dockerfiles/5.6.3_ubi_10.2/`:

```bash
docker build \
  --build-arg IC_VERSION=v5.6.3 \
  --target local \
  -t nginx/nginx-ingress-ppc64le:5.6.3-ubi \
  -f Dockerfile .
```

The `local` target is the default build target.

### Image name when built by CI

CI builds this Dockerfile as `icr.io/ppc64le-oss/kubernetes-ingress-ppc64le:v5.6.3`. The image name
cannot be changed through `build_info.json`. To get the `nginx/nginx-ingress-ppc64le:5.6.3-ubi` name
used for the e2e tests, retag the image after the build:

```bash
docker tag icr.io/ppc64le-oss/kubernetes-ingress-ppc64le:v5.6.3 nginx/nginx-ingress-ppc64le:5.6.3-ubi
```

## Notes

- The e2e test setup that uses this image is described in the package-level
  [`README.md`](../README.md).
- The e2e test results and the image validation results will be posted in
  [isv-ecosystem issue #159](https://github.ibm.com/ppc64le-automation/isv-ecosystem/issues/159).
