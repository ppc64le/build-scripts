# Container Build Proposals - Future Architecture

**Status:** Proposal / Thumbtacked for later review
**Date:** 2026-03-29
**Context:** Nested container builds (kaniko/buildah inside build container) hitting namespace/permission issues

## Current Problem

Building container images from inside the build container fails due to:
- `cannot clone: Operation not permitted` - namespace restrictions
- Podman trying to set up local namespaces even when using Docker socket
- Kaniko requiring privileged mode that isn't available
- Complex fallback logic (kaniko → buildah → podman) adding maintenance burden

## Constraints

| Constraint | Impact |
|------------|--------|
| No Docker Hub access | Can't pull docker binaries or images from docker.com |
| UBI9 base images | Must work within Red Hat ecosystem |
| ppc64le architecture | Limited binary availability |
| Team maintainability | Harness already at maximum complexity |

## Proposed Architecture: Rootless Docker Island

### Concept

Instead of trying to build images from inside nested containers, use a rootless Docker daemon on the host that the build container can talk to via socket.

```
┌─────────────────────────────────────────────────────────┐
│ Host                                                     │
│                                                          │
│  ┌──────────────────────┐    ┌───────────────────────┐  │
│  │ Rootless Docker      │    │ Build Container       │  │
│  │ (user namespace)     │◄───│                       │  │
│  │                      │    │ - Compiles code       │  │
│  │ Socket:              │    │ - Runs tests          │  │
│  │ /run/user/UID/docker │    │ - Stages artifacts    │  │
│  │          .sock       │    │ - Calls docker build  │  │
│  └──────────────────────┘    │   (via socket)        │  │
│           │                  └───────────────────────┘  │
│           ▼                                              │
│  ┌──────────────────────┐                               │
│  │ Built Images         │                               │
│  │ (rootless storage)   │                               │
│  └──────────────────────┘                               │
└─────────────────────────────────────────────────────────┘
```

### One-Time Setup (per build node)

```bash
# As the build user (same UID that runs containers)
dockerd-rootless-setuptool.sh install

# Optionally enable as systemd user service
systemctl --user enable docker
systemctl --user start docker

# Socket location
export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock
```

### Per-Build Usage

Harness mounts the rootless socket into build container:

```bash
docker run --rm \
  -v /run/user/$(id -u)/docker.sock:/var/run/docker.sock \
  -v /build-scripts:/build-scripts \
  -v /output:/output \
  builder-image:latest \
  /build-scripts/a/apache-couchdb/apache-couchdb.sh
```

Inside build container, after build/test completes:

```bash
export DOCKER_HOST=unix:///var/run/docker.sock
docker build -t couchdb:3.4.2-ppc64le /path/to/context
```

### Security Surface

- Blast radius limited to rootless daemon's user namespace
- Not host root, just control of that user's containers/images
- Socket protected by file permissions
- Only mount socket into trusted build jobs

## Docker CLI Problem

Docker CLI (`docker` binary) is needed to talk to the daemon, but:
- Not in UBI9/RHEL repos
- Can't download from docker.com (enterprise policy)

### Option A: Build docker CLI from source

- moby/cli is Go, straightforward to build
- One-time build, add to base builder image
- ~15-20 MB binary

```bash
git clone https://github.com/docker/cli.git
cd cli
make binary
# Produces build/docker
```

### Option B: Curl to Docker API (No CLI needed)

Docker daemon exposes REST API over Unix socket. Can implement `docker build` equivalent with curl:

```bash
_docker_build() {
    local context_dir="$1"
    local image_tag="$2"
    local dockerfile="${3:-Dockerfile}"

    # Tar context and POST to build endpoint
    tar -C "${context_dir}" -c . | \
      curl --unix-socket /var/run/docker.sock \
        -X POST \
        -H "Content-Type: application/x-tar" \
        "http://localhost/v1.43/build?t=${image_tag}&dockerfile=${dockerfile}" \
        --data-binary @-
}

_docker_save() {
    local image_tag="$1"
    local output_file="$2"

    curl --unix-socket /var/run/docker.sock \
      "http://localhost/v1.43/images/${image_tag}/get" \
      -o "${output_file}"
}
```

**Pros:** No external binary, just curl (in UBI9)
**Cons:** More complex error handling, streaming output parsing

## Runtime-Only Dockerfile Pattern

### Concept

Instead of multi-stage Dockerfiles that rebuild from source, build scripts produce artifacts and stage them for a simple COPY-only Dockerfile.

### Current Multi-Stage (slow, duplicates work)

```dockerfile
FROM ubi9 AS builder
RUN dnf install ... && git clone ... && make ...

FROM ubi9
COPY --from=builder /build/output /opt/app
```

### Proposed Runtime-Only (fast, uses existing artifacts)

Build script stages artifacts:

```bash
prepare_container_context() {
    local ctx="${CONTAINER_OUTPUT_DIR}/context"
    mkdir -p "${ctx}"

    # Copy pre-built artifacts
    cp -a "$(artifact_dir erlang)/" "${ctx}/erlang/"
    cp -a "rel/couchdb/" "${ctx}/couchdb/"

    # Use runtime-only Dockerfile
    cp "${SCRIPT_DIR}/Dockerfile.runtime" "${ctx}/Dockerfile"
}
```

Dockerfile.runtime:

```dockerfile
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.3

ARG VERSION=3.4.2

# Runtime deps only (no compilers, no git)
RUN microdnf install -y openssl libicu libcurl ncurses-libs && \
    microdnf clean all

# Pre-built from build container
COPY erlang/ /opt/erlang/
COPY couchdb/ /opt/couchdb/

ENV PATH="/opt/erlang/bin:/opt/couchdb/bin:${PATH}"

RUN useradd -r -d /opt/couchdb couchdb && \
    chown -R couchdb:couchdb /opt/couchdb

EXPOSE 5984
USER couchdb
ENTRYPOINT ["/opt/couchdb/bin/couchdb"]
```

### Context Structure

```
${OUTPUT_DIR}/container-context/
├── Dockerfile
├── erlang/              # Pre-built Erlang runtime
│   ├── bin/
│   ├── lib/
│   └── erts-*/
├── couchdb/             # Pre-built CouchDB release
│   ├── bin/
│   ├── lib/
│   ├── etc/
│   └── share/
└── config/              # Optional custom configs
```

## Implementation Phases

### Phase 1: Infrastructure
- [ ] Set up rootless Docker on build nodes
- [ ] Decide: build docker CLI or use curl API approach
- [ ] Add docker CLI (or curl wrapper) to builder base image

### Phase 2: Framework
- [ ] Update container.sh to detect docker socket + CLI
- [ ] Add `prepare_container_context()` pattern to base template
- [ ] Create `Dockerfile.runtime` template/example

### Phase 3: Package Migration
- [ ] apache-couchdb: prototype runtime-only Dockerfile
- [ ] mongodb: second example
- [ ] Document pattern for other packages

## Decision Log

| Decision | Status | Notes |
|----------|--------|-------|
| Rootless Docker vs alternatives | Proposed | Cleanest privilege separation |
| Docker CLI source | TBD | Need to test moby/cli build on ppc64le |
| Curl API approach | TBD | Backup if CLI build problematic |
| Runtime-only Dockerfiles | Preferred | Faster builds, better separation |

## References

- Docker rootless mode: https://docs.docker.com/engine/security/rootless/
- Docker Engine API: https://docs.docker.com/engine/api/v1.43/
- moby/cli source: https://github.com/docker/cli

## Questions for Later

1. Is rootless dockerd already available on build infrastructure?
2. Can moby/cli be built on ppc64le without issues?
3. Should curl API wrapper be a fallback or primary approach?
4. How to handle multi-arch manifests in this model?
