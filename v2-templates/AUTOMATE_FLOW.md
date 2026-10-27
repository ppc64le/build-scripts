# Automation Script Flow Documentation

## Overview

This document explains how the `automate.sh` script is created and used in the BulkPackageSearch build and test process. There are two distinct sets of automation scripts that serve different purposes.

## Two Types of Automation Scripts

### 1. Docker Architecture-Specific Scripts (`Docker-ppc64le/automate_*.sh`)

Located in `Docker-ppc64le/` and `Docker-s390x/` directories:
- `automate_buildscript.sh`
- `automate_drupal.sh`
- `automate_go.sh`
- `automate_java.sh`
- `automate_node.sh`
- `automate_php.sh`
- `automate_python.sh`
- `automate_ruby.sh`

**Purpose**: These are standalone automation scripts for specific language ecosystems and architectures. They handle cloning, building, and testing packages directly.

**Usage**: These scripts are NOT copied into Docker images during build time. They exist as reference implementations or for direct execution outside the container orchestration system.

### 2. Runtime-Generated `automate.sh`

**Purpose**: This is the actual script executed inside containers during package testing.

**Location**: Dynamically created in the output directory at runtime: `{OUTPUT_DIR}/{email}/{project}/{tech}/{package_name}_{version}/automate.sh`

## The Complete Flow

### Step 1: Template Preparation

Language-specific build script templates are stored in the `templates/` directory:
- `templates/build_script_python.sh`
- `templates/build_script_node.sh`
- `templates/build_script_java.sh`
- `templates/build_script_go.sh`
- `templates/build_script_ruby.sh`
- `templates/build_script_php.sh`
- `templates/build_script_drupal.sh`
- `templates/build_script_buildscript.sh`
- `templates/build_script_conda.sh`

### Step 2: Docker Image Build

**File**: `Docker/build_upload_images.sh`

1. Builds base image from `Docker-ppc64le/Dockerfile.base.ubi` or `Docker-s390x/Dockerfile.base.ubi`
2. Builds language-specific images (python, node, java, etc.) from their respective Dockerfiles
3. **Important**: No `automate.sh` files are copied into images during build
4. Dockerfiles have commented-out references to `/bin/automate.sh` as ENTRYPOINT (not currently used)

Example from `Dockerfile.node.ubi`:
```dockerfile
ENTRYPOINT ["/bin/bash", "-c"]
#ENTRYPOINT ["/bin/automate.sh", "-c"]  # Commented out
#CMD ["./automate.sh"]                   # Commented out
```

### Step 3: Runtime Container Spawning

**File**: `lib/BuildTestPackage.py`

**Function**: `spawn_container_for_testing()` (lines 729-775)

When a package needs to be tested:

1. **Create output directory** (line 746-754):
   ```
   {OUTPUT_DIR}/{email}/{project}/{tech}/{package_name}_{version}/
   ```

2. **Generate `automate.sh`** (lines 761-770):
   
   **Option A - Custom build script provided**:
   ```python
   if build_script_path:
       # Download if remote (HTTP URL) or use local path
       build_script_path = self.check_if_build_script_path_is_local_or_remote(build_script_path)
       shutil.copy(build_script_path, dest_file)
       # Ensure version is an environment variable
       self.ensure_version_is_a_env_param_in_build_script(dest_file)
   ```
   
   **Option B - Use language template** (default):
   ```python
   else:
       shutil.copy("{}/build_script_{}.sh".format(TEMPLATE_DIR, self.tech), dest_file)
   ```
   
   Where `dest_file = "{}/automate.sh".format(output_package_folder)`

3. **Make executable** (lines 771-773):
   ```python
   file_name = "{}/automate.sh".format(output_package_folder)
   st = os.stat(file_name)
   os.chmod(file_name, st.st_mode | stat.S_IEXEC)
   ```

4. **Mount and execute** (line 796):
   ```python
   "bash /home/tester/output/automate.sh {}".format(package_details['version'])
   ```

5. **Fix permissions** (lines 864-866):
   ```python
   container.exec_run(
       cmd="chown -R bulksearch-prod:bulksearch-prod /home/tester/output && chmod 777 /home/tester/output/automate.sh",
       user="root"
   )
   ```

### Step 4: Container Execution

The container runs with:
- **Working directory**: `/home/tester`
- **Output mounted**: `/home/tester/output` (contains the generated `automate.sh`)
- **Command**: `bash /home/tester/output/automate.sh {version}`
- **User**: `bulksearch-prod`

The `automate.sh` script then:
1. Clones the package repository
2. Checks out the specified version
3. Installs dependencies
4. Runs tests
5. Logs results to files in `/home/tester/output/`

## Key Files and Their Roles

| File/Directory | Purpose |
|----------------|---------|
| `templates/build_script_*.sh` | Source templates for language-specific build scripts |
| `lib/BuildTestPackage.py` | Orchestrates container spawning and `automate.sh` creation |
| `Docker-ppc64le/automate_*.sh` | Standalone automation scripts (not used in container flow) |
| `Docker-ppc64le/Dockerfile.*.ubi` | Docker image definitions (no automate.sh copied) |
| `{OUTPUT_DIR}/.../automate.sh` | Runtime-generated script executed in container |

## Important Notes

1. **No build-time copying**: The `automate.sh` file is NOT part of the Docker image
2. **Runtime generation**: Each package test gets its own `automate.sh` created dynamically
3. **Template-based**: Default behavior uses language-specific templates
4. **Custom scripts supported**: Users can provide custom build scripts via `build_script_path`
5. **Permissions**: The script mentions umask 0022 is needed on s390x VSI to avoid access failures for `automate.sh` (see `start_server.sh:20`)

## Example Flow for Python Package

1. User requests testing of `requests` package version `2.28.0`
2. Python code creates: `output/user@example.com/myproject/python/requests_2.28.0/`
3. Copies `templates/build_script_python.sh` → `output/.../automate.sh`
4. Spawns container with `pythontesting` image
5. Mounts output directory to `/home/tester/output`
6. Executes: `bash /home/tester/output/automate.sh 2.28.0`
7. Script clones requests repo, installs, tests, logs results
8. Results written to `/home/tester/output/` files

## References

- Main orchestration: [`lib/BuildTestPackage.py`](lib/BuildTestPackage.py)
- Template directory: [`templates/`](templates/)
- Docker build script: [`Docker/build_upload_images.sh`](Docker/build_upload_images.sh)
- Dockerfiles: [`Docker-ppc64le/`](Docker-ppc64le/) and [`Docker-s390x/`](Docker-s390x/)