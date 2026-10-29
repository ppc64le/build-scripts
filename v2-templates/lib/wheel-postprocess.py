#!/usr/bin/env python3
"""
wheel-postprocess.py - Wheel version retagging and IBM COS suffix resolution

This script is invoked by wheel-utils.sh during wheel postprocessing.
It handles:
1. Parsing wheel filename and extracting package, version, python tag, abi tag.
2. Checking IBM Cloud Object Storage (COS) for existing builds of the same package/version.
3. Resolving PEP 440 local version identifiers (+ubi9, +ubi10, +ppc64leN).
4. Updating the METADATA Version field.
5. Renaming the .dist-info directory inside the extracted wheel temp directory.

Usage:
    python3 wheel-postprocess.py <wheel_name> <extracted_temp_dir> [distro_tag] [wheel_path]
"""

import os
import sys
import re
import hashlib
import subprocess


class COSAdapter:
    """COS client with automatic fallback to pure standard library urllib."""

    def __init__(self, api_key, instance_id, endpoint, bucket):
        self.api_key = api_key
        self.instance_id = instance_id
        self.endpoint = endpoint.rstrip("/")
        self.bucket = bucket
        self.boto_client = None

        try:
            try:
                import ibm_boto3
                from ibm_botocore.client import Config
            except ImportError:
                import boto3 as ibm_boto3
                from botocore.client import Config

            client_kwargs = {
                "service_name": "s3",
                "ibm_api_key_id": api_key,
                "config": Config(signature_version="oauth"),
                "endpoint_url": endpoint,
            }
            if instance_id:
                client_kwargs["ibm_service_instance_id"] = instance_id
            self.boto_client = ibm_boto3.client(**client_kwargs)
        except Exception:
            self.boto_client = None
            import urllib.request
            import urllib.parse
            import json
            import ssl
            import xml.etree.ElementTree as ET

            self.urllib = urllib
            self.json = json
            self.ET = ET
            self.ctx = ssl._create_unverified_context()

            token_url = "https://iam.cloud.ibm.com/identity/token"
            data = urllib.parse.urlencode({
                "apikey": api_key,
                "grant_type": "urn:ibm:params:oauth:grant-type:apikey"
            }).encode("utf-8")
            req = urllib.request.Request(
                token_url,
                data=data,
                headers={"Content-Type": "application/x-www-form-urlencoded", "Accept": "application/json"}
            )
            with urllib.request.urlopen(req, context=self.ctx, timeout=30) as resp:
                self.token = json.loads(resp.read().decode("utf-8"))["access_token"]

    def list_objects(self, prefix):
        if self.boto_client:
            try:
                resp = self.boto_client.list_objects_v2(Bucket=self.bucket, Prefix=f"{prefix}/")
                return [o["Key"] for o in resp.get("Contents", []) if o["Key"].endswith(".whl")]
            except Exception as e:
                sys.stderr.write(f"[DEBUG] [COS] boto list_objects error: {e}\n")
                return []
        else:
            url = f"{self.endpoint}/{self.bucket}?prefix={self.urllib.parse.quote(prefix)}/&list-type=2"
            headers = {"Authorization": f"Bearer {self.token}"}
            req = self.urllib.request.Request(url, headers=headers)
            try:
                with self.urllib.request.urlopen(req, context=self.ctx, timeout=30) as resp:
                    xml_data = resp.read().decode("utf-8")
                    root = self.ET.fromstring(xml_data)
                    ns = {"s3": "http://s3.amazonaws.com/doc/2006-03-01/"}
                    keys = [e.text for e in root.findall(".//s3:Key", ns) if e.text and e.text.endswith(".whl")]
                    if not keys:
                        keys = [e.text for e in root.findall(".//Key") if e.text and e.text.endswith(".whl")]
                    return keys
            except Exception as e:
                sys.stderr.write(f"[DEBUG] [COS] urllib list_objects error: {e}\n")
                return []

    def get_sha(self, key):
        if self.boto_client:
            try:
                h = self.boto_client.head_object(Bucket=self.bucket, Key=key)
                meta = h.get("Metadata", {})
                m_sha = meta.get("sha256") or meta.get("Sha256")
                if m_sha:
                    return m_sha.strip()
                b = self.boto_client.get_object(Bucket=self.bucket, Key=key)["Body"]
                h_obj = hashlib.sha256()
                for chk in iter(lambda: b.read(8192), b""):
                    h_obj.update(chk)
                return h_obj.hexdigest()
            except Exception as e:
                sys.stderr.write(f"[DEBUG] [COS] boto get_sha error: {e}\n")
                return None
        else:
            url = f"{self.endpoint}/{self.bucket}/{self.urllib.parse.quote(key)}"
            headers = {"Authorization": f"Bearer {self.token}"}
            req = self.urllib.request.Request(url, headers=headers)
            try:
                req.get_method = lambda: "HEAD"
                with self.urllib.request.urlopen(req, context=self.ctx, timeout=30) as resp:
                    meta_sha = resp.headers.get("x-amz-meta-sha256") or resp.headers.get("x-amz-meta-Sha256")
                    if meta_sha:
                        return meta_sha.strip()
                req.get_method = lambda: "GET"
                with self.urllib.request.urlopen(req, context=self.ctx, timeout=60) as resp:
                    h_obj = hashlib.sha256()
                    while chk := resp.read(8192):
                        h_obj.update(chk)
                    return h_obj.hexdigest()
            except Exception as e:
                sys.stderr.write(f"[DEBUG] [COS] urllib get_sha error: {e}\n")
                return None



def resolve_artifact_sha(dep_name, dep_version="", artifact_base=None):
    """
    Look up the artifact hash for a dependency in ARTIFACT_WORKSPACE.
    Hierarchy:
      1. ${ARTIFACT_WORKSPACE}/${dep_name}/${dep_version}/sha256.sha
      2. ${ARTIFACT_WORKSPACE}/${dep_name}/sha256.sha
      3. Content hash of manifest.json if sha256.sha is missing
      4. Fallback to SHA256 of f"{dep_name}:{dep_version}"
    """
    if not artifact_base:
        artifact_base = os.environ.get("ARTIFACT_WORKSPACE") or "/output/artifacts"

    search_dirs = []
    ubi_ver = os.environ.get("UBI_VERSION")
    if ubi_ver and ubi_ver not in artifact_base:
        ubi_base = os.path.join(artifact_base, ubi_ver)
        if dep_version:
            search_dirs.append(os.path.join(ubi_base, dep_name, dep_version))
            search_dirs.append(os.path.join(ubi_base, dep_name, dep_version.lstrip("v")))
            search_dirs.append(os.path.join(ubi_base, dep_name, f"v{dep_version.lstrip('v')}"))
        search_dirs.append(os.path.join(ubi_base, dep_name))

    if dep_version:
        search_dirs.append(os.path.join(artifact_base, dep_name, dep_version))
        search_dirs.append(os.path.join(artifact_base, dep_name, dep_version.lstrip("v")))
        search_dirs.append(os.path.join(artifact_base, dep_name, f"v{dep_version.lstrip('v')}"))
    search_dirs.append(os.path.join(artifact_base, dep_name))

    for d in search_dirs:
        # 1. Check sha256.sha file
        sha_file = os.path.join(d, "sha256.sha")
        if os.path.isfile(sha_file):
            try:
                with open(sha_file) as f:
                    val = f.read().strip()
                    if val:
                        return val.split()[0]
            except Exception:
                pass

        # 2. Check manifest.json for recipe_sha or content hash
        manifest_file = os.path.join(d, "manifest.json")
        if os.path.isfile(manifest_file):
            try:
                import json
                with open(manifest_file, "r", encoding="utf-8") as f:
                    m = json.load(f)
                    if isinstance(m, dict) and m.get("recipe_sha"):
                        return str(m["recipe_sha"]).strip()
                with open(manifest_file, "rb") as f:
                    return hashlib.sha256(f.read()).hexdigest()
            except Exception:
                pass

    # 3. Fallback: hash dep name & version string if artifact dir is unmounted
    fallback_str = f"{dep_name}:{dep_version}" if dep_version else dep_name
    return hashlib.sha256(fallback_str.encode("utf-8")).hexdigest()[:16]


def get_build_deps_artifact_hashes(script_dir=None, pkg_ver=None):
    """
    Returns sorted list of artifact SHA strings for declared build dependencies.
    """
    raw_deps = os.environ.get("BUILD_DEPS", "").strip()
    dep_items = []
    if raw_deps:
        dep_items = [d.strip() for d in re.split(r"[,\s]+", raw_deps) if d.strip()]

    # If BUILD_DEPS was not in environment, check build_info.json if available
    if not dep_items and script_dir and os.path.isdir(script_dir):
        bi_path = os.path.join(script_dir, "build_info.json")
        if os.path.isfile(bi_path):
            try:
                import json
                with open(bi_path) as f:
                    data = json.load(f)
                v_block = data.get(pkg_ver) if pkg_ver and isinstance(data.get(pkg_ver), dict) else None
                if v_block and "build_deps" in v_block:
                    dep_items = v_block.get("build_deps") or []
                elif "build_deps" in data:
                    dep_items = data.get("build_deps") or []
            except Exception:
                pass

    if not dep_items:
        return []

    # Sort dependencies alphabetically by name for deterministic hashing
    sorted_deps = sorted(set(dep_items))
    dep_hashes = []

    for item in sorted_deps:
        parts = item.split(":", 1)
        dep_name = parts[0]
        dep_ver = parts[1] if len(parts) > 1 else ""
        sha = resolve_artifact_sha(dep_name, dep_ver)
        dep_hashes.append(sha)

    return dep_hashes


def compute_recipe_sha(pkg, ver, py_tag, abi_tag, remainder, wheel_path=None):
    """
    Compute build-recipe SHA256 matching create_wheel_wrapper.sh generate_sha():
      - If wheel is any.whl, abi3, or none:
          string_to_hash = f"{PACKAGE_NAME}_{PACKAGE_VERSION}_{PACKAGE_LANGUAGE}_{BUILD_SCRIPT_DATE}"
      - Else:
          string_to_hash = f"{PACKAGE_NAME}_{PACKAGE_VERSION}_{PACKAGE_LANGUAGE}_{python_version}_{BUILD_SCRIPT_DATE}"
    Single path: Queries git log on the exact script file and exits immediately if empty.
    """
    pkg_name = os.environ.get("PACKAGE_NAME") or pkg
    pkg_ver = os.environ.get("PACKAGE_VERSION") or ver
    pkg_lang = os.environ.get("PACKAGE_LANGUAGE", "python")

    # Resolve python_version (e.g. 3.12, 3.11, etc.)
    py_ver = os.environ.get("PYTHON_VERSION") or ""
    if not py_ver:
        if py_tag.startswith("python"):
            py_ver = py_tag.replace("python", "")
        elif py_tag.startswith("cp") and len(py_tag) >= 4 and py_tag[2:].isdigit():
            digits = py_tag[2:]
            if len(digits) == 2:
                py_ver = f"{digits[0]}.{digits[1]}"
            elif len(digits) == 3:
                py_ver = f"{digits[0]}.{digits[1:]}"
            else:
                py_ver = py_tag
        else:
            py_ver = py_tag

    # Determine exact build script path
    build_script = os.environ.get("BUILD_SCRIPT") or os.environ.get("BUILD_SCRIPT_PATH") or ""
    if not build_script or not os.path.isfile(build_script):
        script_dir = os.environ.get("SCRIPT_DIR")
        if script_dir and os.path.isdir(script_dir):
            for candidate in [
                os.environ.get("BUILD_SCRIPT_NAME", ""),
                f"{pkg_name}.sh",
                f"{pkg}.sh",
                f"{os.path.basename(script_dir)}.sh",
            ]:
                if candidate:
                    p = os.path.join(script_dir, candidate)
                    if os.path.isfile(p):
                        build_script = p
                        break

    if not build_script or not os.path.isfile(build_script):
        sys.stderr.write(
            f"[ERROR] [SHA] Build script not found (BUILD_SCRIPT='{build_script}', "
            f"SCRIPT_DIR='{os.environ.get('SCRIPT_DIR', '')}'). Cannot determine recipe SHA.\n"
        )
        sys.exit(1)

    # Get BUILD_SCRIPT_DATE via git log on the exact script file
    script_dir = os.path.dirname(os.path.abspath(build_script))
    script_file = os.path.basename(build_script)
    build_script_date = ""
    try:
        res = subprocess.run(
            ["git", "-C", script_dir, "log", "-1", "--format=%ci", "--", script_file],
            capture_output=True,
            text=True,
            check=False,
        )
        if res.returncode == 0 and res.stdout.strip():
            build_script_date = res.stdout.strip()
    except Exception as e:
        sys.stderr.write(f"[ERROR] [SHA] git log execution failed for {build_script}: {e}\n")
        sys.exit(1)

    if not build_script_date:
        err_msg = res.stderr.strip() if ("res" in locals() and res.stderr) else "empty git log output"
        sys.stderr.write(
            f"[ERROR] [SHA] BUILD_SCRIPT_DATE could not be determined from git log for {build_script} ({err_msg}). Hard exit.\n"
        )
        sys.exit(1)

    wheel_name = os.path.basename(wheel_path) if wheel_path else ""
    whl_name_lower = wheel_name.lower()
    is_universal = (
        whl_name_lower.endswith("any.whl") or
        "abi3" in whl_name_lower or
        "-none-" in whl_name_lower or
        "none" in (abi_tag or "").lower()
    )

    dep_hashes = get_build_deps_artifact_hashes(script_dir=os.environ.get("SCRIPT_DIR"), pkg_ver=pkg_ver)

    if is_universal:
        base_str = f"{pkg_name}_{pkg_ver}_{pkg_lang}_{build_script_date}"
    else:
        base_str = f"{pkg_name}_{pkg_ver}_{pkg_lang}_{py_ver}_{build_script_date}"

    if dep_hashes:
        string_to_hash = f"{base_str} {' '.join(dep_hashes)}"
    else:
        string_to_hash = base_str

    sha_val = hashlib.sha256(string_to_hash.encode("utf-8")).hexdigest()
    sys.stderr.write(f"[INFO] [SHA] Recipe string: '{string_to_hash}' -> SHA256: {sha_val}\n")

    # Save to sha256.sha in current dir
    try:
        with open("sha256.sha", "w") as f:
            f.write(f"{sha_val}\n")
    except Exception:
        pass
    return sha_val


def resolve_suffix(pkg, ver, py_tag, abi_tag, remainder, distro_tag, wheel_path):
    """Resolve rebuild suffix from environment or automated IBM COS check."""
    # 1. Direct explicit WHEEL_SUFFIX override (if manually specified)
    wheel_suffix = os.environ.get("WHEEL_SUFFIX")
    if wheel_suffix:
        return wheel_suffix

    # 2. Determine base architecture prefix: BASE_SUFFIX > POWERCORE_ARCH > ARCHITECTURE > "ppc64le"
    base_suffix = (
        os.environ.get("BASE_SUFFIX")
        or os.environ.get("POWERCORE_ARCH")
        or os.environ.get("ARCHITECTURE")
        or "ppc64le"
    )

    # 3. Automated IBM COS lookup
    # Canonical variables from PowerCore (with backward-compatible fallbacks)
    cos_api_key = (
        os.environ.get("IBMCLOUD_API_KEY")
        or os.environ.get("COS_WHEEL_API_KEY")
        or os.environ.get("COS_API_KEY")
        or os.environ.get("IAM_WRITER_API_KEY")
    )
    cos_instance_id = (
        os.environ.get("POWERCORE_COS_INSTANCE_CRN")
        or os.environ.get("COS_WHEEL_SERVICE_INSTANCE_ID")
        or os.environ.get("COS_INSTANCE_CRN")
        or os.environ.get("SERVICE_INSTANCE_ID")
        or ""
    )
    cos_endpoint = (
        os.environ.get("POWERCORE_COS_ENDPOINT")
        or os.environ.get("COS_WHEEL_ENDPOINT")
        or os.environ.get("COS_ENDPOINT")
        or os.environ.get("COS_URL")
        or "https://s3.us.cloud-object-storage.appdomain.cloud"
    )
    cos_bucket = (
        os.environ.get("POWERCORE_COS_BUILT_WHEELS_BUCKET")
        or os.environ.get("COS_WHEEL_BUCKET")
        or os.environ.get("POWERCORE_COS_BUILD_ARTIFACT_WHEELS_BUCKET")
        or "powercore-build-artifact-wheels-staging"
    )

    # 3. Exact package name and version for COS search
    # Search exact match: Pkg_name/<exact_version> (initial letter capitalized, exact version, NO fallback options)
    env_pkg_name = os.environ.get("COS_WHEEL_PACKAGE_NAME") or os.environ.get("COS_PACKAGE_NAME") or os.environ.get("PACKAGE_NAME") or ""
    if env_pkg_name.startswith("$"):
        env_pkg_name = ""
    env_pkg_name = env_pkg_name.strip()

    raw_pkg = env_pkg_name or pkg
    cap_pkg = raw_pkg[0].upper() + raw_pkg[1:] if raw_pkg else (pkg or "")

    env_ver = os.environ.get("COS_WHEEL_VERSION") or os.environ.get("COS_VERSION") or os.environ.get("PACKAGE_VERSION") or ""
    if env_ver.startswith("$"):
        env_ver = ""
    env_ver = env_ver.strip()

    exact_ver = env_ver or (ver.split("+")[0] if ver else "")

    if cos_api_key and pkg and ver:
        try:
            cos_adapter = COSAdapter(cos_api_key, cos_instance_id, cos_endpoint, cos_bucket)

            # Compute recipe SHA-256 (matching create_wheel_wrapper.sh generate_sha())
            wheel_sha = compute_recipe_sha(pkg, ver, py_tag, abi_tag, remainder, wheel_path)

            cos_prefix = f"{cap_pkg}/{exact_ver}"
            matched_prefix = cos_prefix

            sys.stderr.write(f"[INFO] [COS] Searching IBM COS bucket '{cos_bucket}' with prefix: {cos_prefix}...\n")
            cos_objects = cos_adapter.list_objects(cos_prefix) or []

            sys.stderr.write(f"[INFO] [COS] Found {len(cos_objects)} existing wheel(s) in COS under '{matched_prefix}'.\n")

            target_wheel_name = os.path.basename(wheel_path) if wheel_path else f"{pkg}-{ver}-{remainder}.whl"

            # Match whole wheel filename for this specific package and base version:
            # 1. Exact clean wheel: e.g. 're2-2024.7.2-py3-none-manylinux_2_34_ppc64le.whl'
            # 2. Existing rebuild variants: e.g. 're2-2024.7.2+ppc64le1-py3-none-manylinux_2_34_ppc64le.whl'
            base_ver = ver.split("+")[0]
            dist_pattern = rf"(?:{re.escape(pkg)}|{re.escape(pkg.replace('_', '-'))})"
            wheel_regex = re.compile(
                rf"^{dist_pattern}-{re.escape(base_ver)}(?:\+[^\-]+)?(?:-[0-9][^\-]*)?-{re.escape(remainder)}\.whl$",
                re.IGNORECASE
            )
            matching_cos_wheels = [k for k in cos_objects if wheel_regex.match(os.path.basename(k))]

            if not matching_cos_wheels:
                sys.stderr.write(f"[INFO] [COS] No existing wheel found in COS matching wheel '{target_wheel_name}'. Publishing first build clean.\n")
                return None

            # Prioritize exact clean wheel first, followed by rebuild variants
            exact_clean = [k for k in matching_cos_wheels if os.path.basename(k) == target_wheel_name]
            other_rebuilds = [k for k in matching_cos_wheels if os.path.basename(k) != target_wheel_name]
            matching_cos_wheels = exact_clean + other_rebuilds

            sys.stderr.write(f"[INFO] [COS] Found matching wheel(s) for '{target_wheel_name}': {[os.path.basename(k) for k in matching_cos_wheels]}\n")

            # Check for matching SHA-256
            sha_match_key = None
            if wheel_sha:
                for k in matching_cos_wheels:
                    r_sha = cos_adapter.get_sha(k)
                    if r_sha and r_sha.strip() == wheel_sha.strip():
                        sha_match_key = k
                        break

            suffix_pattern = rf"{re.escape(base_suffix)}(\d+)"

            if sha_match_key:
                m_suf = re.search(suffix_pattern, sha_match_key)
                if m_suf:
                    resolved = f"{base_suffix}{m_suf.group(1)}"
                    sys.stderr.write(f"[INFO] [COS] Remote SHA matches existing wheel: {os.path.basename(sha_match_key)}. Reusing suffix {resolved}.\n")
                    return resolved
                else:
                    sys.stderr.write(f"[INFO] [COS] Remote SHA matches clean wheel: {os.path.basename(sha_match_key)}. No rebuild suffix needed.\n")
                    return None
            else:
                existing_nums = []
                for k in matching_cos_wheels:
                    m_num = re.search(suffix_pattern, k)
                    if m_num:
                        existing_nums.append(int(m_num.group(1)))

                next_num = max(existing_nums) + 1 if existing_nums else 1
                resolved = f"{base_suffix}{next_num}"
                sys.stderr.write(f"[INFO] [COS] SHA mismatch with existing wheel(s). Allocated next rebuild slot: {resolved}\n")
                return resolved
        except Exception as e:
            sys.stderr.write(f"[WARN] [COS] Suffix lookup encountered error: {e}\n")
    elif not cos_api_key:
        sys.stderr.write("[INFO] [COS] COS credentials not provided (need COS_WHEEL_API_KEY or IBMCLOUD_API_KEY); skipping automated COS lookup.\n")

    return None


resolve_ppc64le_suffix = resolve_suffix


def main():
    if len(sys.argv) < 3:
        print("Usage: python3 wheel-postprocess.py <wheel_name> <extracted_temp_dir> [distro_tag] [wheel_path]")
        sys.exit(1)

    wheel_name = sys.argv[1]
    temp_dir = sys.argv[2]
    distro_tag = sys.argv[3] if len(sys.argv) > 3 else ""
    wheel_path = sys.argv[4] if len(sys.argv) > 4 else ""

    # Parse wheel filename components
    match = re.match(r"^([^-]+)-([^-]+?)(?:-([0-9][^-]*))?-([^-]+)-([^-]+)-([^-]+)\.whl$", wheel_name)
    if not match:
        print(f"KEEP:{wheel_name}")
        sys.exit(0)

    dist, version, build, py_tag, abi_tag, plat_tag = match.groups()
    pkg, ver = dist, version
    remainder = f"{py_tag}-{abi_tag}-{plat_tag}"

    resolved_suffix = resolve_suffix(pkg, ver, py_tag, abi_tag, remainder, distro_tag, wheel_path)

    segments = []
    if distro_tag:
        segments.append(distro_tag)
    if resolved_suffix:
        clean_suf = resolved_suffix.lstrip("+")
        segments.append(clean_suf)

    if not segments:
        print(f"KEEP:{wheel_name}")
        sys.exit(0)

    local_str = ".".join(segments)

    if "+" in version:
        base, existing_local = version.split("+", 1)
        if local_str in existing_local:
            new_version = version
        else:
            new_version = f"{base}+{existing_local}.{local_str}"
    else:
        new_version = f"{version}+{local_str}"

    if new_version == version:
        print(f"KEEP:{wheel_name}")
        sys.exit(0)

    build_part = f"-{build}" if build else ""
    new_wheel_name = f"{dist}-{new_version}{build_part}-{py_tag}-{abi_tag}-{plat_tag}.whl"

    # Find dist-info directory in temp_dir or immediate subdirectories
    dist_infos = [d for d in os.listdir(temp_dir) if d.endswith(".dist-info")]
    target_dir = temp_dir
    if not dist_infos:
        for sub in os.listdir(temp_dir):
            sub_path = os.path.join(temp_dir, sub)
            if os.path.isdir(sub_path):
                sub_dist_infos = [d for d in os.listdir(sub_path) if d.endswith(".dist-info")]
                if sub_dist_infos:
                    target_dir = sub_path
                    dist_infos = sub_dist_infos
                    break

    if not dist_infos:
        print(f"KEEP:{wheel_name}")
        sys.exit(0)

    old_dist_info = dist_infos[0]
    old_dist_info_path = os.path.join(target_dir, old_dist_info)

    base_name = old_dist_info[:-10] if old_dist_info.endswith('.dist-info') else old_dist_info
    dist_prefix = base_name.rsplit('-', 1)[0]
    new_dist_info = f"{dist_prefix}-{new_version}.dist-info"
    new_dist_info_path = os.path.join(target_dir, new_dist_info)

    # Update METADATA
    metadata_file = os.path.join(old_dist_info_path, "METADATA")
    if os.path.exists(metadata_file):
        with open(metadata_file, "r", encoding="utf-8") as f:
            lines = f.readlines()
        with open(metadata_file, "w", encoding="utf-8") as f:
            for line in lines:
                if line.startswith("Version:"):
                    f.write(f"Version: {new_version}\n")
                else:
                    f.write(line)

    # Rename dist-info directory
    if old_dist_info_path != new_dist_info_path:
        os.rename(old_dist_info_path, new_dist_info_path)

    print(f"RENAME:{new_wheel_name}:{new_dist_info}")


if __name__ == "__main__":
    main()

