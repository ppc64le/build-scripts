# OpenSearch 3.5.0 Docker Image Build Guide (ppc64le)

This document describes the complete procedure to build the OpenSearch **3.5.0** Docker image for the **ppc64le** architecture, including required changes for snapshot-based plugin builds.



## Prerequisites

- Linux system (ppc64le)
- Docker installed and running
- Git installed

Verify Docker installation:

```bash
docker --version
```
## Build the manifest for 3.5.0
```bash
Spon a UBI 9.7 container and build manifest for 3.5.0
git clone https://github.com/opensearch-project/opensearch-build.git
cd opensearch-build
git checkout 3.5.0
git apply opensearch-build.patch
# Build
./build.sh manifests/3.5.0/opensearch-3.5.0.yml \
--platform linux \
--architecture ppc64le \
--distribution tar \
--continue-on-error
```

## Building opensearch-3.5.0 image

```bash
git clone https://github.com/opensearch-project/opensearch-build.git
cd opensearch-build
git checkout 3.5.0
git apply opensearch-docker-build.patch
```


## Snapshot Repository Update (Required)

1. Build the required plugins locally.
2. Verify that snapshot `.zip` artifacts are generated successfully.
3. Use these local artifacts during the Docker image build.


## Prepare Required Files

Place the following files inside:

```
opensearch-build/docker/release/dockerfiles/
```

### Required Files

- Custom `Dockerfile`
- `opensearch-docker-build.patch`
- Locally built plugin snapshot ZIP files: If you're downloading artifact from Jfrog then you need credentials to download them.
  - `opensearch-alerting-3.5.0.0-SNAPSHOT.zip`
  - `opensearch-cross-cluster-replication-3.5.0.0-SNAPSHOT.zip`
  - `opensearch-knn-3.5.0.0.zip`
  - `opensearch-ml-3.5.0.0-SNAPSHOT.zip`
  - `opensearch-neural-search-3.5.0.0-SNAPSHOT.zip`
  - `opensearch-security-3.5.0.0.zip`
  - `opensearch-job-scheduler-3.5.0.0-SNAPSHOT.zip`
  - `opensearch-index-management-3.5.0.0.zip`
  - `opensearch-ltr-3.5.0.0.zip`
  - `opensearch-observability-3.5.0.0.zip`
  - `opensearch-reports-scheduler-3.5.0.0.zip`
  - `opensearch-query-insights-3.5.0.0.zip`

Ensure all artifacts exist before proceeding.



## Replace existing build-image-single-arch.sh with below file under opensearch-build/docker/release/

```
build-image-single-arch.sh
```

## Build the Docker Image

```bash
cd opensearch-build/docker/release
./build-image-single-arch.sh -v 3.5.0 -f dockerfiles/Dockerfile -p opensearch -a ppc64le
```



## Verify the Image

```bash
docker images | grep opensearch
```




This completes the OpenSearch 3.5.0 Docker image build for ppc64le using locally generated snapshot plugin artifacts.
