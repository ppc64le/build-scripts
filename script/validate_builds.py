import os
import requests
import sys
import subprocess


GITHUB_BUILD_SCRIPT_BASE_REPO = "build-scripts"
GITHUB_BUILD_SCRIPT_BASE_OWNER = "ppc64le"
HOME = os.getcwd()

def trigger_basic_validation_checks(file_name):
    key_checks = {
        "# Package": "package_name",
        "# Version": "package_version",
        "# Source repo": "package_url",
        "# Tested on": "",
        "# Maintainer": "maintainer",
        "# Language": "package_type"
    }
    matched_keys = []
    # Check if apache license file exists
    file_parts = file_name.split('/')
    licence_file = "{}/{}/LICENSE".format(HOME, "/".join(file_parts[:-1]))
    if not os.path.exists(licence_file):
        raise ValueError("License file cannot be not found.")

    # Check if components of Doc string are available.
    script_path = "{}/{}".format(HOME, file_name)

    if os.path.exists(script_path):
        package_data = {}
        all_lines = []
        with open(script_path) as script_file_handler:
            all_lines = script_file_handler.readlines()
        # from build script file extract package_name, package_version, packag_url, distro_name and distro_version
        for line in all_lines:
            try:
                for key in key_checks:
                    if key == '# Tested on' and key in line:
                        matched_keys.append(key)
                        distro_data = line.split(':')[-1].strip()
                        distro_data = distro_data.split(' ')
                        package_data["distro_name"] = distro_data[0]
                        package_data["distro_version"] = distro_data[-1]
                    elif key in line:
                        matched_keys.append(key)
                        package_data[key_checks[key]] = line.split(':')[-1].strip()
            except IndexError as ie:
                raise IndexError(str(ie))
        # check if all required keys are available
        if set(matched_keys) == set(list(key_checks.keys())):
            print("Basic Checks passed")
            return True
        else:
            print("Basic Validation Checks Failed!!!")
            print("Requried keys: {}".format(",".join(key_checks.keys())))
            print("Found keys: {}".format(",".join(matched_keys)))
            raise ValueError("Basic Validation Checks Failed!!!")
    else:
        raise ValueError("Build script not found.")

def trigger_script_validation_checks(file_name):
    output = subprocess.run(['sh', file_name])
    if output.returncode != 0:
        raise ValueError("Build script validation failed")
    else:
        return True

def trigger_build_validation_travis(pr_number):
    pull_request_file_url = "https://api.github.com/repos/{}/{}/pulls/{}/files".format(
        GITHUB_BUILD_SCRIPT_BASE_OWNER,
        GITHUB_BUILD_SCRIPT_BASE_REPO,
        pr_number
    )
    response = requests.get(pull_request_file_url).json()
    # Trigger validation for all shell scripts
    for i in response:
        file_name = i['filename']
        if file_name.endswith('.sh'):
            # perform basic validation check
            trigger_basic_validation_checks(file_name)
            # Build/test script files
            trigger_script_validation_checks(file_name)

if __name__=="__main__":
    if len(sys.argv) > 0:
        trigger_build_validation_travis(sys.argv[1])
    else:
        print("Non PR build.")
