"""
Version Fetchers Package

Unified version fetcher scripts for multiple package ecosystems.
All scripts support consistent command-line interface and CSV input format.

Available fetchers:
- fetch_npm_versions.py - Node.js packages from npm
- fetch_packagist_versions.py - PHP packages from Packagist
- fetch_maven_versions.py - Java packages from Maven Central
- fetch_pypi_versions.py - Python packages from PyPI
- fetch_go_versions_enhanced.py - Go modules from Go proxy + GitHub
- fetch_ruby_versions.py - Ruby gems from RubyGems.org

See README.md for detailed usage instructions.
"""

__version__ = "1.0.0"
__all__ = [
    "fetch_npm_versions",
    "fetch_packagist_versions",
    "fetch_maven_versions",
    "fetch_pypi_versions",
    "fetch_go_versions_enhanced",
    "fetch_ruby_versions",
]