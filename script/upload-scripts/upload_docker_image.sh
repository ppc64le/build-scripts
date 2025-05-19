#!/bin/bash -e

echo "$travis_currency_service_id_api_key" | docker login -u iamapikey --password-stdin icr.io
if [ $? -ne 0 ]; then
    echo "Docker login failed. Exiting script."
    exit 1
fi
package_name=$(echo $PACKAGE_NAME | tr '[:upper:]' '[:lower:]')
docker tag $IMAGE_NAME icr.io/ose4power-packages/$package_name-ppc64le:$VERSION
docker push icr.io/ose4power-packages/$package_name-ppc64le:$VERSION
if [ $? -ne 0 ]; then
    echo "Docker push failed. Exiting script."
    exit 1
fi

