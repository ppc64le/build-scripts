# Using the Keycloak-Init-Container Docker image:

## Use the Git repo for building the Keycloak-Init-Container:
```
  https://github.com/keycloak/keycloak-containers/tree/8.0.2/keycloak-init-container
```

## Build the Keycloak-Init-Container docker image:
```bash
$ docker build -t keycloak-init-container-ubi .
```

## Run the Keycloak-Init-Container docker image:
```bash
$ docker run -td keycloak-init-container-ubi
```
