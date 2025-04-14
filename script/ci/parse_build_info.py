'''
This script is to parse the build-info.json file of the given package and get the version info.

It takes inputs as command line arguments, if no arguments provided, works on Vault with version v1.17.3.
First argument is Package name
Second argument is Version

First it parse the build_info.json file and tries to get/match the given version with available versions in json file.
Once version is available, then parse and generate a json string with below details:
{
    'docker_dir': <docker directory in json file>,
    'build_script': <Build script command>,
    'args': <Arguments required for build-scripts and Dockerfile>,
    'patches': <Patches required for build-scripts and Dockerfile>,
    'docker_cmd': <Docker command to generate required docker image with mentioned version>,
    'base_docker_image': <Base image used in Package docker image>,
    'docker_build': <True if dockerfiles is available for the package else False>,
    'validate_build_script': <True if build-script is available for package otherwise False>,
    'use_non_root_user': <Run it as root or non-root>
    'build_script_raw_url': <Build-script raw URL>
    'wheel_build': <True if wheel is available for the package else False>
}

This generated commands/parameter can be used in any CI/script to execute build-script or docker image.
'''

import os
import json
import re
import requests
import sys

path_separator = os.path.sep
ROOT = path_separator.join(os.path.dirname(os.path.realpath(__file__)).split(path_separator)[:-2])

DOCKER_COMMAND = 'docker_cmd'
BUILD_SCRIPT = 'build_script'
DOCKER_BUILD = 'docker_build'
VALIDATE_BUILD_SCRIPT = 'validate_build_script'
DOCKER_DIR = 'docker_dir'
DIR = 'dir'
PATCHES = 'patches'
ARGS = 'args'
DOCKER_FILE = 'docker_file'
BASE_CONTAINER = 'base_docker_image'
NON_ROOT_USER = 'use_non_root_user'
BUILD_SCRIPT_RAW_URL = 'build_script_raw_url'
WHEEL_BUILD = 'wheel_build'

build_details = {
    DOCKER_DIR : '',
    BUILD_SCRIPT: '',
    ARGS : {},
    PATCHES : {},
    DOCKER_COMMAND : '',
    BASE_CONTAINER : 'registry.access.redhat.com/ubi8/ubi',
    DOCKER_BUILD: True,
    VALIDATE_BUILD_SCRIPT: True,
    NON_ROOT_USER : False,
    BUILD_SCRIPT_RAW_URL : "",
    WHEEL_BUILD: False
}

if len(sys.argv) == 3:
    package_name = sys.argv[1]
    version = sys.argv[2]
else:
    package_name = 'vault'
    version = 'v1.9.2'
# package_name = 'Elasticsearch'
# version = 'v8.1.1'

package_name = package_name.lower()

image_name = "ibmcom/" + package_name + "-ppc64le:" + version.replace('/', '_')
version_key =  None
branch = "master"
build_scipt = ''
raw_url_prefix = "https://raw.githubusercontent.com/ppc64le/build-scripts/" + branch + "/" + "/" .join([package_name[0], package_name])

config_json = {}

config_file_name = f"{ROOT}{path_separator}{package_name[0]}{path_separator}{package_name}{path_separator}build_info.json"
if(os.path.exists(config_file_name)):
    # Read the local file if available.
    f = open(config_file_name, 'r')
    contents = f.read()
    config_json = json.loads(contents)
else:
    # If local file not available, read it from github.
    github_url = raw_url_prefix + "/build_info.json"
    r = requests.get(github_url)
    if r.status_code == 200:
        config_json = r.json()

if config_json:
    # Parse the config file and load the common tags.
    build_details[DOCKER_COMMAND] = config_json[DOCKER_COMMAND] if DOCKER_COMMAND in config_json else ''
    build_scipt = config_json[BUILD_SCRIPT] if BUILD_SCRIPT in config_json else ''
    build_details[DOCKER_BUILD] = config_json[DOCKER_BUILD] if DOCKER_BUILD in config_json else True
    build_details[VALIDATE_BUILD_SCRIPT] = config_json[VALIDATE_BUILD_SCRIPT] if VALIDATE_BUILD_SCRIPT in config_json else True
    build_details[NON_ROOT_USER] = config_json[NON_ROOT_USER] if NON_ROOT_USER in config_json else False
    build_details[WHEEL_BUILD] = config_json[WHEEL_BUILD] if WHEEL_BUILD in config_json else False

    # Check for the version in Json file otherwise try to match regex.
    if version not in config_json:
        for key in config_json.keys():
            if version_key:
                break
            sub_keys = [x.strip() for x in key.split(',')]
            if sub_keys:
                if version in sub_keys:
                    version_key = key
                    break
                for sub_key in sub_keys:
                    regex = f"^{sub_key}$"
                    if re.search(regex, version):
                        version_key = key
                        break
    else:
        version_key = version

    # If no match found, pick the last version configuration. 
    # Considering, latest version info added at end.
    if not version_key:
        version_key = config_json.keys()[-1]
    
    version_config = config_json[version_key]

    if build_details[DOCKER_BUILD] and DIR not in version_config:
        print("Not docker directory provided, hence exiting.")
        exit(2)

    build_details[DOCKER_DIR] = version_config[DIR] if DIR in version_config else ''

    build_args = ''
    if PATCHES in version_config:
        # Parsing and generating PATCH arguments
        for patch_name in version_config[PATCHES].keys():
            build_args += f" --build-args {patch_name}={version_config[PATCHES][patch_name]} "
    if ARGS in version_config:
        # Parsing and generating BUILD-ARG arguments.
        for arg_name in version_config[ARGS].keys():
            build_details[ARGS][arg_name] = version_config[ARGS][arg_name]
            build_args += f" --build-args {arg_name}={version_config[ARGS][arg_name]} "
    
    
    build_scipt = version_config[BUILD_SCRIPT].strip() if BUILD_SCRIPT in version_config else build_scipt
    if not build_scipt and build_details[VALIDATE_BUILD_SCRIPT]:
        print("Build-script is not mentioned...")
        exit(1)

    build_details[BUILD_SCRIPT_RAW_URL] = raw_url_prefix + f"/{build_scipt}"
    # Generating docker build command with
    #    --build-args with ARG values
    #    --build-args with PATCH values
    build_details[DOCKER_COMMAND] = f"sudo docker build -t {image_name}" + (build_args if build_args else '') + (f"-f {version_config[DOCKER_FILE]}" if DOCKER_FILE in version_config else '') + f" {build_details[DOCKER_DIR]}" if build_details[DOCKER_DIR] else ''
    # Geneating build & validation command with
    #    Setting variable mentioned in ARG key value pairs.
    #    Running it as sudo if root user otherwise running it as non-root depending on `use_non_root_user` key in info file.
    build_details[BUILD_SCRIPT] = 'sudo ' if build_details[NON_ROOT_USER] else '' + (" ".join([f"{x}={build_details[ARGS][x]}" for x in build_details[ARGS].keys()])) + " ./" + build_scipt + " " + version
    # Setting base container if `base_docker_image` is mentioned otherwise taking ubi8 as the default base image for package docker image.
    build_details[BASE_CONTAINER] = version_config[BASE_CONTAINER] if BASE_CONTAINER in version_config else 'registry.access.redhat.com/ubi8/ubi'

    print(build_details)
