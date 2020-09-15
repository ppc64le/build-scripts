FROM rhel_ppc64le:7.4
MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

RUN yum -y update && \
    yum install -y wget && \
    wget https://dl.fedoraproject.org/pub/epel/7/ppc64le/Packages/e/epel-release-7-11.noarch.rpm && \
    rpm -ivh epel-release-7-11.noarch.rpm && \
    yum install -y ansible && \
    echo '[local]\nlocalhost\n' > /etc/ansible/hosts && \
    yum remove wget

CMD [ "/bin/bash" ]
