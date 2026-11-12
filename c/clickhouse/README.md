# ClickHouse v26.8.27.9-lts - ppc64le (UBI 9.8)

## Overview

This directory contains the build script, patches, and Dockerfile to build and run
**ClickHouse v26.8.27.9-lts** (including ClickHouse Keeper) on IBM Power (ppc64le) using Red Hat UBI 9.8.

ClickHouse is required by Instana. This port was created to satisfy that dependency on IBM Power10.

---

## What was tested (Power10, UBI 9.8)

| Step | Result |
|------|--------|
| C++ build (CMake + Ninja, RELWITHDEBINFO, `-mcpu=power10 -mtune=power10`) | Pass (16,229 steps) |
| `clickhouse-keeper --version` (`ClickHouse keeper version 26.8.27.1`) and `clickhouse-keeper-client` present | Pass |
| Unit tests (`unit_tests_dbms`) | Pass: 28,334 tests in 676 suites ran, 23,581 passed, 0 failed, 4,753 skipped, 3 disabled |
| Docker image build and smoke test | Pass on a POWER9 host (not a Power10 image), see the Docker image section |

### Unit test notes

- The 4,753 skipped tests are skipped by the tests themselves (for example float-compressed non-float columns,
  tests that need an AI API key, x86-only SSE posting-list tests).
- The 3 disabled tests are upstream microbenchmarks in `src/Storages/MergeTree/UniqueKey/tests/gtest_unique_key_encoding.cpp`
  (`UniqueKeyEncoding.DISABLED_MicrobenchUInt641M`, `DISABLED_MicrobenchString321M`,
  `DISABLED_MicrobenchCompoundUInt64String1M`). Upstream marks them "informational only; no gate" and disables them
  with the googletest `DISABLED_` prefix, with no architecture `#if` in the file. They have no pass or fail criteria
  and were not run.
- `FindSymbols.RunTimeNeedle`: the upstream test expects success on non-SSE4.2 targets, but `SearchSymbols`
  throws for more than 16 symbols on every platform. `clickhouse-v26.8.27.9-lts.patch` makes the test always expect the throw.
- `ParserPRQL/ParserTest.parseQuery/0` and `/1`: with lld `--icf=safe` on ppc64le, the generated TOC-save stub for
  `malloc` jumped 64 KB below the real function, so the Rust allocator call used by the PRQL parser landed on a
  non-executable address and the test binary crashed. The patch does not pass `--icf=safe` on ppc64le.

### What was NOT tested

- Full functional test suite (`tests/clickhouse-test`) and integration tests.

---

## Build environment

- **Container**: `registry.access.redhat.com/ubi9/ubi:9.8`
- **Architecture**: `ppc64le` (Power10)
- **Compiler**: Clang/LLD 22.1.8 (CentOS 9-stream)
- **Rust toolchain**: `nightly-2026-03-22`
- **Build type**: `RELWITHDEBINFO`
- The script adds the `POWER10` cmake option only when POWER10 is detected in `/proc/cpuinfo` or `lscpu`.

---

## Patches applied

| Patch file | Reason |
|------------|--------|
| `clickhouse-v26.8.27.9-lts.patch` | `CMakeLists.txt`: adds `-Wframe-larger-than=131072` and skips `--icf=safe` on ppc64le (see the PRQL note above). `cmake/cpu_features.cmake`: removes the x86 `-D__SSE2__=1 -DNO_WARN_X86_INTRINSICS` macros, adds `-mabi=ibmlongdouble` (clang on EL9 defaults to IEEE128 `long double`, which gives undefined `*f128` symbols at link), adds a `POWER10` option (`-mcpu=power10 -mtune=power10`, Rust `target-cpu=pwr10`). `src/AggregateFunctions/CMakeLists.txt`: `-O1` for the three Student/Welch t-test files, which take 5+ hours at `-O3`. `src/Common/tests/gtest_find_symbols.cpp`: see above. |
| `clickhouse-v26.8.27.9-lts-llvm-project.patch` | `libunwind/src/UnwindRegistersSave.S`: adds the missing `xxswapd` after `stxvd2x` on ppc64le. |

---

## Docker image

The Dockerfile performs a two-stage build (UBI 9.8 build stage, UBI 9.8 runtime stage with only the `clickhouse`
binary and its OpenSSL libraries). It downloads the patch files from `ppc64le/build-scripts` master, so it only builds
after the patches are merged.

```
docker build -t clickhouse:v26.8.27.9-lts \
    -f Dockerfiles/v26.8.27.9-lts_ubi_9/Dockerfile .
```
The build adds `-D POWER10=1` only when a POWER10 CPU is detected, and `BUILD_JOBS` (default 4) limits the ninja
parallelism to keep peak RAM down (`--build-arg BUILD_JOBS=6` was used on the test host).

### Docker validation

- **Host**: POWER9, RHEL 9.8, so the image was built without `-mcpu=power10` (`RELEASE`, `-mcpu=power8`).
  It validates the Dockerfile steps. A Power10-optimized image was not built or tested.
- **Patches**: the two patch files were copied from the build context for the test instead of downloaded from
  `ppc64le/build-scripts` master (they only exist there after the PR is merged). The download path was not tested.
- **Build**: passed (15,701 ninja steps, about 2 h 40 min with 6 jobs). Image size 1.77 GB (the runtime stage
  installs the binary from the build stage with a BuildKit bind mount, so it is stored once).
- **Smoke tests that passed**:
  - `clickhouse-keeper --version` (`26.8.27.1`) and `system.build_options` (`VERSION_FULL`, `GIT_HASH 551899e2...`).
  - Server container: `/ping`, an HTTP query, creating a MergeTree table, inserting and querying 1,000,000 rows,
    runs as user `clickhouse` (uid 101) with no restarts.
  - Keeper container with a minimal user-supplied config: `ruok` returned `imok`, leader elected, and
    `clickhouse keeper-client` create, get and ls worked.
- **Notes**: the image ships no Keeper config, so Keeper needs `--config-file`. There is no `clickhouse-keeper-client`
  symlink in the image; use `clickhouse keeper-client`.
- **Further image checks (all passed)**: entrypoint with `CLICKHOUSE_USER`/`CLICKHOUSE_PASSWORD` (login works, wrong
  password rejected, HTTP basic auth works), `/docker-entrypoint-initdb.d` `.sql` and `.sh` scripts ran, data survives a
  container restart, server runs as uid 101, codecs (Delta, DoubleDelta, Gorilla, LZ4HC, ZSTD) round-trip 200,000 rows
  exactly, `OPTIMIZE`/`CHECK TABLE`, the t-test aggregate functions, hash functions, Decimal/Int128, and PRQL queries
  (PRQL needs `allow_experimental_prql_dialect=1`; invalid PRQL returns a clean error).
- **Server log**: no `<Fatal>` entries. On a fresh container the server logs `CertificateReloader` errors because
  `config.d/openssl.xml` (present in the image, most likely created by `clickhouse install`) points to `/etc/clickhouse-server/server.key`,
  which does not exist. TLS is not enabled by default, so this does not affect operation. Whether the v26.3.9.8 image
  does the same was not checked.
- **Not tested**: TLS with real certificates, multi-node Keeper.



---

## References

- Upstream: https://github.com/ClickHouse/ClickHouse/tree/v26.8.27.9-lts
- Instana issue: https://github.ibm.com/ppc64le-automation/isv-ecosystem/issues/181
