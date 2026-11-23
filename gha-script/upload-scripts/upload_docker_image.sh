#!/bin/bash -e

# currency-build-v2.yaml supplies GHA_CURRENCY_SERVICE_ID_API_KEY_V2 -> push to staging.
# currency-build.yaml supplies GHA_CURRENCY_SERVICE_ID_API_KEY       -> push to production.
if [ -n "${GHA_CURRENCY_SERVICE_ID_API_KEY_V2:-}" ]; then
    API_KEY="${GHA_CURRENCY_SERVICE_ID_API_KEY_V2}"
    ICR_NAMESPACE="ose4power-packages-stag"
else
    API_KEY="${GHA_CURRENCY_SERVICE_ID_API_KEY:-}"
    ICR_NAMESPACE="ose4power-packages-production"
fi

echo "$API_KEY" | docker login -u iamapikey --password-stdin icr.io

if [ $? -ne 0 ]; then
    echo "Docker login failed. Exiting script."
    exit 1
fi
package_name=$(echo $PACKAGE_NAME | tr '[:upper:]' '[:lower:]')
echo "Pushing to icr.io/${ICR_NAMESPACE}/$package_name-ppc64le:$VERSION"
docker tag $IMAGE_NAME icr.io/${ICR_NAMESPACE}/$package_name-ppc64le:$VERSION
docker push icr.io/${ICR_NAMESPACE}/$package_name-ppc64le:$VERSION
if [ $? -ne 0 ]; then
    echo "Docker push failed. Exiting script."
    exit 1
fi
