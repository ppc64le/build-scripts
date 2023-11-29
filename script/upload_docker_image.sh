#!/bin/bash -xe

echo "$icr_service_id_api_key" | docker login -u iamapikey --password-stdin icr.io
package_name=$(echo $PACKAGE_NAME | tr '[:upper:]' '[:lower:]')
docker tag $IMAGE_NAME icr.io/currency-images/$package_name-ppc64le:$VERSION
docker push icr.io/currency-images/$package_name-ppc64le:$VERSION
