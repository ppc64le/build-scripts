# Building Consul
```
docker build -t consul .
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

$ oc new-app ibmcom/consul-ppc64le:latest
--> Found container image 41cd3e9 (About an hour old) from docker.io for "ibmcom/consul-ppc64le:latest"

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
```
