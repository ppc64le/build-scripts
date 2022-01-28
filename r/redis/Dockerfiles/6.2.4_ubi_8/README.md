# Building Redis
```

docker build -t redis .
docker run -d -p 6379:6379 --name redis-demo redis:latest

```

# Deploying Redis on Openshift
```
$ oc new-project redis
--> Now using project "redis" on server "https://api-<cluster-address>:6443".
	You can add applications to this project with the 'new-app' command. For example, try:
    oc new-app rails-postgresql-example
	to build a new example application in Ruby. Or use kubectl to deploy a simple Kubernetes application:
    kubectl create deployment hello-node --image=k8s.gcr.io/serve_hostname

$ oc adm policy add-scc-to-user anyuid -z default
--> clusterrole.rbac.authorization.k8s.io/system:openshift:scc:anyuid added: "default"

$ oc new-app ibmcom/redis-ppc64le:latest
--> Found container image dbc74cf (25 minutes old) from quay.io for "ibmcom/redis-ppc64le:latest"
    Red Hat Universal Base Image 8
    ------------------------------
    The Universal Base Image is designed and engineered to be the base layer for all of your containerized applications, middleware and utilities. This base image is freely redistributable, but Red Hat only supports Red Hat technologies through subscriptions for Red Hat products. This image is maintained by Red Hat and updated regularly.
    Tags: base rhel8
    * An image stream tag will be created as "redis-ppc64le:latest" that will track this image
--> Creating resources ...
    imagestream.image.openshift.io "redis-ppc64le" created
    deployment.apps "redis-ppc64le" created
    service "redis-ppc64le" created
--> Success
    Application is not exposed. You can expose services to the outside world by executing one or more of the commands below:
     'oc expose service/redis'
    Run 'oc status' to view your app.
	
$ oc expose service/redis-ppc64le
--> route.route.openshift.io/redis-ppc64le exposed
```

# Quick test using a new interactive session and the redis cli
Connect to docker container or Openshift pod and execute below commands:
```
sh-4.2# redis-cli

127.0.0.1:6379> ping
PONG
127.0.0.1:6379> get name
(nil)
127.0.0.1:6379> set name "foobar"
OK
127.0.0.1:6379> get name
"foobar"
```
