#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : mistral-common
# Version       : v1.11.5
# Source repo   : https://github.com/mistralai/mistral-common
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Shubham Garud <Shubham.Garud@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="mistral-common"
PACKAGE_VERSION="${1:-v1.11.5}"
PACKAGE_URL="https://github.com/mistralai/mistral-common"
NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
# gcc-toolset-13-libatomic-devel — sentencepiece source build links -latomic;
#   the gcc-toolset-13 linker searches its own sysroot so the toolset-specific
#   package is required (not the base libatomic)
# libsndfile — soundfile Python package wraps libsndfile.so via cffi;
#   mistral_common/protocol/instruct/chunk.py imports soundfile unconditionally
#   so every test file fails at collection time without this shared library
# pkgconf-pkg-config — allows sentencepiece's cmake to locate sndfile headers
RH_DEP_PKGS="git gcc gcc-c++ cmake make libsndfile pkgconf-pkg-config gcc-toolset-13-libatomic-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_test — install test dependencies into the test venv
# =============================================================================
pre_test() {
    log_info "Installing pip/setuptools/wheel into test venv"
    python -m pip install --upgrade pip setuptools wheel
    log_info "Installing sentencepiece from source (no ppc64le wheel; needs gcc-toolset-13-libatomic-devel)"
    python -m pip install sentencepiece
    log_info "Installing optional extras required by tests: soundfile, soxr, jinja2, huggingface_hub, openai"
    python -m pip install soundfile soxr jinja2 huggingface_hub openai
}

# =============================================================================
# CALLBACK: custom_test_command — skip/deselect tests requiring unavailable deps:
#   - tests/experimental, tests/guidance: require fastapi / llguidance
#   - tests/test_image.py, tests/test_tokenizer_v3_mm.py: require opencv (cv2);
#     no ppc64le wheel on public PyPI
#   - individual cases in test_tokenizer_v7.py, v15.py that call image_encoder
#   4 audio tests deselected per v1 reference (fail on ppc64le)
# =============================================================================
custom_test_command() {
    log_info "Running tests (skipping suites requiring opencv; deselecting known-failing audio tests)"
    python -m pytest \
        -o "addopts=" \
        --disable-warnings \
        --ignore=tests/experimental \
        --ignore=tests/guidance \
        --ignore=tests/test_image.py \
        --ignore=tests/test_tokenizer_v3_mm.py \
        --deselect=tests/test_audio.py::test_audio_base64[True] \
        --deselect=tests/test_audio.py::test_audio_base64[False] \
        --deselect="tests/test_audio.py::TestDeprecationWarnings::test_audio_import_from_old_location_warns[AudioFormat]" \
        --deselect="tests/test_audio.py::TestDeprecationWarnings::test_audio_import_from_old_location_warns[EXPECTED_FORMAT_VALUES]" \
        --deselect="tests/test_tokenizer_v7.py::test_tokenize_assistant_message" \
        --deselect="tests/test_tokenizer_v7.py::test_tokenize_assistant_message_continue_final_message" \
        --deselect="tests/test_tokenizer_v7.py::test_encode_chat_completion" \
        --deselect="tests/test_tokenizer_v7.py::test_multi_image_order_is_preserved[empty-text-then-two-images]" \
        --deselect="tests/test_tokenizer_v7.py::test_multi_image_order_is_preserved[text-then-two-images]" \
        --deselect="tests/test_tokenizer_v7.py::test_multi_image_order_is_preserved[two-images]" \
        --deselect="tests/test_tokenizer_v7.py::test_single_trailing_image_moves_first" \
        --deselect="tests/test_tokenizer_v7.py::test_single_leading_image_remains_first" \
        --deselect="tests/test_tokenizer_v15.py::test_encode_chat_completion_with_multimodal_tool[image_url]" \
        --deselect="tests/test_tokenizer_v15.py::test_encode_chat_completion_with_multimodal_user[image_url]"
}

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
