# Pre-requisites

This dockerfile is an adaptation of the community dockerfile which rests at the root of grafana source.

In order to use it, first you need to clone the grafana source, checkout tag v8.1.5 and copy this dockerfile to the root of source directory as:

```
git clone https://github.com/grafana/grafana.git
cp Dockerfile.ubi grafana/
cd grafana
git checkout v8.1.5
```

# Build the image

```
docker build -f Dockerfile.ubi -t ibmcom/grafana-ppc64le:8.1.5 .
```

# Docker run command  (this will start grafana-server with default configuration on port 3000)

```
docker run -p 3000:3000 --name grafana ibmcom/grafana-ppc64le:8.1.5
```
