"""
Database Migration Scripts for PowerCore.

This package contains all scripts needed to migrate the existing Cloudant
production database to the new normalized schema.

Directory Structure:
- fetchers/: External data fetchers (GitHub, PyPI, npm, Go, Maven)
- normalizers/: Data normalization utilities
- quality/: Quality scoring and validation
- deduplication/: Deduplication logic
- migration/: Migration orchestration
- utils/: Shared utilities (logging, rate limiting, retry)
"""

__version__ = "1.0.0"