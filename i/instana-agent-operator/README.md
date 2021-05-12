# Operator Validation

To validate the operator image on a kubernetes cluster and confirm the functionality on instana dashboard, instana/agent image needs to be built.

## Build instana agent image

For platforms other than ppc64le, instana agent in RPM form are available. For ppc64le, we need to rely on the tarball.

To build the agent image using the downloaded tarball, please use the following steps:

1. Create a dockerfile in the same directory as the tarball and add the following lines

```
FROM registry.access.redhat.com/ubi8/ubi:8.2

COPY instana-agent-linux-ppcle-64bit.tar.gz /root/

RUN yum install -y java-11-openjdk-devel \
    && cd /root/ \
    && tar xzf instana-agent-linux-ppcle-64bit.tar.gz \
    && rm -rf instana-agent-linux-ppcle-64bit.tar.gz

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk \
    INSTANA_AGENT_MODE="APM" \
    INSTANA_AGENT_KEY="uBp4GXpZQpKrHxMXNcvInQ"

CMD ["/root/instana-agent/bin/karaf", "daemon"]
```
2. Now build the image as:

```
docker build -t instana/agent:latest .
```

## Validation on minikube

In order to validate your operator on a minikube cluster, you simply need to use the following steps:

1. Deploy the operator pod in the cluster

```
cd instana-agent-operator
kubectl apply -f ./olm/operator-resources/instana-agent-operator.yaml
```

2. After the operator pod is up and running, execute the following command to insert the agent custom resource

```
kubectl apply -f deploy/instana-agent.customresource.yaml
```

The operator will bring an agent pod up and you should be able to see your cluster details in the instana dashboard.

## Validation on kind

1. To setup a kind cluster on ppc64le, execute the folowing commands:

```
wget -O kind https://github.com/kubernetes-sigs/kind/releases/download/v0.7.0/kind-linux-ppc64le
chmod +x kind
export PATH=`pwd`:$PATH
```

2. From inside the instana-agent-operator source directory, execute:

```
kind --config e2e-testing/with-kind/kind-config-linux.yaml create cluster --image kbasheer/kindest-node:v1.18.0
```

3. Wait for all (1 master, 2 worker) the nodes to be in `Ready` state and then load the operator and agent images as:

```
kind load docker-image instana/instana-agent-operator
kind load docker-image instana/agent
```

4. Follow the steps #1 and #2 from minikube based validation above.

The difference here is that there will be two agent pods, one on each worker node.

## Deleting the deployment

From inside the instana-agent-operator source directory, execute:

```
kubectl delete -f deploy/instana-agent.customresource.yaml
kubectl delete -f ./olm/operator-resources/instana-agent-operator.yaml
```

# References

https://github.com/instana/instana-agent-operator/blob/main/docs/testing-with-kind.md#testing-the-instana-agent-operator-with-kind
