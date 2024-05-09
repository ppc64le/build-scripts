import os
import stat
import requests
import sys
import subprocess
import docker
import json
import argparse
from sys import argv
from subprocess import PIPE
from datetime import datetime


GITHUB_BUILD_SCRIPT_BASE_REPO = "build-scripts"
GITHUB_BUILD_SCRIPT_BASE_OWNER = "ppc64le"

HOME = os.getcwd()

package_data = {}


def trigger_script_validation_checks(image_name = "registry.access.redhat.com/ubi9/ubi:9.3"):
    
    parser = argparse.ArgumentParser(description="""Pass `build script` name""")
    parser.add_argument('-f','--filename', type=str, help='Filename', required=True)
    args = parser.parse_args()
    file_name = args.filename
    

    # Spawn a container and pass the build script
    client = docker.DockerClient(base_url='unix://var/run/docker.sock')
    st = os.stat(file_name)
    current_dir = os.getcwd()
    os.chmod("{}/{}".format(current_dir,file_name), st.st_mode | stat.S_IEXEC)

    # Let the container run in non detach mode, as we need to delete the container on operation completion
    print("\n Creating Container....")
    print("\n Wait ...")
    print(f"\n running file:{file_name}")
    container = client.containers.run(
        image_name,
        "/home/tester/{}".format(file_name),
        network = 'host',
        detach = True,
        volumes = {
            current_dir : {'bind': '/home/tester/', 'mode': 'rw'}
        },
        stderr = True, # Return logs from STDERR
    )
    result = container.wait()
    try:
        print(container.logs().decode("utf-8"))

    except Exception:

        print(container.logs())

    container.remove()
    if int(result["StatusCode"]) != 0:
        #raise Exception(f"Build script validation failed for {file_name} !")
        return False 
    else:
        return True


container_result=trigger_script_validation_checks(image_name = "registry.access.redhat.com/ubi9/ubi:9.3")
if container_result:
    print("Executed script in container")
    
else:
    print("FAILING")
    print("Some Error while executing script in container")

sys.exit()
