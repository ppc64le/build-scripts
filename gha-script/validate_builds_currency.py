import os
import stat
import requests
import sys
import subprocess
import docker
import json

def trigger_script_validation_checks(file_name, version, image_name):
    client = docker.DockerClient(base_url='unix://var/run/docker.sock')
    st = os.stat(file_name)
    current_dir = os.getcwd()
    os.chmod(os.path.join(current_dir, file_name), st.st_mode | stat.S_IEXEC)

    print("Working directory:", current_dir)
    print("Build script:", file_name)
    package = file_name.split("/")[1]
    print("Package name:", package)

    log_file_path = os.path.join(current_dir, "build_log.txt")
    with open(log_file_path, "w") as log_file:
        try:
            # For non-root builds the container runs as test_user but the workspace
            # is bind-mounted as root-owned. Run the build script via sudo bash so
            # it executes as root (yum/dnf, git clone etc. all work) while still
            # inside the non-root image environment.
            # Root builds use the plain UBI image and run as root directly.
            if image_name == "docker_non_root_image":
                # The workspace is bind-mounted as root-owned but the container
                # starts as test_user. Chown first so test_user can write to it
                # (git clone, gradle cache, etc.), then run the build script via
                # sudo bash so yum/dnf calls have the required root privileges.
                run_cmd = (
                    "sudo chown -R test_user:test_user /home/tester && "
                    f"sudo bash ./{file_name} {version}"
                )
            else:
                run_cmd = f"./{file_name} {version}"
            command = [
                "bash",
                "-c",
                f"cd /home/tester/ && {run_cmd}"
            ]

            container = client.containers.run(
                image=image_name,
                command=command,
                detach=True,
                volumes={current_dir: {'bind': '/home/tester/', 'mode': 'rw'}},
                stderr=True,
                stdout=True
            )

            # Stream logs to console and file
            stream = container.attach(stream=True, stdout=True, stderr=True)
            for line in stream:
                decoded_line = line.decode("utf-8").rstrip()
                print(decoded_line, flush=True)
                log_file.write(decoded_line + "\n")

            result = container.wait()
        except Exception as e:
            print(f"Failed to create or run container: {e}")
            raise
        finally:
            try:
                container.remove()
            except Exception as cleanup_error:
                print(f"Warning: failed to remove container: {cleanup_error}")

    if int(result["StatusCode"]) != 0:
        raise Exception(f"Build script validation failed for {file_name}!")
    else:
        print("Build script executed successfully.")
        return True

if __name__ == "__main__":
    print("Inside python program")
    sys.stdout.reconfigure(line_buffering=True)
    trigger_script_validation_checks(sys.argv[1], sys.argv[2], sys.argv[3])
