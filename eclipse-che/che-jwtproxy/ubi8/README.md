# Steps for creating che-jwtproxy docker image on POWER

1. Ensure that Latest docker version should be installed

2. Execute following commands:

```bash
git clone https://github.com/eclipse/che-jwtproxy.git
cd che-jwtproxy
```
3.Build che-jwtproxy

```bash
docker build -t <repository_name> -f rhel.Dockerfile .
```
