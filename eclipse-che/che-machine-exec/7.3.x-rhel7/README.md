# Steps for creating che-machine-exec docker image on POWER
 1. Ensure that Latest docker version should be installed
 2. Execute following commands:

```bash
git clone -b 7.3.x https://github.com/eclipse/che-machine-exec.git
git checkout tags/7.3.2
mv Dockerfile che-machine-exec
cd che-machine-exec
```
3.Build che-machine-exec

```bash
docker build -t <repository_name> .
```
