#!/bin/bash
#
# Run All Version Fetchers
#
# This script runs the complete version fetching pipeline based on QUICKSTART.md.
# It processes all ecosystems and stores results in ../version_data/.
#
# Features:
# - Uses cached data (won't re-fetch already processed packages)
# - Validates each step
# - Provides progress updates
# - Generates summary report
#
# Usage:
#   ./run_all_fetchers.sh [--force]
#
# Options:
#   --force    Delete cache and re-fetch everything
#

# Note: Not using 'set -e' so we can continue processing all ecosystems even if one fails
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_DATA_DIR="$SCRIPT_DIR/../version_data"
BUILD_SCRIPTS_REPO="${BUILD_SCRIPTS_REPO:-$HOME/src/build-scripts-v2}"

# Check for --force flag
FORCE_REFETCH=false
if [[ "${1:-}" == "--force" ]]; then
    FORCE_REFETCH=true
    echo -e "${YELLOW}⚠️  Force mode enabled - will delete cache and re-fetch everything${NC}"
fi

# Function to print section headers
print_header() {
    echo ""
    echo -e "${BLUE}======================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}======================================================================${NC}"
    echo ""
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to print info
print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Function to check if file exists and show size
check_file() {
    local file=$1
    if [[ -f "$file" ]]; then
        local size=$(du -h "$file" | cut -f1)
        print_success "Found: $(basename $file) ($size)"
        return 0
    else
        print_error "Missing: $(basename $file)"
        return 1
    fi
}

# Function to count packages in JSON file
count_packages() {
    local file=$1
    if [[ -f "$file" ]]; then
        local count=$(python3 -c "import json; print(len(json.load(open('$file'))))" 2>/dev/null || echo "0")
        echo "$count"
    else
        echo "0"
    fi
}

# Start
print_header "PowerCore Version Fetcher Pipeline"
echo "Script directory: $SCRIPT_DIR"
echo "Version data directory: $VERSION_DATA_DIR"
echo "Build scripts repository: $BUILD_SCRIPTS_REPO"
echo ""

# Step 0: Check prerequisites
print_header "Step 0: Checking Prerequisites"

# Check Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    print_success "Python: $PYTHON_VERSION"
else
    print_error "Python 3 not found"
    exit 1
fi

# Check required Python packages
print_info "Checking Python packages..."
python3 -c "import requests" 2>/dev/null && print_success "requests installed" || print_error "requests not installed (pip install requests)"

# Check for build-scripts repository
print_info "Checking build-scripts repository..."
if [[ ! -d "$BUILD_SCRIPTS_REPO" ]]; then
    print_error "Build scripts repository not found: $BUILD_SCRIPTS_REPO"
    print_info "Set BUILD_SCRIPTS_REPO environment variable or ensure ~/src/build-scripts-v2 exists"
    exit 1
else
    print_success "Found: $BUILD_SCRIPTS_REPO"
fi

# Check for extract script
if [[ ! -f "$SCRIPT_DIR/extract_build_script_info.py" ]]; then
    print_error "extract_build_script_info.py not found"
    exit 1
else
    print_success "Found: extract_build_script_info.py"
fi

# Step 1: Generate input lists from build scripts
print_header "Step 1: Generating Input Lists from Build Scripts"

BUILD_SCRIPTS_CSV="$VERSION_DATA_DIR/build_scripts.csv"

print_info "Running: python3 extract_build_script_info.py --input $BUILD_SCRIPTS_REPO --output $BUILD_SCRIPTS_CSV"

if python3 "$SCRIPT_DIR/extract_build_script_info.py" \
    --input "$BUILD_SCRIPTS_REPO" \
    --output "$BUILD_SCRIPTS_CSV"; then
    print_success "Generated: $BUILD_SCRIPTS_CSV"
else
    print_error "Failed to extract build script info"
    exit 1
fi

# Generate ecosystem-specific lists
print_info "Generating ecosystem-specific lists..."
cd "$VERSION_DATA_DIR"

# Get header from CSV
header=$(head -1 "$BUILD_SCRIPTS_CSV")

for ecosystem_info in "Ruby:ruby2.list" "Go:go2.list" "Node:node2.list" "Python:python2.list" "Java:java2.list" "PHP:php2.list"; do
    IFS=':' read -r lang file <<< "$ecosystem_info"
    
    # Add header and filter by language
    echo "$header" > "$file"
    if grep ",${lang}," "$BUILD_SCRIPTS_CSV" >> "$file" 2>/dev/null; then
        lines=$(($(wc -l < "$file") - 1))  # Subtract header line
        print_success "$file ($lines packages)"
    else
        print_error "Failed to create $file"
    fi
done

cd "$SCRIPT_DIR"

# Step 2: Setup output directory
print_header "Step 2: Setting Up Output Directory"

if [[ ! -d "$VERSION_DATA_DIR" ]]; then
    mkdir -p "$VERSION_DATA_DIR"
    print_success "Created: $VERSION_DATA_DIR"
else
    print_success "Directory exists: $VERSION_DATA_DIR"
fi

# Handle force mode
if [[ "$FORCE_REFETCH" == true ]]; then
    print_info "Deleting existing cache files..."
    rm -f "$VERSION_DATA_DIR"/*_versions.json
    rm -f "$VERSION_DATA_DIR"/*_errors.json
    print_success "Cache cleared"
fi

# Step 3: Run fetchers for each ecosystem
print_header "Step 3: Running Version Fetchers"

cd "$SCRIPT_DIR"

# Array of ecosystems to process
declare -a ECOSYSTEMS=(
    "ruby:fetch_ruby_versions.py:ruby2.list"
    "go:fetch_go_versions_enhanced.py:go2.list"
    "npm:fetch_npm_versions.py:node2.list"
    "pypi:fetch_pypi_versions.py:python2.list"
    "maven:fetch_maven_versions.py:java2.list"
    "packagist:fetch_packagist_versions.py:php2.list"
)

# Track results
declare -A RESULTS
TOTAL=0
SUCCESS=0
FAILED=0

for ecosystem_info in "${ECOSYSTEMS[@]}"; do
    IFS=':' read -r ecosystem script input_file <<< "$ecosystem_info"
    
    echo ""
    echo -e "${BLUE}--- Processing: $ecosystem ---${NC}"
    
    # Check if script exists
    if [[ ! -f "$script" ]]; then
        print_error "Script not found: $script"
        RESULTS[$ecosystem]="MISSING_SCRIPT"
        ((FAILED++))
        ((TOTAL++))
        continue
    fi
    
    # Check if input file exists
    input_path="$VERSION_DATA_DIR/$input_file"
    if [[ ! -f "$input_path" ]]; then
        print_error "Input file not found: $input_file"
        RESULTS[$ecosystem]="MISSING_INPUT"
        ((FAILED++))
        ((TOTAL++))
        continue
    fi
    
    # Run the fetcher
    output_file="$VERSION_DATA_DIR/${ecosystem}_versions.json"
    errors_file="$VERSION_DATA_DIR/${ecosystem}_errors.json"
    
    print_info "Running: python3 $script"
    print_info "  Input:  $input_path"
    print_info "  Output: $output_file"
    print_info "  Errors: $errors_file"
    
    if python3 "$script" \
        --input "$input_path" \
        --output "$output_file" \
        --errors "$errors_file"; then
        
        print_success "Completed: $ecosystem"
        RESULTS[$ecosystem]="SUCCESS"
        ((SUCCESS++))
    else
        print_error "Failed: $ecosystem"
        RESULTS[$ecosystem]="FAILED"
        ((FAILED++))
    fi
    
    ((TOTAL++))
done

# Step 4: Validate outputs
print_header "Step 4: Validating Outputs"

echo "Checking generated files..."
echo ""

for ecosystem_info in "${ECOSYSTEMS[@]}"; do
    IFS=':' read -r ecosystem script input_file <<< "$ecosystem_info"
    
    echo -e "${BLUE}$ecosystem:${NC}"
    
    versions_file="$VERSION_DATA_DIR/${ecosystem}_versions.json"
    errors_file="$VERSION_DATA_DIR/${ecosystem}_errors.json"
    
    if [[ -f "$versions_file" ]]; then
        size=$(du -h "$versions_file" | cut -f1)
        count=$(count_packages "$versions_file")
        print_success "Versions: $count packages ($size)"
    else
        print_error "Versions file missing"
    fi
    
    if [[ -f "$errors_file" ]]; then
        size=$(du -h "$errors_file" | cut -f1)
        count=$(count_packages "$errors_file")
        if [[ "$count" -gt 0 ]]; then
            print_info "Errors: $count packages ($size)"
        else
            print_success "Errors: 0 packages"
        fi
    else
        print_info "No errors file (all succeeded)"
    fi
    
    echo ""
done

# Step 5: Generate summary report
print_header "Step 5: Summary Report"

echo "Execution Results:"
echo "  Total ecosystems: $TOTAL"
echo "  Successful: $SUCCESS"
echo "  Failed: $FAILED"
echo ""

echo "Individual Results:"
for ecosystem_info in "${ECOSYSTEMS[@]}"; do
    IFS=':' read -r ecosystem script input_file <<< "$ecosystem_info"
    result="${RESULTS[$ecosystem]}"
    
    case "$result" in
        "SUCCESS")
            echo -e "  ${GREEN}✓${NC} $ecosystem"
            ;;
        "FAILED")
            echo -e "  ${RED}✗${NC} $ecosystem"
            ;;
        "MISSING_SCRIPT")
            echo -e "  ${RED}✗${NC} $ecosystem (script not found)"
            ;;
        "MISSING_INPUT")
            echo -e "  ${RED}✗${NC} $ecosystem (input file not found)"
            ;;
        *)
            echo -e "  ${YELLOW}?${NC} $ecosystem (unknown status)"
            ;;
    esac
done

echo ""
echo "Output directory: $VERSION_DATA_DIR"
echo ""

# Calculate total size
if [[ -d "$VERSION_DATA_DIR" ]]; then
    total_size=$(du -sh "$VERSION_DATA_DIR" | cut -f1)
    print_info "Total data size: $total_size"
fi

# Final status
echo ""
if [[ $FAILED -eq 0 ]]; then
    print_header "✓ All Fetchers Completed Successfully"
    exit 0
else
    print_header "⚠ Some Fetchers Failed"
    exit 1
fi