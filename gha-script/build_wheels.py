import os
import stat
import requests
import sys
import subprocess
import docker
import json
   
def trigger_build_wheel(wrapper_file, python_version, image_name, file_name, version, post_process_file):
    # Docker client setup
    client = docker.DockerClient(base_url='unix://var/run/docker.sock')
    
    current_dir = os.getcwd()

    # Make the wrapper script executable by owner, group, and other so that
    # any user inside the container (e.g. test_user in non-root builds) can
    # execute it after the workspace is bind-mounted.
    st1 = os.stat(f"{current_dir}/{wrapper_file}")
    os.chmod(f"{current_dir}/{wrapper_file}",
             st1.st_mode | stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH)
 
    print(current_dir)
    print(f"Running script: {wrapper_file}")
    print(f"Additional file used by script: {file_name}")
 
    # Extract just the file names    
    script_name = file_name.split("/")[1]
 
    try:
        # For non-root builds the workspace is bind-mounted as root-owned but
        # the container runs as test_user. Prepend a chown so test_user can
        # write to it, then run the wrapper script via sudo bash so that
        # yum/dnf calls inside it have the required root privileges.
        if image_name == "docker_non_root_image":
            setup = "sudo chown -R test_user:test_user /home/tester && "
            run_script = f"sudo bash ./{wrapper_file}"
        else:
            setup = ""
            run_script = f"./{wrapper_file}"
        # Command to run only the main script (which uses the additional file internally)
        command = [
            "bash",
            "-c",
            f"{setup}cd /home/tester/ && {run_script} {python_version} {file_name} {version} {post_process_file}"
        ]
        
        # Run container
        container = client.containers.run(
            image_name,
            command,
            detach=True,
            volumes={current_dir: {'bind': '/home/tester/', 'mode': 'rw'}},  # Mount current directory with both files
            stderr=True,
            stdout=True,
            environment={
               "GHA_CURRENCY_SERVICE_ID_API_KEY": os.getenv("GHA_CURRENCY_SERVICE_ID_API_KEY"),
               "GHA_CURRENCY_SERVICE_ID": os.getenv("GHA_CURRENCY_SERVICE_ID"),
               "AUDITWHEEL_EXCLUDE": os.getenv("AUDITWHEEL_EXCLUDE", ""),
               # Grype is installed on the host runner at scan-tools-bin/grype.
               # The workspace is volume-mounted at /home/tester/ inside the
               # container, so the binary is reachable at that in-container path.
               # Passing GRYPE_BIN lets generalized_wheel_scanner.py find it via
               # os.environ without relying on $PATH (which is host-only).
               "GRYPE_BIN": "/home/tester/scan-tools-bin/grype",
               # Set to "false" by pr-build.yaml to skip the CVE scan in PR builds.
               # Defaults to "true" (scan runs) when unset (currency-build.yaml).
               "ENABLE_CVE_SCAN": os.getenv("ENABLE_CVE_SCAN", "true"),
            }
        )
        
        #  STREAM logs in real-time
        for log in container.logs(stream=True, stdout=True, stderr=True, follow=True):
            print(log.decode("utf-8", errors="replace").rstrip())

        # Wait until it's done
        result = container.wait()

    except Exception as e:
        print(f"Failed to create container: {e}")
        raise

    finally:
        # Clean up container
        try:
            container.remove()
        except:
            pass

 
    # Check exit status
    if int(result["StatusCode"]) != 0:
        raise Exception(f"Build script validation failed for {file_name}!")
    else:
        return True

if __name__=="__main__":
    print("Inside python program")
    trigger_build_wheel(sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4],sys.argv[5],sys.argv[6])
