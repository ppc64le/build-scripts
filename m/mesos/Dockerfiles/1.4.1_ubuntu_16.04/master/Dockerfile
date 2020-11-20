FROM ppc64le/mesos:1.4.1
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

ENV PATH $PATH:/usr/local/mesos/sbin
ENV MESOS_SYSTEMD_ENABLE_SUPPORT false
CMD ["--registry=in_memory"]
ENTRYPOINT ["mesos-master"]

