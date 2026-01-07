"""
Automated Wheel License Extraction Script

This script automates the extraction and aggregation of license information
from shared object (.so) files bundled within Python wheel (.whl) packages.

Key Features:
-Extracts wheel files to a temporary directory for inspection.
-Searches for .libs directories containing .so files.
-Normalizes .so file names by removing hash-like suffixes.
-Attempts to detect licenses in two ways:
    -Checks if the .so file is part of an installed RPM package and retrieves its license.
    -Searches for bundled LICENSE or COPYING files in the project directory containing the .so.
-Generates aggregated license files inside the wheel's .dist-info folder.
-UBI_BUNDLED_LICENSES.txt for RPM-based licenses.
-BUNDLED_LICENSES.txt for bundled licenses or cases where license info could not be found.
-Updates the original wheel file in place after processing.
-Cleans up temporary extraction directories to avoid clutter.

Usage:
python so_license_extractor.py <wheel_file.whl>

Arguments:
<wheel_file.whl>: Path to the wheel file to process.

Requirements:
- Python 

Notes:
- Aggregated LICENSE files are separated by a hardcoded separator (----) to distinguish multiple entries.

"""

import os
import re
import shutil
import subprocess
import tempfile
import zipfile
import sys

LICENSE_PATTERN = re.compile(r"^(LICENSE|COPYING)(\..*)?$")
LICENSE_SEPARATOR = "----"  # Hardcoded separator for both files


def run_command(cmd):
    """
    Run a shell command and return the completed process.

    Args:
        cmd (list): Command and arguments as a list.

    Returns:
        subprocess.CompletedProcess: Result object containing stdout, stderr, and return code.
    """
    return subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        check=False
    )


def extract_wheel(wheel_path):
    """
    Extract a wheel file into a temporary directory.

    Args:
        wheel_path (str): Path to the .whl file.

    Returns:
        str: Path to the temporary directory containing extracted files.
    """
    temp_dir = tempfile.mkdtemp(prefix="wheel_extract_")
    with zipfile.ZipFile(wheel_path, "r") as zf:
        zf.extractall(temp_dir)
    return temp_dir


def rezip_wheel(src_dir, output_whl):
    """
    Rezip an extracted wheel directory back into a .whl file.

    Args:
        src_dir (str): Path to the extracted wheel directory.
        output_whl (str): Path to output wheel file (overwrite original).
    """
    with zipfile.ZipFile(output_whl, "w", zipfile.ZIP_DEFLATED) as zf:
        for root, _, files in os.walk(src_dir):
            for file in files:
                full_path = os.path.join(root, file)
                arcname = os.path.relpath(full_path, src_dir)
                zf.write(full_path, arcname)


def cleanup(path):
    """
    Remove a directory and all its contents.

    Args:
        path (str): Path to the directory to delete.
    """
    shutil.rmtree(path, ignore_errors=True)


def find_libs_dirs(root):
    """
    Find all directories ending with '.libs' in the extracted wheel.

    Args:
        root (str): Root directory of extracted wheel.

    Returns:
        list: List of paths to '.libs' directories.
    """
    return [
        os.path.join(dirpath, d)
        for dirpath, dirnames, _ in os.walk(root)
        for d in dirnames
        if d.endswith(".libs")
    ]


def collect_so_files(libs_dir):
    """
    Collect all .so files in a .libs directory.

    Args:
        libs_dir (str): Path to the .libs directory.

    Returns:
        list: List of .so file paths.
    """
    return [
        os.path.join(libs_dir, f)
        for f in os.listdir(libs_dir)
        if f.startswith("lib") and ".so" in f
    ]


def normalize_so_name(so_name):
    """
    Normalize a .so file name by removing hash-like suffixes.

    Args:
        so_name (str): Original .so file name.

    Returns:
        str: Normalized .so name.
    """
    return re.sub(r'-[0-9a-f]{8,}(?=(?:\.so|\.\d))', '', so_name)


def find_all_so_anywhere(so_name):
    """
    Find all paths on the system matching a .so file name.

    Args:
        so_name (str): Normalized .so file name.

    Returns:
        list: List of full paths matching the .so name.
    """
    result = run_command(["find", ".", "-type", "f", "-name", so_name])
    return result.stdout.strip().splitlines()


def get_rpm_package(so_path):
    """
    Get the RPM package that provides a .so file.

    Args:
        so_path (str): Path to the .so file.

    Returns:
        str or None: RPM package name if found, else None.
    """
    result = run_command(["rpm", "-qf", so_path])
    if result.returncode == 0:
        return result.stdout.strip()
    return None


def get_rpm_license(pkg_name):
    """
    Get the license of an RPM package.

    Args:
        pkg_name (str): RPM package name.

    Returns:
        str or None: License string if found, else None.
    """
    result = run_command(["rpm", "-q", "--qf", "%{LICENSE}\n", pkg_name])
    if result.returncode == 0:
        return result.stdout.strip()
    return None


def find_project_root(so_path, max_up=10):
    """
    Find the project root directory containing LICENSE or COPYING files.

    Args:
        so_path (str): Path to a .so file.
        max_up (int): Maximum levels to traverse upwards.

    Returns:
        str or None: Path to project root or None if not found.
    """
    current = os.path.dirname(so_path)
    for _ in range(max_up):
        for f in os.listdir(current):
            if LICENSE_PATTERN.match(f):
                return current
        parent = os.path.dirname(current)
        if parent == current:
            break
        current = parent
    return None


def find_license_in_directory(directory):
    """
    Find a LICENSE or COPYING file in a directory.

    Args:
        directory (str): Directory to search.

    Returns:
        str or None: Path to license file or None if not found.
    """
    for f in os.listdir(directory):
        if LICENSE_PATTERN.match(f):
            return os.path.join(directory, f)
    return None


def find_dist_info_dir(root):
    """
    Find the .dist-info folder in the extracted wheel.

    Args:
        root (str): Root of extracted wheel.

    Returns:
        str or None: Path to .dist-info folder or None if not found.
    """
    for item in os.listdir(root):
        if item.endswith(".dist-info"):
            return os.path.join(root, item)
    return None


def append_license_entry(file_path, so_names, license_text):
    """
    Append license information for .so files into a LICENSE file.

    Args:
        file_path (str): Path to the LICENSE file.
        so_names (list): List of .so file names.
        license_text (str): License text to append.
    """
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


def process_so_file(so_path, rpm_licenses, bundled_licenses):
    """
    Process a single .so file by checking RPM or bundled license.

    Args:
        so_path (str): Path to the .so file.
        rpm_licenses (dict): Dictionary mapping license text to list of RPM .so files.
        bundled_licenses (dict): Dictionary mapping license text to list of bundled .so files.
    """
    original_name = os.path.basename(so_path)
    normalized_name = normalize_so_name(original_name)

    for match_so in find_all_so_anywhere(normalized_name):
        pkg = get_rpm_package(match_so)
        if pkg:
            license_text = get_rpm_license(pkg)
            if license_text:
                rpm_licenses.setdefault(license_text, []).append(original_name)
            else:
                bundled_licenses.setdefault(f"{original_name}_license_not_found", []).append(original_name)
            return

        project_root = find_project_root(match_so)
        if project_root:
            license_file = find_license_in_directory(project_root)
            if license_file:
                try:
                    with open(license_file, "r", encoding="utf-8", errors="ignore") as f:
                        bundled_licenses.setdefault(f.read(), []).append(original_name)
                    return
                except Exception:
                    pass

    bundled_licenses.setdefault(f"{original_name}_license_not_found", []).append(original_name)


def main():
    if len(sys.argv) != 2:
        raise SystemExit("Usage: python so_license_extractor.py <wheel_file.whl>")
    
    wheel_path = sys.argv[1]

    extracted_dir = extract_wheel(wheel_path)
    rpm_licenses = {}
    bundled_licenses = {}

    try:
        libs_dirs = find_libs_dirs(extracted_dir)

        if not libs_dirs:
            print("[INFO] No .libs directory found. No .so files to process.")
            return

        libs_dir = libs_dirs[0] 
        so_files = collect_so_files(libs_dir)

        if not so_files:
            print("[INFO] No .so files found in .libs directory. Nothing to process.")
            return

        for so_file in so_files:
            process_so_file(so_file, rpm_licenses, bundled_licenses)

        dist_info = find_dist_info_dir(extracted_dir)
        if not dist_info:
            print("[WARN] No .dist-info folder found. LICENSE files not updated.")
        else:
            ubi_path = os.path.join(dist_info, "UBI_BUNDLED_LICENSES.txt")
            bundled_path = os.path.join(dist_info, "BUNDLED_LICENSES.txt")

            for license_text, files in rpm_licenses.items():
                append_license_entry(ubi_path, files, license_text)

            for license_text, files in bundled_licenses.items():
                append_license_entry(bundled_path, files, license_text)

        rezip_wheel(extracted_dir, wheel_path)
        print(f"[INFO] Wheel updated in place: {wheel_path}")

    finally:
        cleanup(extracted_dir)


if __name__ == "__main__":
    main()
