# Building Vault
Docker build command: docker build -t ppc64le/vault .

Docker run command:
    Development mode:
        docker run --cap-add=IPC_LOCK -d --name=dev-vault ppc64le/vault

        Server mode:
        docker run --cap-add=IPC_LOCK -e 'VAULT_LOCAL_CONFIG={"backend": {"file": {"path": "/vault/file"}}, "default_lease_ttl": "168h", "max_lease_ttl": "720h"}' ppc64le/vault server

# Deploying Vault on Openshift
```
$ oc new-project vault-test
--> Now using project "vault-test" on server "https://api-<cluster-address>:6443".
    You can add applications to this project with the 'new-app' command. For example, try:
    oc new-app rails-postgresql-example
    to build a new example application in Ruby. Or use kubectl to deploy a simple Kubernetes application:
    kubectl create deployment hello-node --image=k8s.gcr.io/serve_hostname

$ oc adm policy add-scc-to-user anyuid -z default
--> clusterrole.rbac.authorization.k8s.io/system:openshift:scc:anyuid added: "default"

$oc new-app ibmcom/vault-ppc64le:1.5.3-ubi8 -e SKIP_CHOWN=true -e SKIP_SETCAP=true
--> Found container image d232b8f (8 months old) from Docker Hub for "ibmcom/vault-ppc64le:1.5.3-ubi8"
    Red Hat Universal Base Image 8
    ------------------------------
    The Universal Base Image is designed and engineered to be the base layer for all of your containerized applications, middleware and utilities. This base image is freely redistributable, but Red Hat only supports Red Hat technologies through subscriptions for Red Hat products. This image is maintained by Red Hat and updated regularly.
    Tags: base rhel8
    * An image stream tag will be created as "vault-ppc64le:1.5.3-ubi8" that will track this image
--> Creating resources ...
    imagestream.image.openshift.io "vault-ppc64le" created
    deployment.apps "vault-ppc64le" created
    service "vault-ppc64le" created
--> Success
    Application is not exposed. You can expose services to the outside world by executing one or more of the commands below:
     'oc expose service/vault-ppc64le'
    Run 'oc status' to view your app.

$ oc status
--> In project vault-test on server https://api-<cluster-address>:6443
    svc/vault-ppc64le - 172.30.227.208:8200
    deployment/vault-ppc64le deploys istag/vault-ppc64le:1.5.3-ubi8
    deployment #2 running for 15 seconds - 1 pod
    deployment #1 deployed 18 seconds ago
    1 info identified, use 'oc status --suggest' to see details.

$ oc expose service/vault-ppc64le
route.route.openshift.io/vault-ppc64le exposed
```

