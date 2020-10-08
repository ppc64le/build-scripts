# KUI build and image creation

The build and image creation for KUI are coupled within the build framework.
The build-script takes care of building KUI and then the docker image too.
After successful execution, an image "kuishell/kui:latest" should be created.

# Image Usage

Assuming that you have k8s cluster running on the system, here is how you can
create a KUI proxy container:

```
docker run --rm -v /root/.kube:/root/.kube -p 9080:80 -e DEBUG=* kuishell/kui
```

If you are using minikube, here's how you can create the container:

```
docker run --rm -v /root/.kube:/root/.kube -v /root/.minikube:/root/.minikube -p 9080:80 -e DEBUG=* kuishell/kui
```

Note that the -e DEBUG=* flag to docker run is not necessary. It will emit lots
of debug output, but you can use it to see the kuiproxy messages; this will help
confirm that things are flowing.

Once the container starts, goto http://<HOST_IP>:9080 in a browser (preferably
chrome or firefox). KUI console will then be loaded in your browser window and
you can start executing various commands, like *pwd, ls, kubectl get nodes,
kubectl krew search*, etc.
```
