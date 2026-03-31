"""
post_process_wheel.py
This script performs post-processing of a built Python wheel before uploading it to IBM COS.

Main responsibilities:
1. Unpack the wheel.
2. Detect bundled shared libraries (.so files) and extract their license information.
3. Inject license details into:
   - UBI_BUNDLED_LICENSES.txt
   - BUNDLED_LICENSES.txt
4. Update the wheel METADATA by injecting the classifier:
   "Classifier: Environment :: MetaData :: IBM Python Ecosystem"
5. Determine the correct version suffix (+ppc64leN) by checking IBM COS:
   - Compute SHA256 of the local wheel.
   - Check if a wheel with the same name already exists in COS.
   - If SHA matches → reuse suffix.
   - If SHA differs → increment suffix (ppc64le1, ppc64le2, etc.).
6. Update the wheel version with the resolved suffix.
7. Regenerate the RECORD file with updated hashes.
8. Repack the wheel.

Execution Flow:
Wheel Build → Auditwheel Repair → post_process_wheel.py → Upload to COS
This script is executed by the CI pipeline through create_wheel_wrapper.sh.
"""

import os
import re
import shutil
import subprocess
import tempfile
import sys
import hashlib
import base64
import ibm_boto3
from ibm_botocore.client import Config
import logging

logging.basicConfig(
    level=logging.INFO,
    format="[%(levelname)s] %(asctime)s - %(message)s"
)

logger = logging.getLogger(__name__)

# COS configuration 
COS_API_KEY = os.environ["GHA_CURRENCY_SERVICE_ID_API_KEY"]
COS_SERVICE_INSTANCE_ID = os.environ["GHA_CURRENCY_SERVICE_ID"]
COS_ENDPOINT = "https://s3.us.cloud-object-storage.appdomain.cloud"
COS_BUCKET = "ose-power-artifacts-production"

# License extraction utilities
LICENSE_PATTERN = re.compile(r"^(LICENSE|COPYING)(\..*)?$")
LICENSE_SEPARATOR = "----"  # Hardcoded separator for both files
# Metadata update utilities
CLASSIFIER = "Classifier: Environment :: MetaData :: IBM Python Ecosystem"
# Suffix configuration
BASE_SUFFIX = "ppc64le"

def run_command(cmd):
    # Run a command and return the result, with error handling
    try:
        return subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            check=False
        )
    except Exception as e:
        logger.error(f"Command failed → {cmd} : {e}")
        return None

def find_libs_dirs(root):
    # Walk the directory tree to find all .libs directories
    try:
        return [
            os.path.join(dirpath, d)
            for dirpath, dirnames, _ in os.walk(root)
            for d in dirnames
            if d.endswith(".libs")
        ]
    except Exception as e: 
        logger.error(f"Failed to find .libs directories → {e}")
        return []

def collect_so_files(libs_dir):
    # Collect .so files in a given .libs directory
    try:
        return [
            os.path.join(libs_dir, f)
            for f in os.listdir(libs_dir)
            if f.startswith("lib") and ".so" in f
        ]
    except Exception as e:
        logger.error(f"Failed to collect .so files → {e}")
        return []

def normalize_so_name(so_name):
    # Normalize .so name by removing hash-like suffixes before .so or version numbers
    return re.sub(r'-[0-9a-f]{8,}(?=(?:\.so|\.\d))', '', so_name)

def find_all_so_anywhere(so_name):
    # Search for the .so file anywhere in the filesystem
    try:
        result = run_command(["find", ".", "-type", "f", "-name", so_name])
        if len(result.stdout) == 0:
            result = run_command(["find", "/", "-type", "f", "-name", so_name])
        return result.stdout.strip().splitlines()
    except Exception as e:
        logger.error(f"Failed to find .so files → {e}")
        return []

def get_rpm_package(so_path):
    # Get the RPM package that owns the given .so file
    try:
        logger.info(f"Searching for library → {so_path}")
        result = run_command(["rpm", "-qf", so_path])
        if result.returncode == 0:
            return result.stdout.strip()
        return None
    except Exception as e:
        logger.error(f"RPM package lookup failed for {so_path} → {e}")
        return None

def get_rpm_license(pkg_name):
    # Get the license of an RPM package
    try:
        result = run_command(["rpm", "-q", "--qf", "%{LICENSE}\n", pkg_name])
        if result.returncode == 0:
            return result.stdout.strip()
        return None
    except Exception as e:
        logger.error(f"RPM license lookup failed for {pkg_name} → {e}")
        return None

def find_project_root(so_path, max_up=10):
    # Traverse up the directory tree to find a directory containing LICENSE file
    try:
        current = os.path.dirname(so_path)
        for _ in range(max_up):
            if not current:
                break  # stop if directory doesn't exist

            for f in os.listdir(current):
                if LICENSE_PATTERN.match(f):
                    return current  # found LICENSE/COPYING

            parent = os.path.dirname(current)
            if parent == current:
                break  # reached root
            current = parent

        return None  # no license found
    except Exception as e:
        logger.error(f"Failed to find project root for {so_path} → {e}")
        return None


def find_license_in_directory(directory):
    # Look for LICENSE files in the given directory
    try:
        for f in os.listdir(directory):
            if LICENSE_PATTERN.match(f):
                return os.path.join(directory, f)
        return None
    except Exception as e:
        logger.error(f"Failed to find license in directory {directory} → {e}")
        return None

def find_dist_info_dir(root):
    # Look for the .dist-info directory in the given root
    try:
        for item in os.listdir(root):
            if item.endswith(".dist-info"):
                return os.path.join(root, item)
        return None
    except Exception as e:
        logger.error(f"Failed to find .dist-info directory in {root} → {e}")
        return None

def append_license_entry(file_path, so_names, license_text):
    # Append a license entry to the given file, with proper formatting
    try:
        logger.info(f"Appending license to {file_path} for files: {so_names}")
        if os.path.exists(file_path) and os.path.getsize(file_path) > 0:
            with open(file_path, "a", encoding="utf-8") as f:
                f.write(f"\n\n\n{LICENSE_SEPARATOR}\n\n\n\n")

        with open(file_path, "a", encoding="utf-8") as f:
            f.write(f"Files: {', '.join(so_names)}\n")
            lines = license_text.strip("\n").splitlines()
            if len(lines) > 1:
                f.write("\n")
                f.write(license_text)
                if not license_text.endswith("\n"):
                    f.write("\n")
            else:
                f.write(f"License: {license_text.strip()}\n")
    except Exception as e:
        logger.error(f"Failed to append license entry → {e}")

def compute_hash_and_size(file_path):
    # Compute SHA256 hash and size of the given file
    try:
        with open(file_path, "rb") as f:
            data = f.read()
        digest = hashlib.sha256(data).digest()
        hash_b64 = base64.urlsafe_b64encode(digest).rstrip(b'=').decode("utf-8")
        size = len(data)
        return f"sha256={hash_b64}", size
    except Exception as e:
        logger.error(f"Failed to compute hash and size for {file_path} → {e}")
        return None, None

def update_record(dist_info_dir, file_paths):
    # Update the RECORD file with new hash and size for the given file paths
    try:
        logger.info(f"Updating RECORD file in {dist_info_dir}")
        record_file = os.path.join(dist_info_dir, "RECORD")
        if not os.path.exists(record_file):
            logger.warning(f"RECORD file not found at {record_file}")
            return

        with open(record_file, "r", encoding="utf-8") as f:
            lines = f.read().splitlines()

        record_map = {line.split(",")[0]: line.split(",") for line in lines}

        for path in file_paths:
            if not os.path.exists(path):
                continue
            relative_path = os.path.relpath(path, os.path.dirname(dist_info_dir))
            hash_val, size_val = compute_hash_and_size(path)
            record_map[relative_path] = [relative_path, hash_val, str(size_val)]

        with open(record_file, "w", encoding="utf-8", newline="\n") as f:
            for parts in record_map.values():
                f.write(",".join(parts) + "\n")
    except Exception as e:
        logger.exception(f"Failed to update RECORD file → {e}")

def process_so_file(so_path, rpm_licenses, bundled_licenses):
    # Determine the original .so name and normalized name for searching
    try:
        logger.info(f"Processing .so file: {so_path}")
        original_name = os.path.basename(so_path)
        normalized_name = normalize_so_name(original_name)

        # Track if a license was successfully found
        license_found = False

        for match_so in find_all_so_anywhere(normalized_name):
            if not match_so:
                continue  # skip empty paths

            # RPM license check
            pkg = get_rpm_package(match_so)
            if pkg:
                license_text = get_rpm_license(pkg)
                if license_text:
                    rpm_licenses.setdefault(license_text, []).append(original_name)
                    license_found = True
                    break  # stop after successfully found RPM license
                else:
                    # RPM package exists but license not found, continue to next path
                    continue

            # Bundled license check
            project_root = find_project_root(match_so)
            if project_root:
                license_file = find_license_in_directory(project_root)
                if license_file:
                    try:
                        with open(license_file, "r", encoding="utf-8", errors="ignore") as f:
                            bundled_licenses.setdefault(f.read(), []).append(original_name)
                            license_found = True
                            break  # stop after successfully read bundled license
                    except Exception:
                        # Failed to read this license file, continue to next match_so
                        continue

        # Fallback if no license found in any path
        if not license_found:
            bundled_licenses.setdefault(f"{original_name}_license_not_found", []).append(original_name)
    except Exception as e:
        logger.exception(f"Error processing .so file {so_path} → {e}")

# Wheel version suffix utilities 
def read_version_from_metadata(dist_info_dir):
    # Read the version from the METADATA file in the .dist-info directory
    try:
        metadata_path = os.path.join(dist_info_dir, "METADATA")
        with open(metadata_path, "r", encoding="utf-8") as f:
            for line in f:
                if line.startswith("Version:"):
                    return line.split(":", 1)[1].strip()
        raise RuntimeError("Version not found in METADATA")
    except Exception as e:
        logger.error(f"Failed to read version from METADATA → {e}")
        return None

def build_new_version(old_version, suffix):
    # Build a new version string by appending the suffix
    try:
        if "+" in old_version:
            base, local = old_version.split("+", 1)
            return f"{base}+{local}{suffix}"
        return f"{old_version}+{suffix}"
    except Exception as e:
        logger.error(f"Failed to build new version string → {e}")
        return old_version  # fallback to old version if error occurs

def update_metadata_version(dist_info_dir, new_version):
    # Update the Version field in the METADATA file with the new version
    try:
        metadata_path = os.path.join(dist_info_dir, "METADATA")
        with open(metadata_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
        with open(metadata_path, "w", encoding="utf-8") as f:
            for line in lines:
                if line.startswith("Version:"):
                    f.write(f"Version: {new_version}\n")
                else:
                    f.write(line)
    except Exception as e:
        logger.error(f"Failed to update version in METADATA → {e}")

def rename_dist_info_dir(extract_path, old_version, new_version):
    # Rename the .dist-info directory to reflect the new version
    try:
        for entry in os.listdir(extract_path):
            if entry.endswith(".dist-info") and old_version in entry:
                old_path = os.path.join(extract_path, entry)
                new_entry = entry.replace(old_version, new_version)
                new_path = os.path.join(extract_path, new_entry)
                os.rename(old_path, new_path)
                return new_path
        raise RuntimeError("Failed to rename .dist-info directory")
    except Exception as e:
        logger.error(f"Failed to rename .dist-info directory → {e}")
        return None

def _hash_file(path):
    # Compute SHA256 hash of the given file and return in the format required by RECORD
    try:
        h = hashlib.sha256()
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(8192), b""):
                h.update(chunk)
        return "sha256=" + h.digest().hex()
    except Exception as e:
        logger.error(f"Failed to hash file {path} → {e}")
        return None

def regenerate_record(extract_path, dist_info_dir):
    # Regenerate the RECORD file with updated hashes and sizes for all files in the wheel
    try:
        logger.info("Regenerating RECORD file with updated hashes and sizes")
        record_path = os.path.join(dist_info_dir, "RECORD")
        records = []

        for root, _, files in os.walk(extract_path):
            for fname in files:
                full_path = os.path.join(root, fname)
                rel_path = os.path.relpath(full_path, extract_path)
                rel_path = rel_path.replace(os.sep, "/")

                if rel_path.endswith("RECORD"):
                    records.append(f"{rel_path},,")
                    continue

                size = os.path.getsize(full_path)
                digest = _hash_file(full_path)
                records.append(f"{rel_path},{digest},{size}")

        with open(record_path, "w", encoding="utf-8") as f:
            f.write("\n".join(records))
    except Exception as e:
        logger.exception(f"Failed to regenerate RECORD file → {e}")

def resolve_suffix(client, package, version, wheel_name, wheel_sha256):
    # Resolve a unique suffix for the wheel based on its name and local hash
    try:
        logger.info(f"Resolving suffix for package={package}, version={version}, wheel={wheel_name}")
        parts = wheel_name[:-4].rsplit("-", 3)
        pkg_ver = parts[0]
        remainder = "-".join(parts[1:])

        pkg, ver = pkg_ver.rsplit("-", 1)

        base_keys = [
            f"{package}/v{version}",
            f"{package}/{version}"
        ]

        n = 1
        while True:
            suffix = f"{BASE_SUFFIX}{n}"
            candidate = f"{pkg}-{ver}+{suffix}-{remainder}.whl"
            found = False
            response = None
            for base in base_keys:
                cos_key = f"{base}/{candidate}"
                logger.info(f"Checking COS object → {cos_key}")
                try:
                    response = client.head_object(
                        Bucket=COS_BUCKET,
                        Key=cos_key
                    )
                    found = True
                    break
                except Exception:
                    pass

            if not found:
                return suffix

            remote_sha = (
                response.get("Metadata", {}).get("sha256")
                or response.get("Metadata", {}).get("Sha256")
            )
            logger.info(f"Found existing object in COS with SHA256 → {remote_sha}")
            logger.info(f"Comparing COS SHA={remote_sha} with build SHA={wheel_sha256}")
            # CASE 1 - COS object exists but SHA metadata missing
            if remote_sha is None:
                logger.info("COS SHA metadata missing → using suffix ppc64le1")
                return suffix
            # CASE 2 - SHA matches
            if remote_sha and remote_sha.strip() == wheel_sha256.strip():
                logger.info(f"SHA match → reusing suffix {suffix}")
                return suffix
            # CASE 3 - SHA mismatch → try next suffix
            logger.info(f"SHA mismatch → trying next suffix")
            n += 1
    except Exception as e:
        logger.exception(f"Suffix resolution failed → {e}")
        sys.exit(1)


def inject_classifier(dist_info):
    # Inject the required classifier into the METADATA file if not already present
    try:
        logger.info(f"Injecting classifier into METADATA at {dist_info}")
        metadata_file = os.path.join(dist_info, "METADATA")

        with open(metadata_file, "r", encoding="utf-8") as f:
            lines = f.readlines()

        if any(CLASSIFIER in line for line in lines):
            return

        classifier_indexes = [i for i,l in enumerate(lines) if l.startswith("Classifier:")]
        project_indexes = [i for i,l in enumerate(lines) if l.startswith("Project-URL:")]

        insert_at = 0

        if classifier_indexes:
            insert_at = classifier_indexes[-1] + 1
        elif project_indexes:
            insert_at = project_indexes[-1] + 1

        lines.insert(insert_at, CLASSIFIER + "\n")

        with open(metadata_file, "w", encoding="utf-8") as f:
            f.writelines(lines)
    except Exception as e:
        logger.error(f"Failed to inject classifier → {e}")

# Main processing function
def process_wheel(wheel_path, suffix):
    try:
        logger.info(f"Processing wheel: {wheel_path} with suffix: {suffix}")
        wheel_dir = os.path.dirname(wheel_path)
        wheel_name = os.path.basename(wheel_path)

        with tempfile.TemporaryDirectory() as tmpdir:
            # Unpack wheel
            logger.info(f"Unpacking wheel: {wheel_path}")
            subprocess.run(["wheel", "unpack", wheel_path, "-d", tmpdir], check=True)
            dirs = [d for d in os.listdir(tmpdir) if os.path.isdir(os.path.join(tmpdir, d))]
            if len(dirs) != 1:
                raise RuntimeError(f"Unexpected unpack layout. Found directories: {dirs}")
            extract_path = os.path.join(tmpdir, dirs[0])

            # License processing
            logger.info("Starting license extraction and injection")
            rpm_licenses = {}
            bundled_licenses = {}

            libs_dirs = find_libs_dirs(extract_path)

            if libs_dirs:
                logger.info(f"Found {len(libs_dirs)} .libs directories → scanning for shared libraries")
                for libs_dir in libs_dirs:
                    so_files = collect_so_files(libs_dir)

                    if not so_files:
                        logger.info(f"No .so files found in {libs_dir}")

                    for so_file in so_files:
                        process_so_file(so_file, rpm_licenses, bundled_licenses)
            else:
                logger.info(".libs directory not found, No .so files were added, skipping adding licenses")

            dist_info = find_dist_info_dir(extract_path)
            old_version = None
            if dist_info:
                inject_classifier(dist_info)
                ubi_path = os.path.join(dist_info, "UBI_BUNDLED_LICENSES.txt")
                bundled_path = os.path.join(dist_info, "BUNDLED_LICENSES.txt")

                for license_text, files in rpm_licenses.items():
                    append_license_entry(ubi_path, files, license_text)
                for license_text, files in bundled_licenses.items():
                    append_license_entry(bundled_path, files, license_text)

                existing_license_files = [p for p in [ubi_path, bundled_path] if os.path.exists(p)]
                if existing_license_files:
                    update_record(dist_info, existing_license_files)

                # Version suffix processing
                old_version = read_version_from_metadata(dist_info)
            
                if old_version is None:
                   logger.error("Version not found in METADATA, cannot proceed")
                   sys.exit(1)
                   
                new_version = build_new_version(old_version, suffix)
                update_metadata_version(dist_info, new_version)
                dist_info = rename_dist_info_dir(extract_path, old_version, new_version)
                regenerate_record(extract_path, dist_info)

            # Pack wheel
            subprocess.run(["wheel", "pack", extract_path, "-d", wheel_dir], check=True)

        new_wheel_name = wheel_name
        if "+" in old_version:
            base, local = old_version.split("+", 1)
            new_wheel_name = wheel_name.replace(f"{base}+{local}", f"{base}+{local}{suffix}", 1)
        else:
            new_wheel_name = wheel_name.replace(old_version, f"{old_version}+{suffix}", 1)

        new_wheel_path = os.path.join(wheel_dir, new_wheel_name)
        os.remove(wheel_path)
        logger.info("Processing wheel completed")
        return new_wheel_path
    except Exception as e:
        logger.error(f"Failed to process wheel → {e}")
        return None

def create_cos_client():
    # Create and return an IBM COS client using the provided configuration
    try:
        return ibm_boto3.client(
            "s3",
            ibm_api_key_id=COS_API_KEY,
            ibm_service_instance_id=COS_SERVICE_INSTANCE_ID,
            config=Config(signature_version="oauth"),
            endpoint_url=COS_ENDPOINT,
        )
    except Exception as e:
        logger.error(f"Failed to create COS client → {e}")
        sys.exit(1)

def main():
    if len(sys.argv) != 3:
        logger.error("Usage: python post_process_wheel.py <wheel_file.whl> <wheel_sha256>")
        sys.exit(1)

    wheel_path = sys.argv[1]
    wheel_sha256 = sys.argv[2]

    # Resolve suffix using COS
    wheel_name = os.path.basename(wheel_path)
    parts = wheel_name.split("-")
    package = parts[0]
    version = parts[1]

    client = create_cos_client()
    if client is None:
        logger.error("COS client creation failed")
        sys.exit(1)

    suffix = resolve_suffix(
        client,
        package,
        version,
        wheel_name,
        wheel_sha256
    )
    
    new_wheel = process_wheel(wheel_path, suffix)
    if not new_wheel:
        logger.error("Wheel processing failed")
        sys.exit(1)
    logger.info(f"Wheel updated: {new_wheel}")

if __name__ == "__main__":
    main()
