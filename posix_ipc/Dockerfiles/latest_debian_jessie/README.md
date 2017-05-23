Docker build command:
docker build -t posix_ipc:16.04 .

Docker run command:
docker run --rm=True --privileged=True -it posix_ipc:16.04 /bin/bash
