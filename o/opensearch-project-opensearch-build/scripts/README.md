# PPC dependency version updates (OpenSearch 3.10.0 and 3.8.0)

Change OpenSearch, Security or OpenSAML dependency versions with one flag.
You do not edit upstream repositories and you do not regenerate the PPC source patches.

## How it works

Two stages. Nothing is applied until the matching component is checked out.

| Stage | Script | Runs | Does |
|-------|--------|------|------|
| A | `scripts/generate-dependency-patches.sh` | Host, in `build.sh` stage 4, after the base PPC patch | Fetches the upstream `gradle/libs.versions.toml` at the manifest ref, changes only the keys you selected, writes a patch per selected target. |
| B | `scripts/apply-dependency-patches.sh` | Inside the build container, from `BuilderFromSource.checkout()` | Applies that component's patches right after its git checkout, before its `build.sh` runs `./gradlew`. |

Stage B is wired in by a per-release hook patch for opensearch-build:

| Release | Hook patch | Applied after |
|---------|------------|---------------|
| 3.10.0 | `Dockerfiles/3.10.0_ubi9.7/ppc64le-3.10.0-dependency-patches.patch` | `ppc64le-3.10.0-ai-services.patch` |
| 3.8.0 | `Dockerfiles/3.8.0_ubi9.7/ppc64le-3.8.0-dependency-patches.patch` | `ppc64le-3.8.0-ai-services.patch` |

Guarantees:

- A patch is applied only to the component whose name matches its directory.
- Targets you did not select produce no patch, so that component is untouched.
- Applied patches are recorded in `<git-dir>/ppc-dependency-patches.applied`, so a re-run does not apply twice.
- `git apply --check` runs first. A failure stops that component's build.
- The existing PPC fixes in `builder_from_source.py` are unchanged and run after the dependency patches.

## Targets

| Target | Patched repo | Keys |
|--------|--------------|------|
| `opensearch` | OpenSearch | Any key in `[versions]`. |
| `security` | security | Any key in `[versions]` except the two OpenSAML keys. |
| `opensaml` | security | `open_saml`, `open_saml_shib` only. |

OpenSAML is not a manifest component. It is the `libs:opensaml` subproject of the
security Gradle build and reads the security catalog. Its patch is therefore applied
to the security checkout, as a second patch (`20-opensaml.patch`) after `10-security.patch`.

## Weekly update

1. Pick the key in the upstream `gradle/libs.versions.toml` `[versions]` table.
2. Run the build with one `--update <target>:<key>=<version>` per change:

   ```bash
   ./build.sh \
     --update security:guava=33.7.3-jre \
     --update opensaml:open_saml=5.2.4 \
     --update opensearch:joda=2.12.6
   ```

3. In Jenkins, pass the same entries in `DEPENDENCY_UPDATES`.
   The separator can be a comma, a space or a newline.

   ```text
   security:guava=33.7.3-jre,opensaml:open_saml=5.2.4
   ```

With no updates selected, no patch is generated and the build is unchanged.

## Base patches (3.8.0)

The 3.8.0 base patch already edits OpenSearch's `gradle/libs.versions.toml`
(`opensearch.patch`: jackson, netty, bouncycastle). A patch generated from the pristine
upstream catalog would not apply on top of it. Pass `--base-patch <component>=<file>`
to Stage A so it applies that patch's catalog hunk to the baseline first:

```bash
scripts/generate-dependency-patches.sh \
  --base-patch OpenSearch=opensearch.patch \
  --update opensearch:netty=4.1.130.Final ...
```

The component name must match the manifest name (`OpenSearch`, `security`).
`security.patch` does not touch the catalog, so 3.8.0 needs a base patch for `OpenSearch` only.
The 3.10.0 build does not need `--base-patch`.

## Verify the resolved version

A changed catalog line is not proof. Check what Gradle resolves in the component checkout:

```bash
# security (guava is forced in security's build.gradle, so it shows "(forced)")
./gradlew dependencyInsight --dependency guava --configuration runtimeClasspath

# OpenSAML subproject
./gradlew :libs:opensaml:dependencyInsight --dependency opensaml-core-api --configuration runtimeClasspath

# OpenSearch
./gradlew :server:dependencyInsight --dependency joda-time --configuration runtimeClasspath
```

If the resolved version differs from the one you set, look for a `force`, `strictly`
or `resolutionStrategy` entry in that component's `build.gradle`. It overrides the catalog.

## Error cases

Stage A exits non-zero for an unknown target, a key not in `[versions]`, a malformed entry,
or an OpenSAML key under `security` (and the reverse). Stage B exits non-zero when a patch
does not apply to the checked-out source, for example after the manifest ref moved.
Regenerate by re-running the build; Stage A always rebuilds from the current manifest ref.

## New release (for example 3.11.0)

1. Copy `ppc64le-3.10.0-dependency-patches.patch` into the new `Dockerfiles/<version>/` directory.
2. Regenerate it against the new opensearch-build tag if `builder_from_source.py` changed.
3. Copy the `--update` / `DEPENDENCY_UPDATES` handling, `DEPS_PATCH_FILE`, and the stage 4 mounts from `Dockerfiles/3.10.0_ubi9.7/build.sh`.
4. If the new base patch edits a catalog, add `--base-patch` for that component.
5. The two scripts are version independent. Do not copy them.
