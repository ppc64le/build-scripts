# Build and test

The build installs helm as a depedendency in custom location and also sets the home directory for it. So, it does not matter whether helm is installed on the build machine already. Also, note that the e2e test execution sets up a kind cluster. So, it is necessary that you do not have minikube or any other k8s cluster running locally already.

# Manual validation

For manual validation of the image and CLI, the system needs helm and k8s cluster (minikube has been validated).

## Validating the image

Install helm3 with the following steps and add crossplane repo:

```
wget https://get.helm.sh/helm-v3.4.2-linux-ppc64le.tar.gz
tar -zxvf helm-v3.4.2-linux-ppc64le.tar.gz
rm -rf helm-v3.4.2-linux-ppc64le.tar.gz
cp linux-ppc64le/helm /usr/local/bin

kubectl create namespace crossplane-system
helm repo add crossplane-master https://charts.crossplane.io/master/
helm repo update
```

You should be able to find crossplane chart in the serahc results:

```
# helm search repo crossplane-master
NAME                                            CHART VERSION   APP VERSION     DESCRIPTION
crossplane-master/crossplane                    1.0.0           1.0.0           Crossplane is an open source Kubernetes add-on ...
crossplane-master/crossplane-controllers        0.12.0          0.12.0          Crossplane - Managed Cloud Resources Operator
crossplane-master/crossplane-types              0.12.0          0.12.0          Crossplane - Managed Cloud Resources Operator
crossplane-master/oam-kubernetes-runtime        0.3.0           0.3.0           A Helm chart for OAM Kubernetes Resources Contr...
```

Now, try installing the operator via helm using the local image as:

``` 
# docker tag build-fb4cbea9/crossplane-ppc64le:latest crossplane/crossplane:v1.0.0
# helm install crossplane --namespace crossplane-system crossplane-master/crossplane --version 1.0.0 --set image.pullPolicy=IfNotPresent
NAME: crossplane
LAST DEPLOYED: Wed Jan 27 14:05:38 2021
NAMESPACE: crossplane-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Release: crossplane

Chart Name: crossplane
Chart Description: Crossplane is an open source Kubernetes add-on that extends any cluster with the ability to provision and manage cloud infrastructure, services, and applications using kubectl, GitOps, or any tool that works with the Kubernetes API.
Chart Version: 1.0.0
Chart Application Version: 1.0.0

Kube Version: v1.19.0
```

You should be able to see the pods and deployments now:

```
# kubectl get all -n crossplane-system
NAME                                           READY   STATUS    RESTARTS   AGE
pod/crossplane-55849dbc57-svgh7                1/1     Running   0          71s
pod/crossplane-rbac-manager-7cb47b4f48-r2tnw   1/1     Running   0          71s

NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/crossplane                1/1     1            1           72s
deployment.apps/crossplane-rbac-manager   1/1     1            1           72s

NAME                                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/crossplane-55849dbc57                1         1         1       71s
replicaset.apps/crossplane-rbac-manager-7cb47b4f48   1         1         1       71s

# kubectl logs pod/crossplane-55849dbc57-svgh7 -n crossplane-system
I0127 19:05:48.703370       1 leaderelection.go:242] attempting to acquire leader lease  crossplane-system/crossplane-leader-election-core...
I0127 19:05:48.711133       1 leaderelection.go:252] successfully acquired lease crossplane-system/crossplane-leader-election-core

# kubectl logs crossplane-rbac-manager-7cb47b4f48-r2tnw -n crossplane-system
I0127 19:05:48.863619       1 leaderelection.go:242] attempting to acquire leader lease  crossplane-system/crossplane-leader-election-rbac...
I0127 19:05:48.868525       1 leaderelection.go:252] successfully acquired lease crossplane-system/crossplane-leader-election-rbac
```

## Validating CLI binary

Looking at the CLI installation script, it can be seen that it simply downloads crank binary and copies over as a sibbling of kubectl.
(https://github.com/crossplane/crossplane/blob/v1.0.0/install.sh#L54)

So, try doing something similar with the local built binary:

```
# cp ./_output/bin/linux_ppc64le/crank $(dirname $(which kubectl))/kubectl-crossplane
# kubectl crossplane --help
Usage: kubectl crossplane <command>

A command line tool for interacting with Crossplane.

Flags:
  -h, --help       Show context-sensitive help.
  -v, --version    Print version and quit.

Commands:
  build configuration
    Build a Configuration package.

  build provider
    Build a Provider package.

  install configuration <package> [<name>]
    Install a Configuration package.

  install provider <package> [<name>]
    Install a Provider package.

  push configuration <tag>
    Push a Configuration package.

  push provider <tag>
    Push a Provider package.

Run "kubectl crossplane <command> --help" for more information on a command.
```

# References

https://crossplane.io/docs/v0.12/getting-started/install-configure.html
https://raw.githubusercontent.com/crossplane/crossplane/release-1.0/install.sh
