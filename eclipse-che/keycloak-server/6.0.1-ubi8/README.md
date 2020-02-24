# Steps for creating keycloak-server docker image on POWER

1. Execute following command:
```bash
git clone -b 6.0.1 https://github.com/keycloak/keycloak-containers.git
```

2. Download following files from this page:
Dockerfile

3. Execute following commands:
```bash
mv Dockerfile keycloak-containers/server
cd keycloak-containers/server
```

4. Build the image:
```bash
docker build -t <repository>/keycloak-ubi8-ppc64le .
docker push <repository>/keycloak-ubi8-ppc64le
```
