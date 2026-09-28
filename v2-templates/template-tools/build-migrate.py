#!/usr/bin/env python3
"""
build-migrate - Unified build script migration tool

Consolidates the migration pipeline into a single command:
  analyze  -> Scan build-scripts repository for migration candidates
  filter   -> Filter candidates by language, distro, release
  migrate  -> Convert scripts to new template format
  run      -> Execute full pipeline (analyze + filter + migrate)

Usage:
    build-migrate analyze -b ../build-scripts
    build-migrate filter --language node --release 9 -o Node.csv
    build-migrate migrate --batch Node.csv -d ./output
    build-migrate run --language python -b ../build-scripts -d ./output

For detailed help on each command:
    build-migrate <command> --help
"""

import argparse
import sys
from pathlib import Path
from typing import Optional


# =============================================================================
# IMPORTS FROM EXISTING MODULES
# =============================================================================

# Add script directory to path for imports
SCRIPT_DIR = Path(__file__).parent.resolve()
sys.path.insert(0, str(SCRIPT_DIR))

# Import existing modules from lib/
try:
    from lib import analyze_migration_candidates as analyze_mod
    from lib import filter_candidates as filter_mod
    from lib import migrate_to_template as migrate_mod
except ImportError as e:
    print(f"Error importing modules: {e}", file=sys.stderr)
    print("Ensure lib/ directory exists with analyze_migration_candidates.py,", file=sys.stderr)
    print("filter_candidates.py, and migrate_to_template.py", file=sys.stderr)
    sys.exit(1)


# =============================================================================
# COLORS (consistent with other tools)
# =============================================================================

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    BOLD = '\033[1m'
    NC = '\033[0m'


def log_info(msg: str) -> None:
    print(f"{Colors.BLUE}[INFO]{Colors.NC} {msg}")


def log_success(msg: str) -> None:
    print(f"{Colors.GREEN}[OK]{Colors.NC} {msg}")


def log_warn(msg: str) -> None:
    print(f"{Colors.YELLOW}[WARN]{Colors.NC} {msg}")


def log_error(msg: str) -> None:
    print(f"{Colors.RED}[ERROR]{Colors.NC} {msg}", file=sys.stderr)


def log_header(msg: str) -> None:
    print(f"\n{Colors.BOLD}{'='*60}{Colors.NC}")
    print(f"{Colors.BOLD}{msg}{Colors.NC}")
    print(f"{Colors.BOLD}{'='*60}{Colors.NC}\n")


# =============================================================================
# ANALYZE COMMAND
# =============================================================================

def cmd_analyze(args) -> int:
    """Run the analyze stage"""
    log_header("Stage: Analyze Migration Candidates")

    # Build argument list for analyze module
    argv = []

    if args.base:
        argv.extend(['-b', str(args.base)])
    if args.output:
        argv.extend(['-o', str(args.output)])
    if args.language:
        argv.extend(['-l', args.language])
    if args.status:
        argv.extend(['-s', args.status])
    if args.csv:
        argv.append('-c')
    if args.priority:
        argv.append('--priority')

    # Parse and run
    parser = argparse.ArgumentParser()
    parser.add_argument('-b', '--base', type=Path)
    parser.add_argument('-o', '--output', type=Path, default=Path('./migration_analysis'))
    parser.add_argument('-l', '--language')
    parser.add_argument('-s', '--status', choices=['pending', 'migrated', 'unknown'])
    parser.add_argument('-c', '--csv', action='store_true')
    parser.add_argument('--priority', action='store_true')

    analyze_args = parser.parse_args(argv)

    # Resolve base directory
    if analyze_args.base:
        base_dir = analyze_args.base.resolve()
    else:
        base_dir = SCRIPT_DIR.parent

    if not base_dir.is_dir():
        log_error(f"Directory not found: {base_dir}")
        return 1

    # Create output directory
    analyze_args.output.mkdir(parents=True, exist_ok=True)

    # Load language CSV and create detector
    csv_path = SCRIPT_DIR / "pkg-lang.csv"
    lang_lookup = analyze_mod.LanguageLookup(csv_path)
    detector = analyze_mod.LanguageDetector(lang_lookup)

    log_info(f"Analyzing build scripts in: {base_dir}")
    print()

    # Find and analyze scripts
    scripts = []
    for script_path in sorted(base_dir.rglob("*.sh")):
        rel_path = str(script_path.relative_to(base_dir))
        if "/templates/" in rel_path or "/template-tools/" in rel_path:
            continue

        info = analyze_mod.analyze_script(script_path, base_dir, detector)
        if info is None:
            continue

        # Apply filters
        if analyze_args.language and info.language != analyze_args.language.lower():
            continue
        if analyze_args.status and info.status != analyze_args.status:
            continue

        scripts.append(info)
        print(f"{info.relative_path:<60} | {info.language:<8} | {info.language_source:<12} | {info.status:<8}")

    # Sort by priority if requested
    if analyze_args.priority:
        scripts.sort(key=lambda s: s.priority)

    # Write output files
    candidates_file = analyze_args.output / "migration_candidates.txt"
    analyze_mod.write_candidates_file(scripts, candidates_file, analyze_args.csv)

    if analyze_args.priority:
        priority_file = analyze_args.output / "priority_list.txt"
        analyze_mod.write_priority_file(scripts, priority_file)

    summary_file = analyze_args.output / "migration_summary.md"
    analyze_mod.write_summary_file(scripts, summary_file, base_dir)

    print()
    log_success(f"Analysis complete: {len(scripts)} scripts found")
    log_info(f"Output directory: {analyze_args.output}")

    return 0


# =============================================================================
# FILTER COMMAND
# =============================================================================

def cmd_filter(args) -> int:
    """Run the filter stage"""
    log_header("Stage: Filter Migration Candidates")

    # Determine input file
    if args.input:
        input_file = args.input
    else:
        input_file = SCRIPT_DIR / "migration_analysis" / "migration_candidates.txt"

    if not input_file.exists():
        log_error(f"Input file not found: {input_file}")
        log_info("Run 'build-migrate analyze' first to generate it.")
        return 1

    log_info(f"Reading candidates from: {input_file}")

    # Read and filter
    records = filter_mod.read_candidates(input_file)
    log_info(f"Loaded {len(records)} candidates")

    filtered = filter_mod.filter_candidates(
        records,
        language=args.language,
        distro=args.distro,
        release=args.release,
    )

    log_info(f"After filtering: {len(filtered)} candidates")

    # Write output
    if args.output:
        with open(args.output, 'w', encoding='utf-8', newline='') as f:
            count = filter_mod.write_output(filtered, f)
        log_success(f"Wrote {count} records to: {args.output}")
    else:
        filter_mod.write_output(filtered, sys.stdout)

    return 0


# =============================================================================
# MIGRATE COMMAND
# =============================================================================

def cmd_migrate(args) -> int:
    """Run the migrate stage"""
    log_header("Stage: Migrate Scripts to Template Format")

    # Validate arguments
    if not args.target and not args.batch:
        log_error("No target path or batch file specified")
        log_info("Use --batch <file.csv> or provide a target path")
        return 1

    if args.batch and not args.base:
        log_error("--base is required when using --batch")
        return 1

    # Resolve templates directory
    if args.template_dir:
        templates_dir = args.template_dir.resolve()
    else:
        sibling_templates = (SCRIPT_DIR / ".." / "templates").resolve()
        parent_templates = SCRIPT_DIR.parent.resolve()

        if sibling_templates.exists() and (sibling_templates / "lib").exists():
            templates_dir = sibling_templates
        elif (parent_templates / "lib").exists():
            templates_dir = parent_templates
        else:
            templates_dir = sibling_templates

    if not templates_dir.exists() or not (templates_dir / "lib").exists():
        log_error(f"Templates lib directory not found: {templates_dir}/lib")
        log_info("Use --template-dir to specify the V2 templates directory")
        return 1

    # Initialize stats
    stats = migrate_mod.MigrationStats()
    mapping_entries = []

    # Initialize version matcher (if enabled)
    version_matcher = None
    no_version_fix = getattr(args, 'no_version_fix', False)
    if not no_version_fix:
        from lib.version_matcher import VersionMatcher
        version_data_dir = getattr(args, 'version_data', None)
        if version_data_dir is None:
            version_data_dir = SCRIPT_DIR / "version_data"
        if version_data_dir.exists():
            version_matcher = VersionMatcher(version_data_dir)
            log_info(f"Version matching enabled (data: {version_data_dir})")
        else:
            log_warn(f"Version data directory not found: {version_data_dir}")
            log_warn("Version matching disabled (use --version-data to specify)")

    # Copy templates for batch mode
    if args.batch and not args.scan:
        migrate_mod.copy_templates_to_dest(templates_dir, args.dest, args.dry_run, args.verbose)
        migrate_mod.copy_template_tools_to_dest(SCRIPT_DIR, args.dest, args.dry_run, args.verbose)

    # Process based on input type
    base_dir = args.base.resolve() if args.base else None

    # Set base_dir on version_matcher for relative path output
    if version_matcher and base_dir:
        version_matcher.base_dir = base_dir

    if args.batch:
        mapping_entries = migrate_mod.process_batch_file(
            args.batch, base_dir, args.dest, templates_dir, stats,
            args.language, args.dry_run, args.force, args.verbose,
            version_matcher,
        )
    elif args.target:
        if args.target.is_dir():
            migrate_mod.process_directory(
                args.target, args.dest, templates_dir, stats,
                args.scan, args.language, args.dry_run, args.force, args.verbose,
                version_matcher,
            )
        elif args.target.is_file():
            stats.total = 1
            output_path = args.dest / args.target.name
            success, msg = migrate_mod.migrate_script(
                args.target, output_path, templates_dir,
                args.language, args.dry_run, args.force, args.verbose,
                version_matcher,
            )
            if success:
                stats.migrated += 1
            elif msg in ["Already migrated", "Output exists"]:
                stats.skipped += 1
            else:
                stats.failed += 1
        else:
            log_error(f"Target not found: {args.target}")
            return 1

    # Print summary
    print()
    log_info("=== Migration Summary ===")
    log_info(f"Total scripts:      {stats.total}")
    log_info(f"Migrated:           {stats.migrated}")
    log_info(f"Skipped:            {stats.skipped}")
    log_info(f"Failed:             {stats.failed}")
    log_info(f"Assets copied:      {stats.assets_copied}")

    # Generate report if requested
    if args.report:
        if args.dry_run:
            report_path = Path("./migration_report.md")
        else:
            report_path = args.dest / "templates" / "template-tools" / "migration_report.md"
        migrate_mod.generate_report(report_path, stats, None, args.dest)

    # Write mapping file
    if mapping_entries:
        if args.mapping_output:
            mapping_path = args.mapping_output
        elif args.dry_run:
            mapping_path = Path("./advanced_mapping.csv")
        else:
            mapping_path = args.dest / "templates" / "template-tools" / "advanced_mapping.csv"
        migrate_mod.write_advanced_mapping(mapping_path, mapping_entries)

    # Write version warnings file if there are any
    if version_matcher and version_matcher.warnings:
        if args.dry_run:
            warnings_path = Path("./version_warnings.txt")
        else:
            warnings_path = args.dest / "templates" / "template-tools" / "version_warnings.txt"
        warnings_count = version_matcher.write_warnings(warnings_path)
        log_warn(f"Version warnings: {warnings_count} unconfirmed versions (see {warnings_path})")

    # Write github_tags_missing file if there are any
    if version_matcher and version_matcher.github_tags_missing:
        if args.dry_run:
            missing_path = Path("./github_tags_missing.csv")
        else:
            missing_path = args.dest / "templates" / "template-tools" / "github_tags_missing.csv"
        missing_count = version_matcher.write_github_tags_missing(missing_path)
        log_warn(f"GitHub tags missing: {missing_count} packages not in github_tags_mapping.json (see {missing_path})")

    # Write version substitutions tracking file if any substitutions were made
    if version_matcher and version_matcher.substitution_tracker:
        if version_matcher.substitution_tracker.substitutions:
            if args.dry_run:
                subs_path = Path("./version_substitutions.csv")
            else:
                subs_path = args.dest / "templates" / "template-tools" / "version_substitutions.csv"
            subs_count = version_matcher.write_substitutions(subs_path)
            log_warn(f"Version substitutions: {subs_count} packages updated to newer versions (see {subs_path})")
            version_matcher.print_substitution_summary()

    return 1 if stats.failed > 0 else 0


# =============================================================================
# RUN COMMAND (FULL PIPELINE)
# =============================================================================

def cmd_run(args) -> int:
    """Run the full pipeline (analyze + filter + migrate)"""
    log_header("Running Full Migration Pipeline")

    # Parse stages
    if args.stages:
        stages = [s.strip().lower() for s in args.stages.split(',')]
    else:
        stages = ['analyze', 'filter', 'migrate']

    log_info(f"Stages to run: {', '.join(stages)}")

    # Validate required arguments
    if not args.base:
        log_error("--base is required for the pipeline")
        return 1

    if not args.dest:
        log_error("--dest is required for the pipeline")
        return 1

    # Set up intermediate files
    analysis_dir = Path("./migration_analysis")
    filtered_csv = Path("./filtered_candidates.csv")

    # Override with explicit paths if provided
    if args.analysis_output:
        analysis_dir = args.analysis_output
    if args.filter_output:
        filtered_csv = args.filter_output

    ret = 0

    # Stage 1: Analyze
    if 'analyze' in stages:
        log_info("Running analyze stage...")
        args.output = analysis_dir
        args.csv = True  # Always use CSV for pipeline
        args.status = None
        args.priority = True
        ret = cmd_analyze(args)
        if ret != 0:
            log_error("Analyze stage failed")
            return ret
        print()

    # Stage 2: Filter
    if 'filter' in stages:
        log_info("Running filter stage...")
        args.input = analysis_dir / "migration_candidates.txt"
        args.output = filtered_csv
        ret = cmd_filter(args)
        if ret != 0:
            log_error("Filter stage failed")
            return ret
        print()

    # Stage 3: Migrate
    if 'migrate' in stages:
        log_info("Running migrate stage...")
        args.batch = filtered_csv
        args.target = None
        args.scan = False
        args.report = True
        ret = cmd_migrate(args)
        if ret != 0:
            log_error("Migrate stage failed")
            return ret

    log_header("Pipeline Complete")
    return ret


# =============================================================================
# MAIN
# =============================================================================

def main() -> int:
    parser = argparse.ArgumentParser(
        prog='build-migrate',
        description='Unified build script migration tool',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Commands:
  analyze   Scan repository for migration candidates
  filter    Filter candidates by language, distro, release
  migrate   Convert scripts to new template format
  run       Execute full pipeline (analyze + filter + migrate)

Examples:
  %(prog)s analyze -b ../build-scripts
  %(prog)s filter --language node --release 9 -o Node.csv
  %(prog)s migrate --batch Node.csv -b ../build-scripts -d ./output
  %(prog)s run --language python -b ../build-scripts -d ./output
  %(prog)s run --stages filter,migrate --language go -b ../build-scripts -d ./output
""",
    )

    subparsers = parser.add_subparsers(dest='command', help='Command to run')

    # --- Analyze subcommand ---
    p_analyze = subparsers.add_parser('analyze', help='Scan repository for migration candidates')
    p_analyze.add_argument('-b', '--base', type=Path,
                          help='Build-scripts directory to analyze')
    p_analyze.add_argument('-o', '--output', type=Path, default=Path('./migration_analysis'),
                          help='Output directory (default: ./migration_analysis)')
    p_analyze.add_argument('-l', '--language',
                          help='Filter by language')
    p_analyze.add_argument('-s', '--status', choices=['pending', 'migrated', 'unknown'],
                          help='Filter by status')
    p_analyze.add_argument('-c', '--csv', action='store_true',
                          help='Output in CSV format')
    p_analyze.add_argument('--priority', action='store_true',
                          help='Sort by migration priority')

    # --- Filter subcommand ---
    p_filter = subparsers.add_parser('filter', help='Filter candidates by language, distro, release')
    p_filter.add_argument('-l', '--language',
                         help='Filter by language (python, node, go, java, etc.)')
    p_filter.add_argument('-d', '--distro',
                         help='Filter by distro (rhel, ubi, ubuntu, debian, sles)')
    p_filter.add_argument('-r', '--release',
                         help='Filter by release version (8, 9, 9.3, 20.04, etc.)')
    p_filter.add_argument('-i', '--input', type=Path,
                         help='Input candidates file (default: ./migration_analysis/migration_candidates.txt)')
    p_filter.add_argument('-o', '--output', type=Path,
                         help='Output CSV file (default: stdout)')

    # --- Migrate subcommand ---
    p_migrate = subparsers.add_parser('migrate', help='Convert scripts to new template format')
    p_migrate.add_argument('target', nargs='?', type=Path,
                          help='Script or directory to migrate')
    p_migrate.add_argument('-b', '--base', type=Path,
                          help='Old build-scripts source tree (required for --batch)')
    p_migrate.add_argument('-d', '--dest', type=Path, default=Path('./migrated_scripts'),
                          help='Destination for generated scripts')
    p_migrate.add_argument('--template-dir', type=Path,
                          help='V2 templates location')
    p_migrate.add_argument('-l', '--language',
                          help='Override language detection')
    p_migrate.add_argument('-r', '--report', action='store_true',
                          help='Generate detailed migration report')
    p_migrate.add_argument('-n', '--dry-run', action='store_true',
                          help='Show what would be done without making changes')
    p_migrate.add_argument('-f', '--force', action='store_true',
                          help='Overwrite existing migrated scripts')
    p_migrate.add_argument('-v', '--verbose', action='store_true',
                          help='Verbose output')
    p_migrate.add_argument('--scan', action='store_true',
                          help='Scan and report only, don\'t migrate')
    p_migrate.add_argument('--batch', type=Path,
                          help='Batch file (.csv or .list) with scripts to migrate')
    p_migrate.add_argument('--mapping-output', type=Path,
                          help='Output path for advanced_mapping.csv')
    p_migrate.add_argument('--version-data', type=Path,
                          help='Directory containing version data JSON files')
    p_migrate.add_argument('--no-version-fix', action='store_true',
                          help='Disable automatic version correction')

    # --- Run subcommand (full pipeline) ---
    p_run = subparsers.add_parser('run', help='Execute full pipeline')
    p_run.add_argument('-b', '--base', type=Path, required=True,
                      help='Build-scripts directory to analyze')
    p_run.add_argument('-d', '--dest', type=Path, required=True,
                      help='Destination for migrated scripts')
    p_run.add_argument('-l', '--language',
                      help='Filter by language')
    p_run.add_argument('--distro',
                      help='Filter by distro')
    p_run.add_argument('-r', '--release',
                      help='Filter by release version')
    p_run.add_argument('--stages',
                      help='Comma-separated stages to run (default: analyze,filter,migrate)')
    p_run.add_argument('--analysis-output', type=Path,
                      help='Output directory for analysis (default: ./migration_analysis)')
    p_run.add_argument('--filter-output', type=Path,
                      help='Output CSV from filter stage (default: ./filtered_candidates.csv)')
    p_run.add_argument('--template-dir', type=Path,
                      help='V2 templates location')
    p_run.add_argument('-n', '--dry-run', action='store_true',
                      help='Show what would be done without making changes')
    p_run.add_argument('-f', '--force', action='store_true',
                      help='Overwrite existing migrated scripts')
    p_run.add_argument('-v', '--verbose', action='store_true',
                      help='Verbose output')
    p_run.add_argument('--mapping-output', type=Path,
                      help='Output path for advanced_mapping.csv')
    p_run.add_argument('--version-data', type=Path,
                      help='Directory containing version data JSON files')
    p_run.add_argument('--no-version-fix', action='store_true',
                      help='Disable automatic version correction')

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return 1

    # Dispatch to command handler
    if args.command == 'analyze':
        return cmd_analyze(args)
    elif args.command == 'filter':
        return cmd_filter(args)
    elif args.command == 'migrate':
        return cmd_migrate(args)
    elif args.command == 'run':
        return cmd_run(args)
    else:
        parser.print_help()
        return 1


if __name__ == "__main__":
    sys.exit(main())
