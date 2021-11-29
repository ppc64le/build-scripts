# Istio for ppc64le

This scripts allows to build istio package and docker images for ppc64le.
Prebuilt images are also available under [TODO].

## How to use?

```
build.sh <version to build>
```

### Customizing the build

Several environment variables can be used to customize the build :

* *WORK_DIR*: defines the path to the temporary working directory (default: temp directory created with mktemp)
* *HUB*: defines the registry and repository to be used for the images (default: [TODO])
* *BUILD_TOOLS*: defines if the build-tools images will be built (default: yes)
* *PUBLISH_TOOLS*: defines if the build-tools images will be published to the registry (default: no)
* *BUILD_PROXY*: defines if the envoy binary will be built (default: yes)
* *BUILD_IMAGES*: defines if the istio images will be built (default: yes)
* *PUBLISH_IMAGES*: defines if the istio images will be published to the registry (default: no)
* *BUILD_PACKAGES*: defines if the istio packages (*istio-[version].tar.gz* and *istioctl-[version].tar.gz*) will be built (default: yes)
* *ISTIO_REPO*: defines the URL to the istio source repo (default: https://github.com/istio/istio.git)
* *ISTIO_PROXY_REPO*: defines the URL to the proxy source repo (default: https://github.com/istio/proxy.git)
* *ISTIO_TOOLS_REPO*: defines the URL to the build-tools source repo (default: https://github.com/istio/tools.git)
* *DEBUG*: if set to yes, WORK_DIR won't be deleted once build is completed (defalult: no)

### Environment Requirements

Build can only be done on a Linux ppc64le environement, with Docker and make installed.

## How to install ?

### Install Istio Operator

Same as https://istio.io/latest/docs/setup/install/operator, but with `--hub` if you created a custom build.

```
$ istioctl operator init --hub=... --tag=1.12.0
```

### Install Istio

Same as https://istio.io/latest/docs/setup/install

```
$ kubectl create ns istio-system
$ kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane
spec:
  hub: <...>
  profile: demo
```

## Istio images

### [TODO]/proxyv2:{VERSION}[-distroless]

[TODO]/proxyv2/tags

### [TODO]/pilot:{VERSION}[-distroless]`

[TODO]/querycapistio/pilot

### [TODO]/operator:{VERSION}[-distroless]

[TODO]/operator/tags

### [TODO]/install-cni:{VERSION}[-distroless]

[TODO]/install-cni/tags