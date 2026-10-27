# Container Build Methods - Architecture and Tradeoffs

This document covers the multi-method container build system in `templates/lib/container.sh`.

## Overview

The container build system supports multiple build methods with automatic fallback:
- **kaniko** - Runs via Docker socket, outputs tar directly
- **buildah** - Native OCI builder, works rootless with proper namespace support
- **podman** - Fallback via Docker socket

Methods are tried in order specified by `CONTAINER_BUILD_METHODS` environment variable.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CONTAINER_BUILD_METHODS` | `buildah,podman` | Comma-separated list of methods to try in order |
| `KANIKO_IMAGE` | `local/kaniko-executor:ppc64le` | Kaniko executor image name |
| `BUILDAH_ISOLATION` | `chroot` (in container) | Buildah isolation mode |
| `BUILDAH_STORAGE_DRIVER` | `vfs` (in container) | Buildah storage driver |

## Method Comparison

| Aspect | kaniko | buildah | podman |
|--------|--------|---------|--------|
| **Runs as** | Container (via docker or podman) | Direct command | Direct command via socket |
| **Needs** | Docker socket + (docker OR podman) + kaniko image | buildah binary | Docker socket + podman |
| **Output** | Tar only | Local image + optional tar | Local image + optional tar |
| **Rootless** | Yes (via socket) | Needs namespace support | Yes (via socket) |
| **Nested container** | Works | Needs isolation=chroot | Works |

**Note:** Kaniko prefers docker CLI but falls back to podman if docker isn't available.

## Risk Evaluation

### High Risk

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Three untested code paths** | Silent failures in production | Each method needs dedicated test coverage |
| **Kaniko output differs** | Tar only, no local image - downstream scripts may expect `docker images` to show it | Document clearly; ensure tar-based workflow works end-to-end |
| **Docker socket security** | Kaniko via socket = root-equivalent access to host | Already accepted risk for podman fallback |

### Medium Risk

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Environment variable sprawl** | Multiple env vars to configure | Document in one place (this file) |
| **Fallback masking real errors** | Method fails for fixable reason, silently falls back | Log WHY each method failed, not just "failed" |
| **Inconsistent build args** | Methods may handle args subtly differently | Centralize arg construction |

### Low Risk

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Method order confusion** | User sets `podman,kaniko` expecting podman first | Document that order = priority |
| **Kaniko image version drift** | Image gets stale | Harness controls image name; not container.sh's problem |

## Code Complexity Evaluation

### Structure

```
container.sh
├── Detection functions
│   └── _method_available() - dispatcher for method checks
├── Build functions (one per method)
│   ├── _build_with_kaniko()
│   ├── _build_with_buildah()
│   └── _build_with_podman()
├── build_container() - orchestrator, loops through methods
├── Manifest functions (unchanged)
└── Utilities (unchanged)
```

### Maintainability Scorecard

| Factor | Score | Notes |
|--------|-------|-------|
| **Adding new method** | Easy | Add function + case statement |
| **Debugging** | Good | Isolate which `_build_with_X()` failed |
| **Testing** | Good | Test each method independently |
| **Understanding flow** | Medium | Read orchestrator, then specific method |

### Adding a New Build Method

1. Add detection logic to `_method_available()`:
   ```bash
   newmethod)
       command -v newmethod &>/dev/null
       ;;
   ```

2. Create `_build_with_newmethod()` function following existing patterns

3. Add case to `build_container()` orchestrator:
   ```bash
   newmethod)
       if _build_with_newmethod "${dockerfile}" "${context_dir}" "${arch_tag}" "${version}"; then
           return 0
       fi
       ;;
   ```

4. Update `CONTAINER_BUILD_METHODS` default if appropriate

## Output Consistency

All methods produce output in same location with same naming convention:
```
${CONTAINER_OUTPUT_DIR}/${image_name}-${version}-${arch}.tar
```

## Decision Record

**Date:** 2026-03-28

**Decision:** Implement full refactor with method dispatcher rather than minimal kaniko addition.

**Rationale:**
- Future unknowns with harness development
- Current buildah/podman methods need privilege changes under discussion
- Refactor future-proofs against those changes
- Shared code paths mean majority of code tested even if not all methods used
- Low overhead (~100 lines) for significant flexibility gain

**Alternatives Considered:**
- Minimal addition (+40 lines): Lower risk but harder to extend
- Keep current structure: Would require inline spaghetti for each new method
