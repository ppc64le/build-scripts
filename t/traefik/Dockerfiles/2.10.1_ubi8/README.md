To build the traefik Dockerfile:

docker build -t traefik .

To run the traefik Dockerfile:

docker run -d   --name traefik   --publish 80:80   --volume $PWD/traefik.toml:/etc/traefik/traefik.toml   --volume /var/run/docker.sock:/var/run/docker.sock   traefik
