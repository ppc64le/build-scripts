# Building Consul
```
docker build --build-arg CONSUL_VERSION=v1.9.4 -t consul .
docker run -it consul:latest
```

# Deploying Consul on Openshift
```
$ oc new-project consul
--> Now using project "consul" on server "https://api-<cluster-address>:6443".
    You can add applications to this project with the 'new-app' command. For example, try:
    oc new-app rails-postgresql-example
    to build a new example application in Ruby. Or use kubectl to deploy a simple Kubernetes application:
    kubectl create deployment hello-node --image=k8s.gcr.io/serve_hostname

$ oc adm policy add-scc-to-user anyuid -z default
--> clusterrole.rbac.authorization.k8s.io/system:openshift:scc:anyuid added: "default"

# Get the default route host
export HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')

#Login to podman as kubeadmin
podman login -u kubeadmin -p $(oc whoami -t) --tls-verify=false $HOST

#Build Consul image from Dockerfile
podman build --build-arg CONSUL_VERSION=v1.9.4 -t $HOST/local-images/consul:latest .

#Push the image as local image so that any project/namespace get the access.
podman push $HOST/openshift/consul:latest --tls-verify=false

$ oc describe is consul -n openshift

$ oc new-app image-registry.openshift-image-registry.svc:5000/openshift/consul
--> 
    Red Hat Universal Base Image 8
    ------------------------------
    The Universal Base Image is designed and engineered to be the base layer for all of your containerized applications, middleware and utilities. This base image is freely redistributable, but Red Hat only supports Red Hat technologies through subscriptions for Red Hat products. This image is maintained by Red Hat and updated regularly.

    Tags: base rhel8

    * An image stream tag will be created as "consul:latest" that will track this image

--> Creating resources ...
    imagestream.image.openshift.io "consul" created
    deployment.apps "consul" created
    service "consul" created
--> Success
    Application is not exposed. You can expose services to the outside world by executing one or more of the commands below:
     'oc expose service/consul'
    Run 'oc status' to view your app.

$ oc create route edge consule --service=consul --port=8500-tcp --insecure-policy=Redirect
route.route.openshift.io/consule created

// Access the Consul UI at route URL created in previous step
// Get URL from $ oc get all
```
