FROM centos/s2i-core-centos7

# Apache HTTP Server image.
#
# Volumes:
#  * /var/www - Datastore for httpd
#  * /var/log/httpd24 - Storage for logs when $HTTPD_LOG_TO_VOLUME is set
# Environment:
#  * $HTTPD_LOG_TO_VOLUME (optional) - When set, httpd will log into /var/log/httpd24

ENV HTTPD_VERSION=2.4

ENV SUMMARY="Platform for running Apache httpd $HTTPD_VERSION or building httpd-based application" \
    DESCRIPTION="Apache httpd $HTTPD_VERSION available as container, is a powerful, efficient, \
and extensible web server. Apache supports a variety of features, many implemented as compiled modules \
which extend the core functionality. \
These can range from server-side programming language support to authentication schemes. \
Virtual hosting allows one Apache installation to serve many different Web sites."

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="Apache httpd $HTTPD_VERSION" \
      io.openshift.expose-services="8080:http,8443:https" \
      io.openshift.tags="builder,httpd,httpd24" \
      name="centos/httpd-24-centos7" \
      version="$HTTPD_VERSION" \
      com.redhat.component="httpd24-container" \
      usage="s2i build https://github.com/sclorg/httpd-container.git --context-dir=examples/sample-test-app/ centos/httpd-24-centos7 sample-server" \
      maintainer="SoftwareCollections.org <sclorg@redhat.com>"

EXPOSE 8080
EXPOSE 8443


RUN yum install -y yum-utils && \
    yum install -y epel-release && \
    INSTALL_PKGS="gettext hostname nss_wrapper bind-utils httpd.ppc64le mod_ssl.ppc64le mod_auth_mellon.ppc64le" && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all

ENV HTTPD_CONTAINER_SCRIPTS_PATH=/usr/share/container-scripts/httpd/ \
    HTTPD_APP_ROOT=${APP_ROOT} \
    HTTPD_CONFIGURATION_PATH=${APP_ROOT}/etc/httpd.d \
    HTTPD_MAIN_CONF_PATH=/etc/httpd/conf \
    HTTPD_MAIN_CONF_MODULES_D_PATH=/etc/httpd/conf.modules.d \
    HTTPD_MAIN_CONF_D_PATH=/etc/httpd/conf.d \
    HTTPD_VAR_RUN=/var/run/httpd \
    HTTPD_DATA_PATH=/var/www \
    HTTPD_LOG_PATH=/var/log/httpd


# When bash is started non-interactively, to run a shell script, for example it
# looks for this variable and source the content of this file. This will enable
# the SCL for all scripts without need to do 'scl enable'.
ENV BASH_ENV=${HTTPD_APP_ROOT}/scl_enable \
    ENV=${HTTPD_APP_ROOT}/scl_enable \
    PROMPT_COMMAND=". ${HTTPD_APP_ROOT}/scl_enable"

COPY ./s2i/bin/ $STI_SCRIPTS_PATH
COPY ./root /

# Reset permissions of filesystem to default values
RUN /usr/libexec/httpd-prepare && rpm-file-permissions

USER 1001
CMD ["/usr/bin/run-httpd"]

