# Steps for creating che-unified-plugin-broker docker image on POWER

1. Ensure that Latest docker version should be installed

2. Execute following commands:

```bash
git clone https://github.com/eclipse/che-plugin-broker.git
git checkout tags/v3.0.0
cd che-plugin-broker
```
3. build Unified plugin broker

```bash
docker build -t <repository_name> -f build/metadata/rhel.Dockerfile .
```
