#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : django
# Version       : 5.0.7
# Source repo   : https://github.com/django/django
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="django"
PACKAGE_VERSION="${1:-5.0.7}"
PACKAGE_URL="https://github.com/django/django"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel python3-pip libmemcached-awesome-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

NOARCH="true"

# =============================================================================
# CALLBACK: pre_test — Install test dependencies before running the test suite
# =============================================================================
pre_test() {
    # Python 3.12 changed argparse subparser error messages to omit repr()
    # quotes around choices: "choose from foo" vs old "choose from 'foo'".
    # Django 5.0.7's test uses assertRaisesMessage (exact match) against the
    # old quoted format. Fixed upstream in Django 5.0.10 (Refs #35844).
    # Apply the same 2-line fix here without modifying any other source.
    log_info "Installing test requirements..."
    python -m pip install -r tests/requirements/py3.txt
    python -m pip install "tblib<3.2"
    if [ "${PACKAGE_VERSION}" = "5.0.7" ]; then
        python -m pip install "asgiref==3.8.1"

        if python -c "import sys; sys.exit(0 if sys.version_info >= (3, 12) else 1)"; then
            python -c "
import pathlib
f = pathlib.Path('tests/user_commands/tests.py')
old = '''        msg = \"invalid choice: 'test' (choose from 'foo')\"
        with self.assertRaisesMessage(CommandError, msg):'''
new = r'''        msg = r\"invalid choice: 'test' \(choose from '?foo'?\)\"
        with self.assertRaisesRegex(CommandError, msg):'''
content = f.read_text()
if old in content:
    f.write_text(content.replace(old, new))
    print('Patched test_subparser_invalid_option for Python 3.12 compat')
else:
    print('Patch already applied or not needed')
"
        fi
    fi
}

# =============================================================================
# CALLBACK: custom_test_command — Run the Django test suite with custom settings
# =============================================================================
custom_test_command() {
    # Two Python 3.12 incompatibilities in Django 5.0.7 require workarounds:
    #
    # 1. MaybeEncodingError in parallel runner — CPython 3.12's argparse
    #    registers a local closure ('identity') that cannot be pickled across
    #    multiprocessing workers, so any worker exception causes a crash
    #    instead of a clean failure. Fixed in CPython 3.13.
    #    Workaround: --parallel=1 (single process, no pickling needed).
    #
    # 2. test_subparser_invalid_option — Python 3.12 removed repr() quotes
    #    from argparse subparser error messages: "choose from foo" instead of
    #    "choose from 'foo'". The 5.0.7 test uses assertRaisesMessage with
    #    the old quoted format and fails. Fixed upstream in Django 5.0.10
    #    (Refs #35844) by switching to assertRaisesRegex with '?foo'?.
    #    Workaround: patch the test to use assertRaisesRegex (same fix as
    #    Django 5.0.10) applied in pre_test() above.
    log_info "Running custom test command"
    cd tests/

    python runtests.py --settings=test_sqlite \
        --exclude-tag=gis \
        --parallel=1 \
        -v 2
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
