#!/usr/bin/env python3

import os
import sys
import re

def extract_script_metadata(script_path):
    """
    Extract metadata from script header comments.
    Returns dict with package_version, tested_on, ci_check, etc.
    """
    metadata = {
        'package_version': None,
        'tested_on': 'UBI:9.3',  # default
        'ci_check': 'true',  # default
        'package_name': None,
        'use_non_root_user': 'false'  # default
    }
    
    key_mapping = {
        '# Package': 'package_name',
        '# Version': 'package_version',
        '# Tested on': 'tested_on',
        '# Ci-Check': 'ci_check',
        '# Use Non-Root User': 'use_non_root_user'
    }
    
    try:
        with open(script_path, 'r') as f:
            for line in f:
                line = line.strip()
                for key, field in key_mapping.items():
                    if line.startswith(key):
                        value = line.split(':', 1)[-1].strip()
                        metadata[field] = value
                        break
    except Exception as e:
        print(f"Error reading script {script_path}: {e}")
        return None
    
    return metadata

def get_changed_scripts():
    """
    Get list of changed .sh scripts from CHANGED_FILES environment variable.
    """
    changed_files = os.environ.get('CHANGED_FILES', '')
    if not changed_files:
        print("No CHANGED_FILES environment variable found")
        return []
    
    scripts = []
    for line in changed_files.split('\n'):
        line = line.strip()
        if line.endswith('.sh') and 'dockerfile' not in line.lower():
            scripts.append(line)
    
    return scripts

def main():
    print("=" * 80)
    print("EXECUTING CHANGED BUILD SCRIPTS")
    print("=" * 80)
    
    # Get changed scripts
    changed_scripts = get_changed_scripts()
    
    if not changed_scripts:
        print("No .sh scripts found in changed files")
        print("Skipping script execution")
        return 0
    
    print(f"\nFound {len(changed_scripts)} changed script(s):")
    for script in changed_scripts:
        print(f"  - {script}")
    print()
    
    # Process each script
    executed_count = 0
    skipped_count = 0
    
    for script_path in changed_scripts:
        print("=" * 80)
        print(f"Processing: {script_path}")
        print("=" * 80)
        
        # Check if script exists
        if not os.path.exists(script_path):
            print(f"⚠️  Script not found: {script_path}")
            continue
        
        # Extract metadata from script header
        metadata = extract_script_metadata(script_path)
        if not metadata:
            print(f"❌ Failed to extract metadata from {script_path}")
            continue
        
        version = metadata['package_version']
        ci_check = metadata['ci_check'].lower()
        tested_on = metadata['tested_on']
        use_non_root = metadata['use_non_root_user'].lower()
        
        print(f"📋 Metadata extracted:")
        print(f"   Package: {metadata['package_name']}")
        print(f"   Version: {version}")
        print(f"   Tested on: {tested_on}")
        print(f"   CI-Check: {ci_check}")
        print(f"   Use Non-Root: {use_non_root}")
        
        # Check CI-Check flag
        if ci_check != "true":
            print(f"⏭️  Skipping {script_path} - CI-Check flag is set to {ci_check}")
            skipped_count += 1
            continue
        
        if not version:
            print(f"⚠️  No version found in script header, skipping {script_path}")
            skipped_count += 1
            continue
        
        # Set environment variables for build_package.sh
        os.environ['PKG_DIR_PATH'] = os.path.dirname(script_path) + '/'
        os.environ['BUILD_SCRIPT'] = os.path.basename(script_path)
        os.environ['VERSION'] = version
        os.environ['TESTED_ON'] = tested_on
        os.environ['NON_ROOT_BUILD'] = use_non_root
        
        print(f"\n🚀 Executing: {script_path} with version {version}")
        print(f"   Command: bash gha-script/build_package.sh")
        
        # Execute build_package.sh which will run the script
        exit_code = os.system('bash gha-script/build_package.sh')
        
        if exit_code != 0:
            print(f"\n❌ Script execution failed for {script_path} with exit code {exit_code}")
            return exit_code
        else:
            print(f"\n✅ Script execution completed successfully for {script_path}")
            executed_count += 1
    
    print("\n" + "=" * 80)
    print("EXECUTION SUMMARY")
    print("=" * 80)
    print(f"✅ Executed: {executed_count}")
    print(f"⏭️  Skipped: {skipped_count}")
    print(f"📊 Total: {len(changed_scripts)}")
    print("=" * 80)
    
    return 0

if __name__ == "__main__":
    sys.exit(main())


