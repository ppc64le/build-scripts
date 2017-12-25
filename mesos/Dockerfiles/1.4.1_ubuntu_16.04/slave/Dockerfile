FROM ppc64le/mesos:1.4.1
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

ENV MESOS_SYSTEMD_ENABLE_SUPPORT false
ENV PATH $PATH:/usr/local/mesos/sbin
ENTRYPOINT ["mesos-slave"]

