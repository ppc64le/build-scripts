#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pyarrow
# Version       : apache-arrow-19.0.1
# Source repo   : https://github.com/apache/arrow
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pyarrow"
PACKAGE_VERSION="${1:-apache-arrow-19.0.1}"
PACKAGE_URL="https://github.com/apache/arrow"

# Clone into 'arrow' directory
CLONE_DIR="arrow"

# =============================================================================
# Artifact Declaration - Consumer only
# =============================================================================
BUILD_DEPS="arrow:${PACKAGE_VERSION}"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel python3-pip cmake ninja-build"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_clone — verify the arrow artifact (auto-sourced via BUILD_DEPS)
#   provided ARROW_HOME and set build-time env vars for PyArrow feature flags
# =============================================================================
pre_clone() {
    # BUILD_DEPS already sourced the arrow artifact; fail loudly if it was missing
    : "${ARROW_HOME:?Arrow C++ artifact not found - build a/arrow/arrow.sh ${PACKAGE_VERSION} first}"
    log_info "Arrow C++ artifact found at ${ARROW_HOME}"

    # Extract version number from tag (apache-arrow-19.0.0 -> 19.0.0)
    local version="${PACKAGE_VERSION#apache-arrow-}"
    export SETUPTOOLS_SCM_PRETEND_VERSION="${version}"

    # PyArrow build configuration
    export PYARROW_WITH_FLIGHT=1
    export PYARROW_WITH_PARQUET=1
    export PYARROW_WITH_ORC=1
    export PYARROW_WITH_DATASET=1
    export PYARROW_WITH_HDFS=1
    export PYARROW_WITH_GANDIVA=0
    export PYARROW_WITH_PLASMA=0
    export PYARROW_WITH_S3=0
    export PYARROW_WITH_CUDA=0

    # Build settings
    export PYARROW_BUILD_TYPE=release
    export PYARROW_BUNDLE_ARROW_CPP=0
    export PYARROW_BUNDLE_ARROW_CPP_HEADERS=0
    export PYARROW_CMAKE_GENERATOR=Ninja
    export PYARROW_PARALLEL="$(nproc)"

    # Arrow paths (should be set by source_artifact, but ensure they're correct)
    export CMAKE_PREFIX_PATH="${ARROW_HOME}:${CMAKE_PREFIX_PATH:-}"
    export PARQUET_HOME="${ARROW_HOME}"
}

# =============================================================================
# CALLBACK: post_clone — set test data paths and change to python/ subdirectory
# =============================================================================
post_clone() {
    # Set test data paths (relative to repo root)
    export PARQUET_TEST_DATA="${PWD}/cpp/submodules/parquet-testing/data"
    export ARROW_TEST_DATA="${PWD}/testing/data"

    # Change to python/ subdirectory — template will run pip install from here
    cd python

    # Fix Cython 3.1+ nogil Python coercion bug in pyarrow/table.pxi (apache/arrow#49138)
    # Present in Arrow <= 23.0.0, fixed upstream in 23.0.1.
    if [[ -f "pyarrow/table.pxi" ]]; then
        python3 -c '
path = "pyarrow/table.pxi"
with open(path, "r") as f:
    content = f.read()
import re
pattern = r"([ \t]*)with nogil:\s*\n([ \t]*)options\.unify_schemas = promote_options != ([\"'\''].*?[\"'\''])"
def repl(m):
    indent = m.group(1)
    val = m.group(3)
    return f"{indent}options.unify_schemas = promote_options != {val}\n{indent}with nogil:"
new_content = re.sub(pattern, repl, content)
if new_content != content:
    with open(path, "w") as f:
        f.write(new_content)
'
    fi

    # Arrow 15.x declares `cdef object alloc_c_*(...) noexcept` in pyarrow/types.pxi.
    # Cython 3.x warns "noexcept clause is ignored for function returning Python
    # object", and the build runs cython with --warning-errors, so it is fatal.
    # Tags >= 18 already dropped the clause.  Only functions returning `object` are
    # touched; `cdef void ... noexcept` (capsule deleters) is valid and left as is.
    if [[ -f "pyarrow/types.pxi" ]]; then
        sed -i -E 's/^(cdef object [A-Za-z0-9_]+\(.*\)) noexcept:/\1:/' pyarrow/types.pxi
    fi
}

# =============================================================================
# Helper: install the correct Cython and numpy versions for the active Python
# and pyarrow version.  pandas is a test-only optional dep (pyproject.toml
# [project.optional-dependencies] test) — it is not installed here.
#
# Python version: integer major*100+minor (e.g. 3.13 → 313) for plain bash
# integer comparisons — consistent with numpy.sh / numexpr.sh convention.
# Package version: shell %% / # stripping — consistent with markupsafe.sh /
# numpy.sh convention.
#
# Version matrix:
#   Python ≥ 3.13                → Cython ≥ 3.2 (nogil coercion fix), numpy ≥ 2.0
#   Python < 3.13, pyarrow ≤ 23.0.0 → Cython < 3.1
#     Cython 3.1+ adds -Xfreethreading_compatible=True (arrow CMakeLists.txt ~L887)
#     which turns `options.unify_schemas = promote_options != "none"` inside
#     `with nogil:` in table.pxi into a fatal --warning-errors error.
#     Affected: 15.x, 18.x, 19.x, 20.x, 21.x, 22.x, 23.0.0
#     Fixed in: 23.0.1 (assignment moved before the nogil block)
#     See: apache/arrow#49138
#   Python < 3.13, pyarrow ≥ 23.0.1 → Cython ≥ 3.1, numpy 1.26.4
# =============================================================================
_install_cython_deps() {
    # Integer python version: 3.13 → 313, 3.11 → 311
    local _pyver
    _pyver=$(python -c "import sys; print(sys.version_info.major * 100 + sys.version_info.minor)")

    if [[ "${_pyver}" -ge 313 ]]; then
        log_info "Python ≥ 3.13 — Cython ≥ 3.2, numpy ≥ 2.0"
        python -m pip install "cython>=3.2" "numpy>=2.0" setuptools-scm ninja
    else
        # pyarrow < 23.0.1 must build with Cython < 3.1.  The build uses
        # --warning-errors, and Cython 3.1+ turns old constructs in these tags into
        # fatal errors (e.g. io.pxi '__getsegcount__ relates to the old Python 2
        # buffer protocol', types.pxi 'noexcept clause is ignored for function
        # returning Python object', and the nogil coercion in table.pxi).
        local _cython_spec="cython"
        local _pkg_ver=(${PACKAGE_VERSION#apache-arrow-})
        _pkg_ver=(${_pkg_ver//./ })
        if [[ ${_pkg_ver[0]} -lt 23 ]] || [[ ${_pkg_ver[0]} -eq 23 && ${_pkg_ver[1]} -eq 0 && ${_pkg_ver[2]} -lt 1 ]]; then
            _cython_spec="cython<3.1"
        fi
        log_info "Python < 3.13 — ${_cython_spec}, numpy 1.26.4"
        python -m pip install "${_cython_spec}" "numpy==1.26.4" setuptools-scm ninja
    fi
}

# =============================================================================
# Helper: source every transitive C++ artifact that libarrow depends on.
#
# Unversioned source_artifact takes the LAST glob match, which is wrong when
# several versions of one artifact coexist (e.g. libprotobuf 28.2 and 4.25.3 —
# "4.25.3" sorts after "28.2").  For libprotobuf, pick the artifact dir that
# actually ships the soname libarrow links against (read from its DT_NEEDED),
# so this follows whatever protobuf the arrow tag was built with.
# =============================================================================
_source_transitive_artifacts() {
    local _dep
    for _dep in grpc_cpp orc boost thrift utf8proc snappy zstd re2 \
                gflags c-ares abseil-cpp; do
        source_artifact "${_dep}" || log_warn "${_dep} artifact not found"
    done

    # libprotobuf: choose the version libarrow was linked against
    local _arrow_lib_dir="${ARTIFACT_WORKSPACE}/arrow"
    local _soname="" _env _d _found=0
    _soname=$(readelf -d "${_arrow_lib_dir}/${PACKAGE_VERSION}"/lib/lib*.so.*.*.* 2>/dev/null \
        | sed -n 's/.*Shared library: \[\(libprotobuf\.so[^]]*\)\].*/\1/p' | sort -u | head -1 || true)
    if [[ -n "${_soname}" ]]; then
        for _env in "${ARTIFACT_WORKSPACE}"/libprotobuf/*/env.sh; do
            _d="$(dirname "${_env}")"
            if [[ -e "${_d}/lib64/${_soname}" || -e "${_d}/lib/${_soname}" ]]; then
                log_info "Sourcing libprotobuf from ${_d} (provides ${_soname})"
                source "${_env}"
                _found=1
                break
            fi
        done
    fi
    if [[ "${_found}" -eq 0 ]]; then
        log_warn "No libprotobuf artifact provides '${_soname}' — falling back to unversioned"
        source_artifact libprotobuf || log_warn "libprotobuf artifact not found"
    fi

    # Arrow last — keeps ARROW_HOME / CMAKE_PREFIX_PATH authoritative
    source_artifact arrow "${PACKAGE_VERSION}" || log_warn "arrow artifact not found"
    log_info "LD_LIBRARY_PATH: ${LD_LIBRARY_PATH:-not set}"
}

# =============================================================================
# CALLBACK: pre_build — install Cython/numpy and prime LD_LIBRARY_PATH.
#
#   pyarrow uses the standard build path (python -m build --no-isolation),
#   NOT BUILD_WHEEL=true, so _process_and_package_wheels (auditwheel repair)
#   is called directly after the build — pre_wheel is never invoked.
#   LD_LIBRARY_PATH must be set HERE so it is inherited by both the build
#   subprocess and the subsequent auditwheel repair subprocess.
#
#   Sourcing only the arrow artifact is not sufficient: abseil, grpc,
#   protobuf, orc etc. each install .so files into their own artifact lib/.
#   source_artifact with no version picks whatever version is installed,
#   so this works across all arrow releases (11–23+).
# =============================================================================
pre_build() {
    # Tags like 15.x list "oldest-supported-numpy>=0.14" (unconditionally) in both
    # requirements-build.txt and pyproject.toml [build-system].  It pins
    # numpy==1.23.2, which (a) gets compiled from source on ppc64le and (b) fails
    # the --no-isolation dependency check once numpy 1.26.4 is installed:
    #   Unmet dependencies: oldest-supported-numpy>=0.14 -> numpy==1.23.2
    # Tags >= 18 already use "numpy>=1.25"; use the same requirement for older tags.
    # Lines with an environment marker (";python_version...") are left untouched.
    local _f
    for _f in requirements-build.txt pyproject.toml; do
        if [[ -f "${_f}" ]]; then
            sed -i -E 's/oldest-supported-numpy>=0\.14([^;]|$)/numpy>=1.25\1/' "${_f}"
        fi
    done

    # Install the pinned Cython/numpy first so the requirements below are already
    # satisfied by them (otherwise pip would fetch and build the latest numpy).
    _install_cython_deps

    if [[ -f "requirements-build.txt" ]]; then
        log_info "Installing build requirements from requirements-build.txt"
        python -m pip install -r requirements-build.txt
    fi

    # Re-source all transitive C++ artifacts so auditwheel repair can locate
    # every .so file (e.g. libabsl_cordz_info.so.2407.0.0, libgrpc.so, …)
    log_info "Re-sourcing transitive C++ artifacts for auditwheel repair..."
    _source_transitive_artifacts
}

# =============================================================================
# CALLBACK: pre_test — install test deps and prime LD_LIBRARY_PATH.
#
#   pyarrow.lib is a C extension that dlopens libarrow.so and its transitive
#   deps (libabsl_*.so, libgrpc.so, …) at import time.  The test venv is
#   isolated from the build venv, so LD_LIBRARY_PATH is not carried over.
#   Without re-sourcing the artifacts here Python raises:
#     ModuleNotFoundError: No module named 'pyarrow.lib'
# =============================================================================
pre_test() {
    log_info "Installing build backend and mirrored build deps into test venv"
    python -m pip install --upgrade pip setuptools wheel

    # pyarrow/conftest.py in tags < 20 declares pytest_ignore_collect(path, config).
    # pytest 9.0 turns PytestRemovedIn9Warning ("(path: py.path.local) argument is
    # deprecated") into an error at conftest load, and 9.1 removes the argument
    # (PluginValidationError).  pytest 8.x only warns.  Tags >= 20 already use
    # collection_path.  Pin pytest only where the old signature is used.
    local _pkg_major
    _pkg_major="${PACKAGE_VERSION#apache-arrow-}"
    _pkg_major="${_pkg_major%%.*}"
    local _pytest_spec="pytest"
    # Older pyarrow tests do not work with newer pandas: pandas 3 breaks the
    # test_dataset.py fixtures, and pandas 2.3 breaks two test_pandas.py tests
    # (test_binary_column_name, test_roundtrip_with_bytes_unicode) that upstream
    # only skips for pandas < 2.3.  Use pandas 2.2.x for these tags.
    local _pandas_spec="pandas"
    if [[ "${_pkg_major}" -lt 20 ]]; then
        _pytest_spec="pytest<9"
        _pandas_spec="pandas<2.3"
        log_info "pyarrow ${_pkg_major}.x uses pytest_ignore_collect(path, ...) — pinning ${_pytest_spec}"
    fi

    log_info "Installing test requirements"
    python -m pip install "${_pytest_spec}" "${_pandas_spec}" hypothesis
    if [[ -f "requirements-test.txt" ]]; then
        python -m pip install -r requirements-test.txt
    fi

    _install_cython_deps

    # Re-source all transitive C++ artifacts so the dynamic linker can find
    # libarrow.so, libabsl_*.so, libgrpc.so etc. when pyarrow.lib is imported
    log_info "Re-sourcing transitive C++ artifacts for runtime linking..."
    _source_transitive_artifacts

    # Restore test data paths in the test venv environment
    export PARQUET_TEST_DATA="${PWD}/../cpp/submodules/parquet-testing/data"
    export ARROW_TEST_DATA="${PWD}/../testing/data"

    # pyarrow/conftest.py auto-detects each test group by importing its module
    # (e.g. pyarrow.parquet.encryption) and a PYARROW_TEST_<GROUP> variable
    # OVERRIDES that detection.  So only ever set groups to OFF, never ON —
    # forcing ON for a module that was not built (parquet_encryption here) makes
    # its tests fail with AttributeError: 'NoneType' ... instead of skipping.
    #
    # CYTHON=OFF: the cython tests compile an extension that links libarrow.so.1900
    # by plain soname.  With the artifact libarrow.so.1900 on LD_LIBRARY_PATH next
    # to the auditwheel-bundled libarrow-<hash>.so, two copies of libarrow get
    # loaded and protobuf aborts: "File already exists in database: orc_proto.proto".
    # Upstream's own wheel test script (ci/scripts/python_wheel_unix_test.sh)
    # also sets PYARROW_TEST_CYTHON=OFF.
    export PYARROW_TEST_CYTHON=OFF
}

# =============================================================================
# CALLBACK: custom_test_command — run pyarrow tests with deselects for tests
#   that require unavailable services (S3, HDFS, CUDA, Gandiva, Plasma) or are
#   known to be flaky on ppc64le
# =============================================================================
custom_test_command() {
    log_info "Running pyarrow tests..."

    # Resolve the test directory from the installed package, not the source tree.
    # Running pytest from arrow/python/ causes the local pyarrow/ source directory
    # to shadow the installed package (no __init__.py for pyarrow.tests either),
    # producing: ModuleNotFoundError: No module named 'pyarrow.lib'
    # Fix: locate site-packages/pyarrow/tests and run from /tmp with an absolute
    # path — same pattern as llvmlite.sh in this repo.
    # The import must run from /tmp: the cwd is arrow/python, where the source
    # pyarrow/ (no compiled lib) would be imported instead of the installed wheel.
    local _test_dir
    _test_dir=$(cd /tmp && python -c "import pyarrow, os; print(os.path.join(os.path.dirname(pyarrow.__file__), 'tests'))")
    log_info "Running tests from installed package: ${_test_dir}"

    # pandas is unpinned (requirements-test.txt), so pip installs the newest one.
    # pandas >= 3 changes the default string dtype; pyarrow only gained support
    # for that (pandas-shim.pxi is_ge_v3_strict + test updates) in a later tag.
    # Detect it from the installed build instead of hardcoding versions: if pandas
    # is >= 3 and this pyarrow's shim lacks is_ge_v3_strict, its pandas-marked
    # tests are written for pandas < 3 and cannot pass — exclude only those.
    local _pandas_args=()
    local _pandas3_unsupported
    _pandas3_unsupported=$(cd /tmp && python -c "
import pandas, pyarrow.pandas_compat as pc
print(int(int(pandas.__version__.split('.')[0]) >= 3 and not hasattr(pc._pandas_api, 'is_ge_v3_strict')))" 2>/dev/null || echo 0)
    if [[ "${_pandas3_unsupported}" == "1" ]]; then
        log_warn "pandas >= 3 is installed but this pyarrow predates pandas 3 support — skipping pandas-marked tests"
        _pandas_args=(-m "not pandas")
    fi

    # pyarrow + pandas ≥ 3: two test_pandas tests assume datetime64[ns]
    # resolution for tz-aware timestamps but pandas 3 changed the default to
    # datetime64[us].  The pyarrow code is correct; the tests are stale w.r.t.
    # pandas 3.  Deselect rather than xfail so the exit code stays 0.
    local _pandas_major
    _pandas_major=$(cd /tmp && python -c "import pandas; print(pandas.__version__.split('.')[0])" 2>/dev/null || echo 0)
    if [[ "${_pandas_major}" -ge 3 ]]; then
        log_warn "pandas ≥ 3: skipping 2 tz datetime64 resolution tests"
        # -k with spaces word-splits when unquoted; PYTEST_ADDOPTS is parsed by
        # pytest itself as a single shell-quoted string so quoting is preserved.
        export PYTEST_ADDOPTS="-k 'not test_column_index_names_with_tz and not test_mismatch_metadata_schema'"
    fi

    # Test data (flight TLS certs, parquet fixtures) comes from the arrow repo
    # submodules; fail loudly rather than with a RuntimeError deep inside a test.
    [[ -d "${PARQUET_TEST_DATA:-}" ]] || log_warn "PARQUET_TEST_DATA not found: '${PARQUET_TEST_DATA:-}'"
    [[ -d "${ARROW_TEST_DATA:-}" ]]   || log_warn "ARROW_TEST_DATA not found: '${ARROW_TEST_DATA:-}'"

    # --ignore test_flight.py: Flight TLS/network tests are not runnable in the CI container
    # --ignore test_hdfs.py: requires a live HDFS cluster
    # --ignore test_s3fs.py: requires S3 (PYARROW_WITH_S3=0, no live S3 endpoint)
    # --ignore test_cuda.py: requires CUDA (PYARROW_WITH_CUDA=0, no GPU on ppc64le CI)
    # --ignore test_gandiva.py: Gandiva is not built (PYARROW_WITH_GANDIVA=0)
    # --ignore test_plasma.py: Plasma is not built (PYARROW_WITH_PLASMA=0)
    # --deselect test_hdfs_options: HDFS support needs libhdfs/a live cluster
    # --deselect test_s3_options: S3 support is not built (PYARROW_WITH_S3=0)
    cd /tmp
    python -m pytest "${_test_dir}" \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings \
        -v \
        "${_pandas_args[@]}" \
        --ignore="${_test_dir}/test_flight.py" \
        --ignore="${_test_dir}/test_hdfs.py" \
        --ignore="${_test_dir}/test_s3fs.py" \
        --ignore="${_test_dir}/test_cuda.py" \
        --ignore="${_test_dir}/test_gandiva.py" \
        --ignore="${_test_dir}/test_plasma.py" \
        --deselect="${_test_dir}/test_fs.py::test_hdfs_options" \
        --deselect="${_test_dir}/test_fs.py::test_s3_options"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

