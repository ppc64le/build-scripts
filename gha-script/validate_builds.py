import os
import stat
import requests
import sys
import docker
import json
import datetime


GITHUB_BUILD_SCRIPT_BASE_REPO = "build-scripts"
GITHUB_BUILD_SCRIPT_BASE_OWNER = "ppc64le"
HOME = os.getcwd()

package_data = {}
use_non_root = ""
image_name = "registry.access.redhat.com/ubi9/ubi:9.6"

def trigger_basic_validation_checks(file_name):
    key_checks = {
        "# Package": "package_name",
        "# Version": "package_version",
        "# Source repo": "package_url",
        "# Tested on": "",
        "# Maintainer": "maintainer",
        "# Language": "package_type",
        "# Ci-Check": "ci_check"
    }
    matched_keys = []
    # Check if apache license file exists
    file_parts = file_name.split('/')
    licence_file = "{}/{}/LICENSE".format(HOME, "/".join(file_parts[:-1]))
    if not os.path.exists(licence_file):
        raise ValueError("License file cannot be not found.")

    # Check if components of Doc string are available.
    script_path = "{}/{}".format(HOME, file_name)
    
    #Check build script line endings 
    eof=os.popen('file '+script_path).read()
    if 'crlf' in eof.lower():
        raise EOFError("Build script {} contains windows line endings(CRLF), Please update build script with Linux based line endings.".format(file_name))

    if os.path.exists(script_path):
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
                        package_data[key_checks[key]] = line.split(':',1)[-1].strip()
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
            print("Missing required keys: {}".format(",".join(set(key_checks.keys())-set(matched_keys))))
            raise ValueError(f"Basic Validation Checks Failed for {file_name} !!!")
    else:
        raise ValueError("Build script not found.")

def log_msg(message):
    """Helper to print with timestamp"""
    print(f"[{datetime.datetime.now().strftime('%H:%M:%S')}] {message}")

def trigger_script_validation_checks(file_name):
    global image_name
    log_msg(f"Starting validation. Image: {image_name}")
    
    # Initialize Client
    try:
        log_msg("Connecting to Docker socket...")
        client = docker.DockerClient(base_url='unix://var/run/docker.sock')
        log_msg("Docker client connected.")
    except Exception as e:
        log_msg(f"Failed to connect to Docker: {e}")
        raise e

    # File Permissions
    log_msg(f"Setting execution permissions for {file_name}...")
    st = os.stat(file_name)
    current_dir = os.getcwd()
    os.chmod("{}/{}".format(current_dir, file_name), st.st_mode | stat.S_IEXEC)
    
    # Check/Pull Image
    log_msg(f"Checking if image {image_name} exists locally...")
    try:
        client.images.get(image_name)
        log_msg("Image found locally.")
    except docker.errors.ImageNotFound:
        log_msg("Image NOT found locally. Pulling now... (This may take a while)")
        try:
            client.images.pull(image_name)
            log_msg("Image pulled successfully.")
        except Exception as e:
            log_msg(f"Failed to pull image: {e}")
            raise e

    # Spawn Container
    log_msg(f"Spawning container to run /home/tester/{file_name}...")
    try:
        # We run detached=True so we can control the log streaming manually below
        container = client.containers.run(
            image_name,
            "/home/tester/{}".format(file_name),
            network = 'host',
            detach = True,
            volumes = {
                current_dir : {'bind': '/home/tester/', 'mode': 'rw'}
            },
            stderr = True, # Merge stderr into stdout for easier reading
        )
        log_msg(f"Container started. ID: {container.short_id}")
    except Exception as e:
        log_msg(f"Failed to start container: {e}")
        raise e

    # Stream Logs
    # Instead of waiting silently, we print logs as they happen.
    log_msg("Streaming container logs...")
    print("----- CONTAINER LOGS START -----")
    try:
        for line in container.logs(stream=True):
            # Decode bytes to string and strip trailing newlines to avoid double spacing
            print(line.decode("utf-8").strip())
    except Exception as e:
        log_msg(f"Error while streaming logs: {e}")
    print("----- CONTAINER LOGS END -----")

    # Get Exit Code
    # The stream ends when the container stops, so wait() here should be instant.
    result = container.wait()
    log_msg(f"Container finished with status code: {result['StatusCode']}")
    
    # Cleanup
    try:
        container.remove()
        log_msg("Container removed.")
    except Exception as e:
        log_msg(f"Warning: Failed to remove container: {e}")

    # Verify Success
    if int(result["StatusCode"]) != 0:
        raise Exception(f"Build script validation failed for {file_name} with exit code {result['StatusCode']}!")
    else:
        return True

def build_non_root_custom_docker_image():
    global image_name
    print("Building custom docker image for non root user build")
    os.system('docker build --build-arg BASE_IMAGE="registry.access.redhat.com/ubi9/ubi:9.6" -t docker_non_root_image -f gha-script/dockerfile_non_root .')
    image_name = "docker_non_root_image"
    return True



def validate_build_info_file(file_name):
    try:
        script_path = os.path.join(HOME, file_name)
        mandatory_fields = ['package_name', 'github_url', 'version', 'default_branch', 'build_script', 'package_dir', 'maintainer', 'use_non_root_user']
        error_message = f"No `{{}}` field available in {file_name}."

        data = json.load(open(script_path, 'r'))

        # Check for mandatory fields.
        for field in mandatory_fields:
            if field not in data:
                raise ValueError(error_message.format(field))
            
        # Check for valid Github url
        print(str(data['github_url']))
        if str(data['github_url']).endswith('/'):
            raise Exception(f"Build info validation failed for {file_name} due to \"/\" present at the end of github url !")
        
        # Check for empty lines
        lines = open(script_path, 'r').read().splitlines()
        for line in lines :
            if line.isspace() == True:
                raise Exception(f"Build info validation failed for {file_name} due to empty line present !")

        # check for container user mode
        global use_non_root
        print("Non root user: " + str(data['use_non_root_user']).lower())
        use_non_root = str(data['use_non_root_user']).lower()
        if use_non_root == "true":
            build_non_root_custom_docker_image()

        print("Validated build_info.json file successfully")
        return True
    except Exception as e:
        print(str(e))
        print(f"Failed to load build_info file at {file_name} !")
        raise e

def trigger_build_validation_ci(pr_number):
    pull_request_file_url = "https://api.github.com/repos/{}/{}/pulls/{}/files".format(
        GITHUB_BUILD_SCRIPT_BASE_OWNER,
        GITHUB_BUILD_SCRIPT_BASE_REPO,
        pr_number
    )
    print(f"pull_request_file_url:{pull_request_file_url}" )
    
    # capture the full response object first
    req_response = requests.get(pull_request_file_url)
    
    # Check for HTTP errors (404 Not Found, 403 Forbidden, etc.)
    if req_response.status_code != 200:
        print(f"Error calling GitHub API. Status Code: {req_response.status_code}")
        print(f"Response: {req_response.text}")
        sys.exit(1)

    # Parse JSON only if successful
    response = req_response.json()

    # Double check validation to ensure we received a list
    if not isinstance(response, list):
        print(f"Unexpected API response format. Expected list, got {type(response)}")
        print(response)
        sys.exit(1)

    validated_file_list = []

    ordered_files = []
    build_info = [file for file in response if 'build_info.json' in file.get('filename')]
    other_files = [file for file in response if 'build_info.json' not in file.get('filename')]

    ordered_files = build_info + other_files
    for file in ordered_files:
        filename = file.get('filename', "")
        print(f"{filename}")
        
    # Trigger validation for all shell scripts
    for i in ordered_files:
        file_name = i.get('filename', "")
        if not file_name:
            continue
        status = i.get('status', "")
        if file_name.endswith('.sh') and "dockerfile" not in file_name.lower() and status != "removed":
            # perform basic validation check
            trigger_basic_validation_checks(file_name)
            
            #check ci-check from package header  
            ci_check=package_data['ci_check'].lower()
            if ci_check=="true":
                # Build/test script files
                trigger_script_validation_checks(file_name)
            else:
                print("Skipping Build script validation for {} as ci-Check flag is set to False".format(file_name))
            # Keep track of validated files.
            validated_file_list.append(file_name)
        elif file_name.lower().endswith('build_info.json') and status != "removed":
            validate_build_info_file(file_name)
            # Keep track of validated files.
            validated_file_list.append(file_name)
        
    
    if len(validated_file_list) == 0 :
        print("No scripts available for validation.")
    else:
        print("Validated below scripts:")
        print(*validated_file_list, sep="\n")

if __name__=="__main__":
    trigger_build_validation_ci(sys.argv[1])
