# Keycloak Docker image

Keycloak Server Docker image.

## Git repo for Keycloak Docker file
   
   https://github.com/keycloak/keycloak-containers/tree/8.0.2/server

## Usage

Build the Keycloak docker image:

   docker build -t keycloak-ubi .

## Run the Keycloak docker image with exposing the ports as 8080 and 8443:

   docker run -d -p 8081:8080 -p 8443:8443 -e KEYCLOAK_USER=admin -e KEYCLOAK_PASSWORD=admin --name keycloak-duplicate keycloak-ubi

## Access the Keycloak site as:
```
   http://<IP Address>:8081
```   
```
   https://<Ip Address>:8443
```

## Note:

   While deploying the above built images using keycloak-operator, we might get 0/1 running state sometimes due to readiness and liveness probes failure(501-service unavailable). So we need to adjust the liveness and readiness parameters in the deployment file.
 