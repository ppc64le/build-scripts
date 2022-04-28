Building Vault

Docker build command: docker build --build-arg VAULT_VERSION=v1.9.1 -t vault .

Docker run command: docker run -d --name=dev-vault vault

Deploying vault on Openshift

`$ oc new-project vault
--> Now using project "vault" on server "https://api-<cluster-address>:6443".
    You can add applications to this project with the 'new-app' command. For example, try:
    oc new-app rails-postgresql-example
    to build a new example application in Ruby. Or use kubectl to deploy a simple Kubernetes application:
    kubectl create deployment hello-node --image=k8s.gcr.io/serve_hostname

$ oc adm policy add-scc-to-user anyuid -z default
--> clusterrole.rbac.authorization.k8s.io/system:openshift:scc:anyuid added: "default"

#Login to podman as kubeadmin
podman login -u kubeadmin -p $(oc whoami -t) --tls-verify=false $HOST

#Build Vault image from Dockerfile
podman build --build-arg VAULT_VERSION=v1.9.1 -t $HOST/local-images/vault:latest .

#Push the image as local image so that any project/namespace get the access.
podman push $HOST/openshift/vault:latest --tls-verify=false

$ oc describe is vault -n openshift

$ oc new-app image-registry.openshift-image-registry.svc:5000/openshift/vault -e SKIP_CHOWN=true -e SKIP_SETCAP=true
--> Red Hat Universal Base Image 8
    ------------------------------
    The Universal Base Image is designed and engineered to be the base layer for all of your containerized applications, middleware and utilities. This base image is freely redistributable, but Red Hat only supports Red Hat technologies through subscriptions for Red Hat products. This image is maintained by Red Hat and updated regularly.
    Tags: base rhel8
    * An image stream tag will be created as "vault:latest" that will track this image
--> Creating resources ...
    imagestream.image.openshift.io "vault" created
    deployment.apps "vault" created
    service "vault" created
--> Success
    Application is not exposed. You can expose services to the outside world by executing one or more of the commands below:
     'oc expose service/vault'
    Run 'oc status' to view your app.

$ oc status
--> In project vault on server https://api-<cluster-address>:6443
    svc/vault - 172.30.227.208:8200
    deployment/vault-ppc64le deploys istag/vault:latest
    deployment #2 running for 15 seconds - 1 pod
    deployment #1 deployed 18 seconds ago
    1 info identified, use 'oc status --suggest' to see details.

$ oc expose service/vault-ppc64le
route.route.openshift.io/vault exposed`
