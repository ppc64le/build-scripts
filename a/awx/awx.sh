#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : awx
# Version       : 24.6.1
# Source repo   : https://github.com/ansible/awx
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="awx"
PACKAGE_VERSION="${1:-24.6.1}"
PACKAGE_URL="https://github.com/ansible/awx"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git make openldap-devel openssl-devel python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""
# SETUPTOOLS_VERSION is fetched dynamically from pyproject.toml in post_clone

# =============================================================================
# CALLBACK: post_clone — write a conftest.py that calls django.conf.settings.configure()
#   Django's translation machinery reads settings.USE_I18N when formatting any
#   lazy-translated error message (gettext_lazy). Without settings configured,
#   any test that triggers a ValidationError failure path raises ImproperlyConfigured.
#   awx/conf/tests/unit/ has no conftest.py, so we inject a minimal one that
#   calls settings.configure() with USE_I18N=False before tests run.
# =============================================================================
post_clone() {
    # Fetch setuptools lower-bound from pyproject.toml, then cap at <81.
    # pyproject.toml declares: requires = ["setuptools>=45", ...]  (no upper bound).
    # setuptools>=81 removed pkg_resources entirely; awx/__init__.py does:
    #   import pkg_resources
    #   __version__ = pkg_resources.get_distribution('awx').version
    #   except pkg_resources.DistributionNotFound: ...
    # The except only catches DistributionNotFound — if pkg_resources is missing
    # the bare import raises ModuleNotFoundError, which propagates through
    # setuptools' config/expand.py when it resolves "version = attr: awx.get_version"
    # from setup.cfg, aborting the sdist/wheel build.
    if SETUPTOOLS_VERSION="$(grep -o '"setuptools[><=!][^"]*"' pyproject.toml | head -1 | tr -d '"')"; [[ -n "${SETUPTOOLS_VERSION}" ]]; then
        SETUPTOOLS_VERSION="${SETUPTOOLS_VERSION#setuptools}"
        SETUPTOOLS_VERSION="${SETUPTOOLS_VERSION//[[:space:]]/}"
        # Strip any existing upper bound from pyproject.toml and enforce <81:
        # setuptools>=81 removed pkg_resources; awx/__init__.py imports it unconditionally.
        SETUPTOOLS_VERSION="${SETUPTOOLS_VERSION%%,<*},<81"
        log_info "Using SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}' (from pyproject.toml, capped at <81)"
    else
        SETUPTOOLS_VERSION=">=45,<81"
        log_info "No setuptools pin found in pyproject.toml — using fallback '${SETUPTOOLS_VERSION}'"
    fi

    log_info "Writing minimal conftest.py to configure Django settings for unit tests"
    cat > awx/conf/tests/unit/conftest.py << 'EOF'
import django
from django.conf import settings

def pytest_configure(config):
    if not settings.configured:
        settings.configure(
            USE_I18N=False,
            USE_L10N=False,
            INSTALLED_APPS=[
                'django.contrib.contenttypes',
                'django.contrib.auth',
                'rest_framework',
            ],
            DATABASES={},
        )
        django.setup()
EOF
}

# =============================================================================
# CALLBACK: pre_build — pre-install build-system requirements from pyproject.toml
# =============================================================================
# pyproject.toml declares: requires = ["setuptools>=45", "setuptools_scm[toml]>=6.2"]
# The template uses --no-isolation, so these must be installed manually before build.
# SETUPTOOLS_VERSION is set dynamically from pyproject.toml by post_clone.
pre_build() {
    log_info "Installing build-system requirements declared in pyproject.toml"
    python -m pip install --upgrade pip wheel
    python -m pip install "setuptools${SETUPTOOLS_VERSION}" "setuptools_scm[toml]>=6.2"
}

# =============================================================================
# CALLBACK: pre_test — install build backend and minimal unit test dependencies
#   The full requirements/requirements.txt is NOT used — it includes grpcio,
#   uwsgi, xmlsec etc. which have no ppc64le wheels and require system libraries.
#   pytest-django is NOT installed: it always reads DJANGO_SETTINGS_MODULE from
#   pytest.ini (awx.main.tests.settings_for_test → development.py → split_settings
#   → ansible_base) regardless of django_find_project=false, causing ImportError.
# =============================================================================
pre_test() {
    log_info "Installing build backend in test venv"
    python -m pip install --upgrade pip wheel
    python -m pip install "setuptools${SETUPTOOLS_VERSION}" "setuptools_scm[toml]>=6.2"
    log_info "Installing minimal unit test dependencies for awx/conf/tests/unit/test_fields.py"
    # Pin pytest<8: pytest>=8 calls find_spec() on all meta path importers including
    # legacy VendorImporter (pkg_resources vendoring) which only has find_module(),
    # causing AttributeError on Python 3.9.
    # Pin django<5: URLValidator.ul was removed in Django 5.x; awx/conf/fields.py
    # references it at class definition time, so importing fields fails on Django>=5.
    python -m pip install \
        "pytest<8" \
        "django>=4.2,<5" \
        djangorestframework \
        cryptography
}

# =============================================================================
# CALLBACK: custom_test_command — run test_fields.py only
#
#   test_fields.py   : tests StringListBooleanField, StringListPathField,
#                      ListTuplesField, URLField — imports only awx.conf.fields
#                      and rest_framework.fields. Fully self-contained.
#
#   test_registry.py : EXCLUDED
#     awx/conf/tests/unit/test_registry.py imports SettingsWrapper from
#     awx/conf/settings.py, which has these top-level (module-load-time) imports:
#       import psycopg                              (PostgreSQL async driver, C extension)
#       from awx.conf.models import Setting         (→ awx/conf/models.py)
#       from awx.main.utils import encrypt_field    (→ entire awx.main stack)
#     awx/conf/models.py line 10:
#       from ansible_base.lib.utils.models import prevent_search
#     django-ansible-base is only available as a git dependency from the devel
#     branch (git+https://github.com/ansible/django-ansible-base@devel) — it
#     is not published on PyPI and cannot be installed in CI without the full
#     AWX development environment.
#
#   test_settings.py : EXCLUDED
#     awx/conf/tests/unit/test_settings.py imports awx.conf.models directly:
#       from awx.conf import models, fields
#     awx/conf/models.py has the same ansible_base import at module load time,
#     so the collection fails with ModuleNotFoundError: No module named 'ansible_base'
#     for the same reason as test_registry.py above.
#
#   -p no:django  : disables pytest-django plugin so it never reads
#                   DJANGO_SETTINGS_MODULE=awx.main.tests.settings_for_test
#                   from pytest.ini, which chains through development.py
#                   → split_settings → ansible_base → entire AWX stack
#   -o "addopts=" : clears pytest.ini's --reuse-db --nomigrations addopts
# =============================================================================
custom_test_command() {
    log_info "Running awx/conf/tests/unit/test_fields.py"
    log_info "NOTE: test_registry.py excluded — awx/conf/settings.py imports psycopg"
    log_info "      and awx/conf/models.py imports ansible_base (git-only dep, not on PyPI)"
    log_info "NOTE: test_settings.py excluded — awx/conf/models.py imports ansible_base"
    log_info "      (git+https://github.com/ansible/django-ansible-base@devel, not on PyPI)"
    python -m pytest \
        -p no:django \
        -o "addopts=" \
        --disable-warnings \
        awx/conf/tests/unit/test_fields.py
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
