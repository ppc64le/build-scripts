import os
import stat
import requests
import sys
import subprocess
import docker
import json

# GitHub base repo info
GITHUB_BUILD_SCRIPT_BASE_REPO = "build-scripts"
GITHUB_BUILD_SCRIPT_BASE_OWNER = "ppc64le"
HOME = os.getcwd()

package_data = {}
use_non_root = ""

# Updated image version to UBI 9.6
UBI_BASE_IMAGE = "registry.access.redhat.com/ubi9/ubi:9.6"
image_name = UBI_BASE_IMAGE
print("The base image is :",image_name)

def trigger_basic_validation_checks(file_name):
    key_checks = {
        "# Package": "package_name",
        "# Version": "package_version",
        "# Source repo": "package_url",
        "# Tested on": "",
        "# Maintainer": "maintainer",
        "# Language": "package_type",
        "# Travis-Check": "travis_check"
    }
    matched_keys = []
    # Check if license file exists
    file_parts = file_name.split('/')
    licence_file = f"{HOME}/{'/'.join(file_parts[:-1])}/LICENSE"
    if not os.path.exists(licence_file):
        raise ValueError("License file cannot be found.")

    # Check line endings
    script_path = f"{HOME}/{file_name}"
    eof = os.popen(f'file {script_path}').read()
    if 'crlf' in eof.lower():
        raise EOFError(
            f"Build script {file_name} contains Windows line endings (CRLF). "
            f"Please update it to use Linux line endings."
        )

    if os.path.exists(script_path):
        with open(script_path) as script_file_handler:
            all_lines = script_file_handler.readlines()

        for line in all_lines:
            try:
                for key in key_checks:
                    if key == '# Tested on' and key in line:
                        matched_keys.append(key)
                        distro_data = line.split(':')[-1].strip().split(' ')
                        package_data["distro_name"] = distro_data[0]
                        package_data["distro_version"] = distro_data[-1]
                    elif key in line:
                        matched_keys.append(key)
                        package_data[key_checks[key]] = line.split(':', 1)[-1].strip()
            except IndexError as ie:
                raise IndexError(str(ie))

        if set(matched_keys) == set(list(key_checks.keys())):
            print("Basic Checks passed")
            return True
        else:
            print("Basic Validation Checks Failed!!!")
            print(f"Required keys: {','.join(key_checks.keys())}")
            print(f"Found keys: {','.join(matched_keys)}")
            print(f"Missing required keys: {','.join(set(key_checks.keys()) - set(matched_keys))}")
            raise ValueError(f"Basic Validation Checks Failed for {file_name} !!!")
    else:
        raise ValueError("Build script not found.")


def trigger_script_validation_checks(file_name):
    global image_name
    print(f"Image used for container: {image_name}")
    client = docker.DockerClient(base_url='unix://var/run/docker.sock')

    st = os.stat(file_name)
    current_dir = os.getcwd()
    os.chmod(f"{current_dir}/{file_name}", st.st_mode | stat.S_IEXEC)

    container = client.containers.run(
        image_name,
        f"/home/tester/{file_name}",
        network='host',
        detach=True,
        volumes={current_dir: {'bind': '/home/tester/', 'mode': 'rw'}},
        stderr=True,
    )
    result = container.wait()
    try:
        print(container.logs().decode("utf-8"))
    except Exception:
        print(container.logs())
    container.remove()
    if int(result["StatusCode"]) != 0:
        raise Exception(f"Build script validation failed for {file_name}!")
    else:
        return True


def build_non_root_custom_docker_image():
    global image_name
    print("⚙️ Building custom Docker image for non-root user build...")
    os.system(
        f'docker build --build-arg BASE_IMAGE="{UBI_BASE_IMAGE}" '
        f'-t docker_non_root_image -f gha-script/dockerfile_non_root .'
    )
    image_name = "docker_non_root_image"
    return True


def validate_build_info_file(file_name):
    try:
        script_path = os.path.join(HOME, file_name)
        mandatory_fields = [
            'package_name', 'github_url', 'version', 'default_branch',
            'build_script', 'package_dir', 'maintainer', 'use_non_root_user'
        ]
        error_message = f"No `{{}}` field available in {file_name}."

        data = json.load(open(script_path, 'r'))

        for field in mandatory_fields:
            if field not in data:
                raise ValueError(error_message.format(field))

        if str(data['github_url']).endswith('/'):
            raise Exception(
                f"Build info validation failed for {file_name} due to '/' at end of github_url!"
            )

        for line in open(script_path, 'r').read().splitlines():
            if line.isspace():
                raise Exception(f"Build info validation failed for {file_name} due to empty line!")

        global use_non_root
        use_non_root = str(data['use_non_root_user']).lower()
        print(f"Non-root user: {use_non_root}")
        if use_non_root == "true":
            build_non_root_custom_docker_image()

        print("Validated build_info.json file successfully")
        return True
    except Exception as e:
        print(str(e))
        print(f"Failed to load build_info file at {file_name}!")
        raise e


def trigger_build_validation_travis(pr_number):
    pull_request_file_url = (
        f"https://api.github.com/repos/{GITHUB_BUILD_SCRIPT_BASE_OWNER}/"
        f"{GITHUB_BUILD_SCRIPT_BASE_REPO}/pulls/{pr_number}/files"
    )
    validated_file_list = []
    response = requests.get(pull_request_file_url).json()

    build_info = [f for f in response if 'build_info.json' in f.get('filename', '')]
    other_files = [f for f in response if 'build_info.json' not in f.get('filename', '')]
    ordered_files = build_info + other_files

    for f in ordered_files:
        print(f.get('filename', ''))

    for f in ordered_files:
        file_name = f.get('filename', "")
        if not file_name:
            continue
        status = f.get('status', "")
        if file_name.endswith('.sh') and "dockerfile" not in file_name.lower() and status != "removed":
            trigger_basic_validation_checks(file_name)
            travis_check = package_data.get('travis_check', 'false').lower()
            if travis_check == "true":
                trigger_script_validation_checks(file_name)
            else:
                print(f"Skipping validation for {file_name} as Travis-Check=False")
            validated_file_list.append(file_name)
        elif file_name.lower().endswith('build_info.json') and status != "removed":
            validate_build_info_file(file_name)
            validated_file_list.append(file_name)

    if not validated_file_list:
        print("No scripts available for validation.")
    else:
        print("Validated the following scripts:")
        print(*validated_file_list, sep="\n")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python validate_build.py <pr_number>")
        sys.exit(1)
    trigger_build_validation_travis(sys.argv[1])
