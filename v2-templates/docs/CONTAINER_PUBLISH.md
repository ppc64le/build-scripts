# Container Build and Multi-Architecture Publishing

This guide covers building container images and publishing multi-architecture manifests to container registries like ICR, Quay.io, or Docker Hub.

## Quick Start

### Single Architecture Build

```bash
# Build with container image creation
./a/apache-couchdb/apache-couchdb.sh 3.4.2

# Output:
#   apache-couchdb:3.4.2-ppc64le        (local image)
#   /output/containers/apache-couchdb-3.4.2-ppc64le.tar  (OCI archive)
```

### Multi-Architecture Workflow

```bash
# 1. Build on each architecture (run on each machine)
./apache-couchdb.sh 3.4.2   # Creates image:version-ARCH

# 2. Collect archives from all architectures to one location
# 3. Create and push multi-arch manifest
source templates/lib/container.sh
manifest_create apache-couchdb 3.4.2
manifest_push apache-couchdb 3.4.2 icr.io/ppc64le-oss
```

## Configuration

### Enable Container Builds

**Option 1: Environment variable**
```bash
BUILD_CONTAINER=1 ./package.sh version
```

**Option 2: build_info.json**
```json
{
  "docker_build": true,
  "docker_image_name": "my-package",
  "docker_registry": "icr.io/namespace"
}
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `BUILD_CONTAINER` | Set to `1` to enable container builds | - |
| `CONTAINER_REGISTRY` | Registry for tagging (e.g., `icr.io/namespace`) | - |
| `CONTAINER_IMAGE_NAME` | Override image name | `PACKAGE_NAME` |
| `CONTAINER_OUTPUT_DIR` | Where to save archives | `/output/containers` |
| `CONTAINER_PUSH` | Set to `1` to push immediately after build | - |

## Architecture Naming

The library normalizes architecture names to OCI standard:

| `uname -m` | OCI Name | Tag Example |
|------------|----------|-------------|
| x86_64 | amd64 | `image:1.0.0-amd64` |
| aarch64 | arm64 | `image:1.0.0-arm64` |
| ppc64le | ppc64le | `image:1.0.0-ppc64le` |
| s390x | s390x | `image:1.0.0-s390x` |

## Build Output

Each architecture build creates:

```
/output/containers/
├── myimage-1.0.0-ppc64le.tar           # OCI archive
├── myimage-1.0.0-ppc64le.manifest      # Manifest fragment
└── myimage-1.0.0-ppc64le-registry.tar  # Registry-tagged archive (if registry set)
```

### Manifest Fragment

The `.manifest` file is a simple key-value file used for multi-arch assembly:

```bash
# Manifest fragment for myimage:1.0.0-ppc64le
IMAGE_NAME=myimage
VERSION=1.0.0
ARCH=ppc64le
RAW_ARCH=ppc64le
ARCHIVE=/output/containers/myimage-1.0.0-ppc64le.tar
REGISTRY_TAG=icr.io/namespace/myimage:1.0.0-ppc64le
```

## Multi-Architecture Manifests

### Creating a Manifest

After building on all target architectures:

```bash
# Source the library
source templates/lib/container.sh

# Auto-detect architectures from .manifest files
manifest_create myimage 1.0.0

# Or specify explicitly
manifest_create myimage 1.0.0 amd64 ppc64le arm64
```

### Pushing to Registry

```bash
# Push the multi-arch manifest
manifest_push myimage 1.0.0 icr.io/namespace

# This creates:
#   icr.io/namespace/myimage:1.0.0        (multi-arch manifest)
#   icr.io/namespace/myimage:latest       (multi-arch manifest)
```

### Manual Manifest Operations

```bash
# Inspect a manifest
buildah manifest inspect myimage:1.0.0

# Add an image to existing manifest
buildah manifest add myimage:1.0.0 myimage:1.0.0-s390x

# Remove a manifest
buildah manifest rm myimage:1.0.0
```

## Distributed Build Workflow

For CI/CD systems building on multiple architecture runners:

### Step 1: Build on Each Architecture

Each runner executes:
```bash
BUILD_CONTAINER=1 CONTAINER_REGISTRY=icr.io/namespace ./package.sh 1.0.0
```

### Step 2: Collect Artifacts

Gather from each runner:
- `myimage-1.0.0-ARCH.tar`
- `myimage-1.0.0-ARCH.manifest`

### Step 3: Assemble Manifest

On any machine with buildah:
```bash
# Load images from archives
for tar in /artifacts/myimage-1.0.0-*.tar; do
    podman load < "$tar"
done

# Create and push manifest
source templates/lib/container.sh
export PACKAGE_NAME=myimage
export PACKAGE_VERSION=1.0.0
export CONTAINER_OUTPUT_DIR=/artifacts

manifest_create
manifest_push myimage 1.0.0 icr.io/namespace
```

## Registry Authentication

### ICR (IBM Container Registry)

```bash
# Login to ICR
ibmcloud cr login

# Or with API key
echo "$ICR_API_KEY" | buildah login -u iamapikey --password-stdin icr.io
```

### Quay.io

```bash
buildah login -u "$QUAY_USER" -p "$QUAY_TOKEN" quay.io
```

### Docker Hub

```bash
buildah login -u "$DOCKER_USER" -p "$DOCKER_TOKEN" docker.io
```

## Writing a Dockerfile

### Basic Structure

```dockerfile
ARG BASE_IMAGE=registry.access.redhat.com/ubi9/ubi:latest
FROM ${BASE_IMAGE} AS builder

ARG VERSION=1.0.0
ARG PACKAGE_VERSION=1.0.0

# Build your package
WORKDIR /build
# ... build steps ...

# Runtime image
FROM ${BASE_IMAGE}
COPY --from=builder /build/output /app
# ... runtime config ...
```

### Using Version ARGs

The container library automatically passes these build args if your Dockerfile declares them:
- `VERSION`
- `PACKAGE_VERSION`

```dockerfile
ARG VERSION
RUN echo "Building version ${VERSION}"
```

### Multi-Architecture Considerations

For architecture-specific builds:

```dockerfile
# Detect architecture at build time
RUN ARCH=$(uname -m) && \
    case "${ARCH}" in \
        x86_64)  ARCH_NAME="amd64" ;; \
        aarch64) ARCH_NAME="arm64" ;; \
        ppc64le) ARCH_NAME="ppc64le" ;; \
        *)       ARCH_NAME="${ARCH}" ;; \
    esac && \
    curl -o binary "https://example.com/release/${ARCH_NAME}/binary"
```

## Helper Functions

### container_info

Display information about built images:

```bash
source templates/lib/container.sh
container_info myimage 1.0.0
```

### container_only_build

Build container without running the full package build:

```bash
CONTAINER_ONLY=1 ./package.sh 1.0.0
```

## Troubleshooting

### buildah not found

```bash
# RHEL/UBI
dnf install -y buildah

# Ubuntu/Debian
apt-get install -y buildah
```

### Permission denied pushing to registry

```bash
# Check login status
buildah login --get-login icr.io

# Re-authenticate
buildah login icr.io
```

### Manifest push fails

```bash
# Ensure all arch images exist locally
buildah images | grep myimage

# Verify manifest contents
buildah manifest inspect myimage:1.0.0
```

### Image not found for architecture

When creating a manifest, missing architectures are skipped with a warning. Ensure:
1. The image was built on that architecture
2. The archive was loaded with `podman load`
3. The tag format matches: `image:version-arch`

## Best Practices

1. **Use UBI base images** for enterprise deployments
2. **Multi-stage builds** to minimize final image size
3. **Non-root users** for security (see Elasticsearch Dockerfile example)
4. **Version labels** for traceability:
   ```dockerfile
   LABEL org.opencontainers.image.version="${VERSION}"
   LABEL org.opencontainers.image.source="https://github.com/..."
   ```
5. **Test locally** before pushing:
   ```bash
   podman run --rm myimage:1.0.0-ppc64le --version
   ```

## See Also

- [Buildah documentation](https://buildah.io/)
- [OCI Image Spec](https://github.com/opencontainers/image-spec)
- [PURL spec for container images](https://github.com/package-url/purl-spec/blob/master/PURL-TYPES.rst#oci)
