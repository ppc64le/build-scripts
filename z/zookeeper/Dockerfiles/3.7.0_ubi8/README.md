# Building Zookeeper
```
docker build -t zookeeper .
docker run --name zookeeper -it -p 2181:2181 -p 2888:2888 -p 3888:3888 zookeeper:latest
```
# Deploying Zookeeper on Openshift
```
$ oc new-project zookeeper

--> Now using project "zookeeper" on server "https://api-<cluster-address>:6443".
    You can add applications to this project with the 'new-app' command. For example, try:
    oc new-app rails-postgresql-example
    to build a new example application in Ruby. Or use kubectl to deploy a simple Kubernetes application:
    kubectl create deployment hello-node --image=k8s.gcr.io/serve_hostname

$ oc adm policy add-scc-to-user anyuid -z default

clusterrole.rbac.authorization.k8s.io/system:openshift:scc:anyuid added: "default"

$ oc adm policy add-scc-to-user anyuid system:serviceaccount:zookeeper:default

clusterrole.rbac.authorization.k8s.io/system:openshift:scc:anyuid added: "default"

$ oc new-app ibmcom/zookeeper-ppc64le:latest
--> Found container image a7ad145 (9 days old) from Docker Hub for "ibmcom/zookeeper-ppc64le:latest"

    Red Hat Universal Base Image 8
    ------------------------------
    The Universal Base Image is designed and engineered to be the base layer for all of your containerized applications, middleware and utilities. This base image is freely redistributable, but Red Hat only supports Red Hat technologies through subscriptions for Red Hat products. This image is maintained by Red Hat and updated regularly.

    Tags: base rhel8

    * An image stream tag will be created as "zookeeper-ppc64le:latest" that will track this image

--> Creating resources ...
    imagestream.image.openshift.io "zookeeper-ppc64le" created
    deployment.apps "zookeeper-ppc64le" created
    service "zookeeper-ppc64le" created
--> Success
    Application is not exposed. You can expose services to the outside world by executing one or more of the commands below:
     'oc expose svc/zookeeper-ppc64le'
    Run 'oc status' to view your app.


$ oc expose svc/zookeeper-ppc64le

route.route.openshift.io/zookeeper-ppc64le exposed
```

