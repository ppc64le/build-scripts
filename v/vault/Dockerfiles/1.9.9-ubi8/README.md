Building Vault

1. Building the image:

Clone the repository:
```
git clone https://github.com/hashicorp/docker-vault.git
git checkout v1.9.9
docker build --build-arg VAULT_VERSION=v1.9.9 -t vault .
docker run -d --name=dev-vault vault
```
2. Validating the image: On OCP
```
oc new-project vault
oc new-app image-registry.openshift-image-registry.svc:5000/vault/vault

oc get all

[root@comedian1 ubi]# oc get all
NAME                         READY   STATUS    RESTARTS   AGE
pod/vault-57bcc8764f-ppvnw   1/1     Running   0          22h

NAME                                            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
service/vault                                   ClusterIP   172.30.182.124   <none>        8200/TCP            22h

NAME                                                READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/vault                               1/1     1            1           22h

NAME                                                           DESIRED   CURRENT   READY   AGE
replicaset.apps/vault-57bcc8764f                               1         1         1       22h
replicaset.apps/vault-846c84949d                               0         0         0       22h

NAME                                   IMAGE REPOSITORY                                                                           TAGS     UPDATED
imagestream.image.openshift.io/vault   default-<cluster-address>/vault/vault   latest   23 hours ago
```
3. Following are the steps to run the vault with helm on openshift:
```
# Define Route
export VAULT_URL=vault.apps.domain.name

vi override-standalone.yaml

global:
  openshift: true
injector:
  image:
    repository: "image-registry.openshift-image-registry.svc:5000/vault/vault-k8s"
    tag: "latest"
    pullPolicy: IfNotPresent

  # agentImage sets the repo and tag of the Vault image to use for the Vault Agent
  # containers.  This should be set to the official Vault image.  Vault 1.3.1+ is
  # required.
  agentImage:
    repository: "image-registry.openshift-image-registry.svc:5000/vault/vault"
    tag: "latest"

server:

  image:
    repository: "image-registry.openshift-image-registry.svc:5000/vault/vault"
    tag: "latest"
    # Overrides the default Image Pull Policy
    pullPolicy: IfNotPresent
  route:
    enabled: true
    host: vault.apps.domain.name
  standalone:
    enabled: true
    config: |
      ui = true
      listener "tcp" {
        address = "[::]:8200"
        cluster_address = "[::]:8201"
        tls_cert_file = "/var/run/secrets/kubernetes.io/certs/tls.crt"
        tls_key_file = "/var/run/secrets/kubernetes.io/certs/tls.key"
      }
      storage "file" {
       path = "/vault/data"
      }


helm repo add hashicorp https://helm.releases.hashicorp.com

oc adm policy add-scc-to-user -z default -n vault privileged

helm install vault hashicorp/vault -f override-standalone.yaml  --set "server.dev.enabled=true" --version 0.19.0

oc get all

NAME                                       READY   STATUS    RESTARTS   AGE
pod/vault-0                                1/1     Running   0          10m
pod/vault-agent-injector-9789b6665-9gkwt   1/1     Running   0          10m

NAME                               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
service/vault                      ClusterIP   172.30.202.175   <none>        8200/TCP,8201/TCP   10m
service/vault-agent-injector-svc   ClusterIP   172.30.134.230   <none>        443/TCP             10m
service/vault-internal             ClusterIP   None             <none>        8200/TCP,8201/TCP   10m

NAME                                   READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/vault-agent-injector   1/1     1            1           10m

NAME                                             DESIRED   CURRENT   READY   AGE
replicaset.apps/vault-agent-injector-9789b6665   1         1         1       10m

NAME                     READY   AGE
statefulset.apps/vault   1/1     10m

NAME                                       IMAGE REPOSITORY                                                                                TAGS     UPDATED
imagestream.image.openshift.io/vault       default-<cluster-address>/vault/vault       latest   3 days ago
imagestream.image.openshift.io/vault-k8s   default-<cluster-address>/vault/vault-k8s   latest   3 days ago
imagestream.image.openshift.io/vault1      default-<cluster-address>/vault/vault1      latest   3 days ago

NAME                             HOST/PORT                PATH   SERVICES   PORT   TERMINATION   WILDCARD
route.route.openshift.io/vault   vault.apps.domain.name          vault      8200   passthrough   None
```
