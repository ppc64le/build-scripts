# Operator Validation

## Prerequisites

1. You need to have a k8s cluster setup.
2. You need to have an IBM Cloud account with permissions to create/edit/delete/.. an instance of at least one of the service which is bindable.
We're using `language-translator` service here as it is also used in tests.

## Steps to run operator pod on minikube (k8s)

1. Install IBM Cloud CLI as:

```
wget https://clis.cloud.ibm.com/download/bluemix-cli/1.5.1/ppc64le/archive
tar -xzf archive
rm -rf archive
export PATH=`pwd`/IBM_Cloud_CLI/:$PATH
export IBMCLOUD_API_KEY=<API_KEY>
```

2. Now, login to your IBM Cloud account and set the resource group with the following commands:

```
ibmcloud login --apikey <API_KEY>
ibmcloud target -g Default -r us-south
```

3. Now, to run the operator pod, execute the following:

```
cd $GOPATH/src/github.com/IBM/cloud-operators
rm -rf out/ibmcloud-operator.package.yaml
rm -rf out/ibmcloud_operator.v1.0.7.clusterserviceversion.yaml
./hack/configure-operator.sh -v 1.0.7 install
```

You may get failures in applying 3 yaml files due to missing namespace.
This is a known issue and is logged: https://github.com/IBM/cloud-operators/issues/248

So, you'll need to manually apply those 3 yaml files as:

```
kubectl apply -f out/apps_v1_deployment_ibmcloud-operator-controller-manager.yaml
kubectl apply -f out/rbac.authorization.k8s.io_v1_role_ibmcloud-operator-leader-election-role.yaml
kubectl apply -f out/rbac.authorization.k8s.io_v1_rolebinding_ibmcloud-operator-leader-election-rolebinding.yaml
```

4. You should see the operator pod running as:

```
# kubectl get pods -A
NAMESPACE                  NAME                                                   READY   STATUS    RESTARTS   AGE
ibmcloud-operator-system   ibmcloud-operator-controller-manager-6757cfc84-7hcrj   2/2     Running   0          17s
...
```

## Steps to validate the functionality on minikube (k8s)

In order to validate the operator functionality, we'll create and bind an IBM cloud service (language-translator, in this case).

1. Check the service availability and corresponding plans as:

```
# ibmcloud catalog service-marketplace | grep language-translator
f1faf010-4107-4877-a571-fc9c8763c3dd                                 language-translator                                        IBM Watson                              apidocs_enabled,eu_access,hipaa,ibm_created,ibm_dedicated_public,ibm_release,lite,rc_compatible,watson

# ibmcloud catalog service language-translator | grep plan
                   advanced                  plan         1a4c6903-7b12-4632-bd01-69cfc56ebd5b
                   lite                      plan         2d40e0f9-3c12-4d2e-9869-fd700836044f
                   premium                   plan         887dfc04-ac0a-11e6-938a-54ee7514918e
                   standard                  plan         2970b11b-c5c8-4503-a5c6-c05a0e89590e
```

2. Create a service yaml (say, myservice.yaml) with the expected plan and service as:

```
apiVersion: ibmcloud.ibm.com/v1
kind: Service
metadata:
    name: myservice
spec:
    plan: lite
    serviceClass: language-translator
```

3. Apply the yaml to create the service instance and validate using ibmclou cli as:

```
# kubectl apply -f myservice.yaml
service.ibmcloud.ibm.com/myservice created

# kubectl get services.ibmcloud
NAME        STATUS   AGE
myservice   Online   4s

# ibmcloud resource service-instances | grep myservice
myservice                 us-south   active   service_instance
```

You can also check the resource list on your cloud console to see the service instance being created there.

4. Now, to bind this service, create yaml (say mybinding.yaml) and check the bind status as:

```
apiVersion: ibmcloud.ibm.com/v1
kind: Binding
metadata:
    name: mybinding
spec:
    serviceName: myservice
```

```
# kubectl apply -f mybinding.yaml
binding.ibmcloud.ibm.com/mybinding created

# kubectl get bindings.ibmcloud
NAME        STATUS   AGE
mybinding   Online   13s

# kubectl get secrets
NAME                       TYPE                                  DATA   AGE
...
mybinding                  Opaque                                6      16s
```

5. Finally, to delete the binding, service and delete the operator deployment run

```
# kubectl delete -f  mybinding.yaml
binding.ibmcloud.ibm.com "mybinding" deleted

# kubectl delete -f myservice.yaml
service.ibmcloud.ibm.com "myservice" deleted

# ./hack/configure-operator.sh remove
...
```

# References

https://github.com/IBM/cloud-operators#prerequisites
https://github.com/IBM/cloud-operators#setting-up-the-operator
https://github.com/IBM/cloud-operators#using-the-ibm-cloud-operator
https://github.com/IBM/cloud-operators/blob/master/docs/user-guide.md
