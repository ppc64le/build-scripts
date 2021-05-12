The upstream document is [here](https://github.com/strimzi/strimzi-kafka-operator/blob/master/development-docs/DEV_GUIDE.md#building-container-images-for-other-platforms-with-docker-buildx).

# 1. Build pre-requisites #

To build Strimzi from source you need an Kubernetes or OpenShift cluster available. Where Docker and Helm are pre-installed and running

You will also need access to several command line utilities which is installed from the build script itlsef



# 2. Run the Build script #

Note: Before running the Build script modify the Docker host, username and password in the script accordingly.

```
sh strimzi_ubuntu_18.04.sh
```

In case you do NOT need to run tests , above script can be modified by passing **make MVN_ARGS='-DskipTests -DskipIT' all** instead of **make all**
After a while it should be successful.

And we can filter the Build docker images for strimzi on power as below

**docker images | grep $HOST**


# 3. Deployment #

**CAUTION: This steps can be done only after completing above steps 1 & 2 **

Modify the **strimzi-cluster-operator-0.21.1.yaml** file with the respective images of operator, kafka, jmxtrans obtained from the above steps.

Create Namespace: 

```
kubectl create namespace myproject
```
Apply modified "strimzi-cluster-operator-0.21.1.yaml" file as below which includes ClusterRoles, ClusterRoleBindings  & CRD's

```
kubectl apply -f strimzi-cluster-operator-0.21.1.yaml -n myproject
```
Provision the Kafka Cluster using the Cluster CR file

```
kubectl apply -f https://strimzi.io/examples/latest/kafka/kafka-ephemeral-single.yaml -n myproject
```
We now need to wait while Kubernetes starts the required pods, services and so on

This completes the installation of Strimzi Apache Kafka cluster on K8s .