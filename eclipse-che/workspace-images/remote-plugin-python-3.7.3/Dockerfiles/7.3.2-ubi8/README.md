# Steps for creating remote-plugin-python-3.7.3 docker image on POWER

 1. Ensure that Latest docker version should be installed
 2. Execute following commands:
 
 ```bash
git clone -b 7.3.2 https://github.com/eclipse/che-theia.git
cd che-theia/dockerfiles/remote-plugin-python-3.7.3
rm -rf che-theia/dockerfiles/remote-plugin-python-3.7.3/Dockerfile
mv Dockerfile che-theia/dockerfiles/remote-plugin-python-3.7.3
```
3.Build remote-plugin-python-3.7.3

```bash
docker build -t <repository_name> .
```
