#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : rake-nltk
# Version       : master (PyPI: 1.0.6)
# Source repo   : https://github.com/csurfer/rake-nltk
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Pooja Shah <Pooaj.Shah4@ibm.com>
# -----------------------------------------------------------------------------
# Note: v1.0.6 is not tagged in GitHub; NOARCH mode installs directly from
#       PyPI (rake-nltk==1.0.6). The GitHub repo defaults to master branch.
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="rake-nltk"
# v1.0.6 has no GitHub tag; $1 is treated as the PyPI version to install.
# PACKAGE_VERSION is always master so the git checkout succeeds.
PYPI_VERSION="${1:-1.0.6}"
PACKAGE_VERSION="master"
PACKAGE_URL="https://github.com/csurfer/rake-nltk"

# Pure Python package — all wheels are py3-none-any; install from PyPI.
# PYPI_VERSION carries the release to install; PACKAGE_VERSION is the git ref.
NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: custom_test_command — requirements.txt pins py==1.10.0,
#           pytest==6.2.5, tox==3.24.3 which are incompatible with Python 3.12
#           (py apipkg crashes on __spec__). The template installs requirements.txt
#           AFTER pre_test(), so the fix must happen here, after that install step.
#           Also downloads required NLTK corpora: stopwords (default stop-word list),
#           punkt (used by nltk==3.6.2 via tokenizers/punkt/PY3/english.pickle), and
#           punkt_tab (used by newer nltk versions on Python 3.12).
# =============================================================================
custom_test_command() {
    log_info "Removing stale requirements.txt pins incompatible with Python 3.12"
    python -m pip uninstall -y py pytest tox
    log_info "Installing modern pytest"
    python -m pip install "pytest>=7.0"
    log_info "Downloading required NLTK corpora"
    python -c "import nltk; nltk.download('stopwords'); nltk.download('punkt'); nltk.download('punkt_tab')"
    log_info "Running tests"
    python -m pytest tests/ -o "addopts=" --disable-warnings
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"