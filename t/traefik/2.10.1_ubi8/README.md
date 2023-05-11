#To build the Dockerfile:
docker build -t traefik .

#To run the Dockerfile:
docker run -d   --name traefik2   --network traefik-net   --publish 80:80   --volume $PWD/traefik.toml:/etc/traefik/traefik.toml   --volume /var/run/docker.sock:/var/run/docker.sock   traefik
