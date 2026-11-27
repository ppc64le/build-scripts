# ClickHouse v26.8.27.9-lts on ppc64le (UBI 9.8)

ClickHouse built for IBM Power (ppc64le) on Red Hat UBI 9.8, as a build script and a Docker image. Needed by Instana.

## Status

| Check | Result |
|-------|--------|
| Build on Power10 | Pass |
| Unit tests | Pass: 23,581 passed, 0 failed, 4,753 skipped, 3 disabled |
| Docker image (built and tested on POWER9) | Pass |
| Docker image CVE scan (trivy, HIGH/CRITICAL) | 0 |

- **Disabled (3):** `UniqueKeyEncoding.DISABLED_MicrobenchUInt641M`, `DISABLED_MicrobenchString321M` and
  `DISABLED_MicrobenchCompoundUInt64String1M`. These are upstream timing benchmarks ("informational only; no gate")
  that upstream disables on all platforms. They were also run manually on Power10 with
  `--gtest_also_run_disabled_tests` and passed.
- **Skipped (4,753):** the tests skip themselves, for example tests that need an AI API key or x86-only code.
- **Not run:** functional and integration tests (the previous v26.3.9.8 script also ran only the unit tests), TLS, and a Power10-optimized Docker image.

## Files

- `clickhouse-v26.8.27.9-lts_ubi9.8.sh`: build script (builds, then runs unit tests)
- `clickhouse-v26.8.27.9-lts.patch`, `clickhouse-v26.8.27.9-lts-llvm-project.patch`: ppc64le patches
- `Dockerfiles/v26.8.27.9-lts_ubi_9/Dockerfile`: Docker build (compiled on UBI 9.8, runs on UBI 10.2)

## Build

Build script (run as root in a UBI 9.8 ppc64le container):

```
./clickhouse-v26.8.27.9-lts_ubi9.8.sh
```

Docker image:

```
docker build -t clickhouse:v26.8.27.9-lts Dockerfiles/v26.8.27.9-lts_ubi_9
```

## Run the Docker image

```
export CLICKHOUSE_PASSWORD='<choose-a-password>'
docker run -d --name clickhouse \
  -p 127.0.0.1:8123:8123 -p 127.0.0.1:9000:9000 \
  --ulimit nofile=262144:262144 \
  -e CLICKHOUSE_USER=tester -e CLICKHOUSE_PASSWORD="$CLICKHOUSE_PASSWORD" \
  -v clickhouse_data:/var/lib/clickhouse \
  clickhouse:v26.8.27.9-lts
```

Check it:

```
curl http://127.0.0.1:8123/ping
docker exec -it clickhouse clickhouse-client --user tester --password "$CLICKHOUSE_PASSWORD" -q "SELECT version()"
```
