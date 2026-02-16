# OpenSearch 3.3.0 Docker Image Build Guide (ppc64le)

This document describes the complete procedure to build the OpenSearch **3.3.0** Docker image for the **ppc64le** architecture, including required changes for snapshot-based plugin builds.



## Prerequisites

- Linux system (ppc64le)
- Docker installed and running
- Git installed

Verify Docker installation:

```bash
docker --version
```



## Clone and Checkout Source

```bash
git clone https://github.com/opensearch-project/opensearch-build.git
cd opensearch-build
git checkout 3.3.0
```



## Snapshot Repository Update (Required)

The default build process attempts to download plugin snapshot artifacts from:

```
https://central.sonatype.com/repository/maven-snapshots/
```

This repository does not reliably host the required OpenSearch snapshot artifacts, resulting in Docker build failures.

Update the snapshot repository configuration to:

```
https://ci.opensearch.org/ci/dbc/snapshots/maven/
```

After updating the repository:

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
- `opensearch-build.patch`
- Locally built plugin snapshot ZIP files:
  - `opensearch-ml-3.3.0.0-SNAPSHOT.zip`
  - `opensearch-neural-search-3.3.0.0-SNAPSHOT.zip`
  - `opensearch-skills-3.3.0.0-SNAPSHOT.zip`
  - `opensearch-flow-framework-3.3.0.0-SNAPSHOT.zip`
  - `opensearch-security-3.3.0.0-SNAPSHOT.zip`
  - `query-insights-3.3.0.0-SNAPSHOT.zip`

Ensure all artifacts exist before proceeding.



## Modify Build Script

Edit the following file:

```
opensearch-build/docker/release/build-image-single-arch.sh
```

After the workspace creation section (after `$DIR` is created), add:

```bash
# Copy opensearch-build patch and plugin snapshots into workspace
cp -v dockerfiles/opensearch-build.patch $DIR/
cp -v dockerfiles/opensearch-ml-3.3.0.0-SNAPSHOT.zip $DIR/
cp -v dockerfiles/opensearch-neural-search-3.3.0.0-SNAPSHOT.zip $DIR/
cp -v dockerfiles/opensearch-skills-3.3.0.0-SNAPSHOT.zip $DIR/
cp -v dockerfiles/opensearch-flow-framework-3.3.0.0-SNAPSHOT.zip $DIR/
cp -v dockerfiles/opensearch-security-3.3.0.0-SNAPSHOT.zip $DIR/
cp -v dockerfiles/query-insights-3.3.0.0-SNAPSHOT.zip $DIR/
```

Optional (only if required):

```bash
# cp -v dockerfiles/opensearch-project-k-NN_3.3.0.0_ubi_9.6.sh $DIR/
# chmod +x $DIR/opensearch-project-k-NN_3.3.0.0_ubi_9.6.sh
```



## Build the Docker Image

```bash
cd opensearch-build/docker/release
./build-image-single-arch.sh -v 3.3.0 -p opensearch -a ppc64le -f dockerfiles/Dockerfile
```



## Verify the Image

```bash
docker images | grep opensearch
```




This completes the OpenSearch 3.3.0 Docker image build for ppc64le using locally generated snapshot plugin artifacts.
