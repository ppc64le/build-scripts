#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : tokenizers
# Version       : v0.21.1
# Source repo   : https://github.com/huggingface/tokenizers
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Build Scripts Team <build-scripts@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="tokenizers"
PACKAGE_VERSION="${1:-v0.21.1}"
PACKAGE_URL="https://github.com/huggingface/tokenizers"

# =============================================================================
# Artifact Declaration (Tier 0 - no artifact dependencies)
# =============================================================================
PROVIDES_ARTIFACT="tokenizers"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ make cmake openssl-devel python3 python3-devel python3-pip"
DEB_DEP_PKGS=""   # not yet validated on Debian/Ubuntu
SLES_DEP_PKGS=""  # not yet validated on SLES

# =============================================================================
# Build Configuration
# =============================================================================
LICENSE_SPDX="Apache-2.0"

# =============================================================================
# CALLBACK: pre_build — update Rust toolchain and install maturin build dependency
# =============================================================================
pre_build() {
    log_info "Updating Rust toolchain to stable..."
    rustup default stable
    rustup update stable
    log_info "Rust version: $(rustc --version)"
    log_info "Cargo version: $(cargo --version)"

    log_info "Installing maturin build dependency"
    python -m pip install maturin setuptools wheel
}

# =============================================================================
# CALLBACK: post_clone — navigate to Python bindings subdirectory
# =============================================================================
post_clone() {
    log_info "Changing to Python bindings directory: bindings/python/"
    cd bindings/python/
}

# =============================================================================
# CALLBACK: custom_install — build tokenizers wheel with maturin and install it
# =============================================================================
custom_install() {
    log_info "Using Python: $(python --version) from ${VIRTUAL_ENV}"

    log_info "Building wheel with maturin..."
    maturin build --release

    log_info "Installing built wheel..."
    python -m pip install target/wheels/*.whl

    log_info "tokenizers installed successfully"
}

# =============================================================================
# CALLBACK: pre_test — ensure Rust toolchain is active and install test dependencies
# =============================================================================
pre_test() {
    log_info "Updating Rust toolchain to stable for test environment..."
    rustup default stable

    log_info "Installing test dependencies"
    python -m pip install --upgrade pip setuptools wheel maturin

    log_info "Installing tokenizers wheel into test environment..."
    local wheel
    wheel=$(find target/wheels/ -name "*.whl" | head -1)
    if [[ -z "$wheel" ]]; then
        log_error "No built wheel found under target/wheels/ (expected CWD: bindings/python/)"
        return 1
    fi
    python -m pip install "$wheel"
}

# =============================================================================
# CALLBACK: custom_test_command — run tokenizers import and functional tests
# =============================================================================
custom_test_command() {
    log_info "Running tokenizers tests..."

    # Basic import test — tokenizers version is exposed via importlib.metadata, not __version__
    python -c "
import tokenizers
import importlib.metadata
print('tokenizers module imported successfully')
print('tokenizers module location:', tokenizers.__file__)
version = importlib.metadata.version('tokenizers')
print('tokenizers version:', version)
"

    # Functional validation: train a BPE tokenizer, encode, decode, save/load
    python -c "
from tokenizers import Tokenizer
from tokenizers.models import BPE
from tokenizers.trainers import BpeTrainer
from tokenizers.pre_tokenizers import Whitespace
import tempfile
import os

print('Testing tokenizers...')

tokenizer = Tokenizer(BPE(unk_token='[UNK]'))
tokenizer.pre_tokenizer = Whitespace()

corpus = ['Hello world', 'This is a test', 'Tokenizers are fast']

trainer = BpeTrainer(special_tokens=['[UNK]', '[CLS]', '[SEP]', '[PAD]', '[MASK]'])
tokenizer.train_from_iterator(corpus, trainer)

output = tokenizer.encode('Hello world')
assert len(output.ids) > 0, 'Encoding failed: no token IDs generated'
assert len(output.tokens) > 0, 'Encoding failed: no tokens generated'

decoded = tokenizer.decode(output.ids)
assert 'Hello' in decoded or 'hello' in decoded.lower(), f'Decoding failed: {decoded}'

with tempfile.NamedTemporaryFile(suffix='.json', delete=False, mode='w') as f:
    temp_path = f.name

try:
    tokenizer.save(temp_path)
    loaded = Tokenizer.from_file(temp_path)
    output2 = loaded.encode('Hello world')
    assert output2.ids == output.ids, 'Save/load failed: token IDs do not match'
finally:
    if os.path.exists(temp_path):
        os.unlink(temp_path)

print('tokenizers basic tests passed!')
"

    log_info "tokenizers tests passed"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
