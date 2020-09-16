# Steps to run vault on Openshift.

Below steps to generate the `Vault` image from the build scripts.

```
#Login to the openshift with the Kube-admin instead of system admin.
oc login -u kubeadmin -p $(cat ~/openstack-upi/auth/kubeadmin-password)

# Create a new project
oc new-project vault-test

# Get the default route host
HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
echo $HOST

#Login to podman as kubeadmin
podman login -u kubeadm -p $(oc whoami -t) --tls-verify=false $HOST

# Download the Dockerfile and entrypoint script from the ppc64le/buildscripts to generate the Docker Image and push it to the Cluster as IS.
mkdir vault-docker && cd vault-docker
wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/v/vault/Dockerfiles/1.5.3-ubi8/Dockerfile
wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/v/vault/Dockerfiles/1.5.3-ubi8/docker-entrypoint.sh

#Build the Docker image
podman build -t $HOST/local-images/vault:1.5.3 .

#Push the image as local image so that any project/namespace get the access.
podman push $HOST/local-images/vault:1.5.3 --tls-verify=false

oc get is -A | grep vault
oc describe is vault -n local-images

IMAGE_NAME=$(oc describe is vault -n local-images | grep "Image Repository" | cut -d: -f2 | tr -d '\t')

# Update the policy/role to have access to image pull from local image to `vault-test` namespace.
oc policy add-role-to-group system:image-puller system:serviceaccounts --namespace=vault-test || true
```

Following are the steps to run `Vault` on Openshift

```
# A sample application, to check our docker image.
git clone https://github.com/raffaelespazzoli/credscontroller
cd credscontroller/

vi openshift/vault.yaml

#########################################################
# --- Steps to use the locally generated image ---
#########################################################
#Replace image: vault:0.11.1 with image: image-registry.openshift-image-registry.svc:5000/local-images/vault:1.5.3
# Add SKIP_CHOWN variable as true.


#########################################################
# --- Steps to use the ibmcom/vault-ppc64le image ---
#########################################################
#Replace image: vault:0.11.1 with image: ibmcom/vault-ppc64le:1.5.3-ubi8
# Add SKIP_CHOWN variable as true.

oc adm policy add-scc-to-user anyuid -z default

#Set the config for Vault.
oc create configmap vault-config --from-file=vault-config=./openshift/vault-config.json

# Start Vault app/deployment.
oc create -f ./openshift/vault.yaml

#Create a route for vault
oc create route passthrough vault --port=8200 --service=vault

#Unisntallation step for the vault app/deployment.
oc delete all --selector app=vault
```
