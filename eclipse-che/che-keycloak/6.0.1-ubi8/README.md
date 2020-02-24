# Steps for creating che-keycloak docker image on POWER
1. Execute following commands:
```bash
git clone https://github.com/eclipse/che.git
```

2. Download following file from this page:
- Dockerfile

3. Execute following commands:
```bash
mv Dockerfile che/dockerfiles/keycloak/
cd che/dockerfiles/keycloak/
```

4. Edit the `FROM` statement of the Dockerfile to refer to the keycloak-server image.

5. Build the image:
```bash
docker build -t <repository>/che-keycloak-ubi8-ppc64le .
docker push <repository>/che-keycloak-ubi8-ppc64le
```
