# Wheel Bundled Library License Gaps

## Overview

When building Python wheels with native extensions, `auditwheel repair` bundles
shared libraries (`.so` files) into the wheel. These bundled libraries require
license documentation for compliance.

The `bundled-license-utils.sh` library automatically resolves licenses through:

1. **Artifact System** - Checks artifact manifests for custom-built libraries
2. **RPM Queries** - Queries `rpm -qf` and `rpm -q --qf "%{LICENSE}"` for system libs
3. **Filesystem Search** - Searches for LICENSE/COPYING files near library sources

## GitHub Actions on Ubuntu

When running builds on GitHub Actions with Ubuntu runners (not UBI containers),
**RPM license queries are not available**. This creates potential license gaps.

### What Works on Ubuntu

- Artifact system license resolution (if artifacts are available)
- Filesystem LICENSE/COPYING file search
- Libraries bundled from source builds with license files

### What Doesn't Work on Ubuntu

- RPM package license queries (`rpm -qf` not available)
- System library licenses that would normally come from RPM metadata

### Symptoms

You'll see warnings like:

```
[WARN] Running on Ubuntu - RPM license lookup not available
[WARN] Licenses will be resolved from artifact system and filesystem only
[WARN] See templates/docs/WHEEL_LICENSE_GAPS.md for more information
```

And potentially:

```
[WARN] LICENSE GAPS DETECTED
[WARN] The following bundled libraries have unresolved licenses:
[WARN]   - libgfortran-37ae8338.so.5.0.0
[WARN]   - libquadmath-5e7575c3.so.0.0.0
```

## Solutions for GitHub Actions

### Option 1: Use UBI Containers in GHA

Run your GHA workflows in UBI containers where RPM is available:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: registry.access.redhat.com/ubi9/ubi:latest
```

### Option 2: Pre-populate Artifact Database

If you have an artifact database with license information, ensure it's available
in the GHA environment:

```yaml
- name: Fetch artifact manifests
  run: |
    # Download artifact manifests with license info
    aws s3 sync s3://your-bucket/artifacts /opt/artifacts
```

### Option 3: Manual License Documentation

For libraries where automatic resolution fails, you can:

1. Create a `BUNDLED_LICENSES.txt` in your package source
2. Use a `post_build` hook to inject known licenses
3. Manually verify and document licenses post-build

## License File Locations

After processing, license files are added to the wheel's `.dist-info/` directory:

- `UBI_BUNDLED_LICENSES.txt` - Licenses from RPM queries (UBI/RHEL systems)
- `BUNDLED_LICENSES.txt` - Licenses from artifact system, filesystem search, or fallback markers

## Fallback Markers

When a license cannot be resolved, the library is marked in `BUNDLED_LICENSES.txt`:

```
Files: libexample-abc12345.so.1.0.0
libexample-abc12345.so.1.0.0_license_not_found
```

These markers indicate manual review is needed for compliance.

## Container Build System

The container build system (UBI-based) has full license resolution capabilities:

- RPM queries work for system libraries
- Artifact system provides licenses for custom builds
- Filesystem search catches remaining cases

No additional configuration is needed for container builds.
