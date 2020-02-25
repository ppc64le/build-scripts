# Steps for creating remote-plugin-node docker image on POWER

 1. Ensure that Latest docker version should be installed
 2. Execute following commands:
 
 ```bash
git clone -b 7.3.2 https://github.com/eclipse/che-theia.git
cd che-theia/
rm -rf dockerfiles/remote-plugin-node/Dockerfile
mv Dockerfile che-theia/dockerfiles/remote-plugin-node docker
```
3.Build rremote-plugin-node docker

```bash
docker build -t <repository_name> .
```
