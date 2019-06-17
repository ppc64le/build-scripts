
 build:
   docker build -t eclipse/che-action .

 use:
    docker run -v /var/run/docker.sock:/var/run/docker.sock eclipse/che-action [command]

