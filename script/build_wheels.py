import os
import stat
import requests
import sys
import subprocess
import docker
import json
   
def trigger_build_wheel(wrapper_file, python_version, image_name, file_name, version):
    # Docker client setup
    client = docker.DockerClient(base_url='unix://var/run/docker.sock')
    
    # Modify permissions for the main script
    st1 = os.stat(wrapper_file)
    current_dir = os.getcwd()
    
    os.chmod(f"{current_dir}/{wrapper_file}", st1.st_mode | stat.S_IEXEC)
 
    print(current_dir)
    print(f"Running script: {wrapper_file}")
    print(f"Additional file used by script: {file_name}")
 
    # Extract just the file names    
    script_name = file_name.split("/")[1]
 
    try:
        # Command to run only the main script (which uses the additional file internally)
        command = [
            "bash",
            "-c",
            f"cd /home/tester/ && ./{wrapper_file} {python_version} {file_name} {version}"
        ]
        
        # Run container
        container = client.containers.run(
            image_name,
            command,
            network='host',
            detach=True,
            volumes={current_dir: {'bind': '/home/tester/', 'mode': 'rw'}},  # Mount current directory with both files
            stderr=True,
            stdout=True
        )
        
        #  STREAM logs in real-time
        for log in container.logs(stream=True, stdout=True, stderr=True, follow=True):
            print(log.decode("utf-8").rstrip())

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
    trigger_build_wheel(sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4],sys.argv[5])
