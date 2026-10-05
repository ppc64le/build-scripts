# Internal modules for build-migrate.py
# These are not intended to be called directly.
#
# Modules are imported lazily to avoid dependency issues.
# Import specific modules as needed:
#   from lib import version_matcher
#   from lib.version_matcher import VersionMatcher

# Core modules used by build-migrate.py
from . import analyze_migration_candidates
from . import filter_candidates
from . import migrate_to_template

# These are imported on-demand to avoid circular/missing dependencies:
# - version_matcher
# - version_substitution_tracker
# - analyze_missing_versions
# - csv_normalizer
# - intelligent_column_mapping (requires pandas)
