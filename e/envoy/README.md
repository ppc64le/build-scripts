# Envoy 1.36.5 PPC64LE Test Exclusions

This file lists tests that are excluded or failing on PPC64LE, with the observed reasons.

## common
- `//test/common/network:io_socket_handle_impl_integration_test`
  - Requires outbound internet connectivity (connects to `1.1.1.1:80`). The VM/sandbox blocks external network access.

- `//test/common/tls:tls_throughput_benchmark_test`
  - Performance benchmark assumes deterministic CPU timing, thread affinity, and blocking TLS behavior. On PPC64LE (especially virtualized/debug environments) those assumptions do not hold, and the SSL_write assertion is invalid in this context. Upstream Envoy treats this benchmark as non-gating and excludes it on non-x86 platforms.

## config_test
- `//test/config_test:example_configs_test`
  - LUA filter disabled for power (in envoy source code)

## integration
- `//test/integration:tcp_proxy_integration_test`
  - “The test was failing because the expected certificate fingerprint was tied to the integration test certs. After the certs were regenerated, the peer certificate fingerprint changed, so the test expectation had to be updated. This is a test-data change, not a product behavior change.”

  File locations:
  The expectation is in tcp_proxy_integration_test.cc:1551
  The certs that drive the fingerprint are under certs

- `//test/integration:stats_integration_test`
  - Without cert generation, the test reports `server.days_until_first_cert_expiring = 0` and `days_until_expiry = -48`.
  - With cert generation, Envoy fails to load `.../expired_key.pem` because the private key does not match the certificate chain (`OPENSSL_internal:KEY_VALUES_MISMATCH`).

## extensions
- `//test/extensions/dynamic_modules:rust_sdk_doc_test`
  - Skipped.

- `//test/extensions/dynamic_modules/http:filter_test`
  - We refactored Rust build logic to allow dynamic modules to build on PPC64LE by setting explicit clang and bindgen options. Compilation works, but the dynamic metadata callbacks test fails at the Rust/C++ interface due to an FFI/ABI incompatibility.

- `//test/extensions/dynamic_modules/http:integration_test`
  - Crashes with a segmentation fault immediately after dynamic module callbacks (`new_http_filter` / `on_request_headers`). This points to an ABI or memory mismatch between Envoy and the Rust dynamic module, or a bad pointer crossing the ABI boundary during filter creation/callbacks. Stack trace symbolization is blocked by split-DWARF (fission) and `addr2line` errors (`DW_TAG_skeleton_unit`)