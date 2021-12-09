Building Redis

This Dockerfile is required, /opt/bitnami/redis/etc/redis-default.conf, which is not available, hence downloaded the same file from https://downloads.bitnami.com/files/stacksmith/redis-6.2.6-1-linux-amd64-debian-10.tar.gz and added it to prebuildfs/opt/bitnami/redis/etc/redis-default.conf

docker build -t redis-bitnami .
docker run -itd -p 6379:6379 --name redisbitnami redis-bitnami:latest

Deploying Redis on Openshift

$ oc new-project redis-bitnami

Now using project "redis-bitnami" on server "https://api-<cluster-address>:6443".

You can add applications to this project with the 'new-app' command. For example, try:

    oc new-app ruby~https://github.com/sclorg/ruby-ex.git

to build a new example application in Ruby. Or use kubectl to deploy a simple Kubernetes application:

    kubectl create deployment hello-node --image=gcr.io/hello-minikube-zero-install/hello-node


$ oc adm policy add-scc-to-user anyuid -z default

--> clusterrole.rbac.authorization.k8s.io/system:openshift:scc:anyuid added: "default"

$ oc new-app redis-bitnami:latest

--> Found image ed7693e (5 hours old) in image stream "redis-bitnami/redis-bitnami" under tag "latest" for "redis-bitnami:latest"

    Red Hat Universal Base Image 8 Minimal
    --------------------------------------
    The Universal Base Image Minimal is a stripped down image that uses microdnf as a package manager. This base image is freely redistributable, but Red Hat only supports Red Hat technologies through subscriptions for Red Hat products. This image is maintained by Red Hat and updated regularly.

    Tags: minimal rhel8


--> Creating resources ...
    deployment.apps "redis-bitnami" created
    service "redis-bitnami" created
--> Success
    Application is not exposed. You can expose services to the outside world by executing one or more of the commands below:
     'oc expose svc/redis-bitnami'
    Run 'oc status' to view your app.

	
$ oc expose svc/redis-bitnami

route.route.openshift.io/redis-bitnami exposed
