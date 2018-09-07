# Licensed Materials - Property of IBM
# 5737-E67
# @ Copyright IBM Corporation 2016, 2018. All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.

FROM ppc64le/centos:7
MAINTAINER lysannef@us.ibm.com
LABEL org.label-schema.vendor="IBM" \
      org.label-schema.name="$IMAGE_NAME" \
      org.label-schema.description="$IMAGE_DESCRIPTION" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url=$VCS_URL \
      org.label-schema.license="Licensed Materials - Property of IBM" \
      org.label-schema.schema-version="1.0"

RUN adduser -s /bin/bash elasticsearch \
      &&  mkdir /es-plugin && chmod +r -R /es-plugin \
      &&  set -x \
      && yum update -y \
      && yum clean all \
      && yum install -y maven git \
      && git clone https://github.com/floragunncom/search-guard.git \
      && cd search-guard \
      && git checkout ves-5.5.1-16 \
      && sed -i '/os.detected.classifier/d' pom.xml \
      && mvn compile \
      && mvn package \
      && mv target/releases/search-guard-5-5.5.1-16.zip /es-plugin/ \
      && yum remove git maven -y

CMD ["/bin/bash"]
