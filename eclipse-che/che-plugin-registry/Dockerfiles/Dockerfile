FROM mikefarah/yq as builder
RUN apk add --no-cache bash
COPY .htaccess README.md ./scripts/*.sh /build/
COPY /plugins /build/plugins
COPY /v2 /build/v2
COPY /v3 /build/v3
WORKDIR /build/
RUN ./check_plugins_location_v1.sh
RUN ./check_plugins_location_v2.sh v2
RUN ./check_plugins_location_v2.sh v3
RUN ./check_plugins_images.sh
RUN ./set_plugin_dates.sh
RUN ./check_plugins_viewer_mandatory_fields_v1.sh
RUN ./check_plugins_viewer_mandatory_fields_v2.sh
RUN ./check_plugins_viewer_mandatory_fields_v3.sh
RUN ./ensure_latest_exists.sh
RUN ./index.sh > /build/plugins/index.json
RUN ./index_v2.sh v2 > /build/v2/plugins/index.json
RUN ./index_v2.sh v3 > /build/v3/plugins/index.json

FROM registry.centos.org/centos/httpd-24-centos7
RUN mkdir /var/www/html/plugins
COPY --from=builder /build/ /var/www/html/
USER 0
RUN chmod -R g+rwX /var/www/html/plugins && \
    chmod -R g+rwX /var/www/html/v2/plugins && \
    chmod -R g+rwX /var/www/html/v3/plugins
