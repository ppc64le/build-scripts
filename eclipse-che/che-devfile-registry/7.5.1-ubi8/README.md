# Steps for creating che-devfile-registry docker image on POWER

1. Build this on machine with latest docker

2. Execute following command:
```bash
git clone -b 7.5.1 https://github.com/eclipse/che-devfile-registry.git
```

3. Download following file from this page:
- content_sets_epel7.repo

4. Execute following commands:
```bash
mv content_sets_epel7.repo che-devfile-registry/build/dockerfiles/
cd che-devfile-registry
```

5. Build the image:
```bash
docker build -t <repository>/che-devfile-registry-ubi8-ppc64le -f build/dockerfiles/rhel.Dockerfile .
docker push <repository>//che-devfile-registry-ubi8-ppc64le
```
