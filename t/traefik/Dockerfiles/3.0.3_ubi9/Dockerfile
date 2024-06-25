FROM registry.access.redhat.com/ubi9/ubi:9.3
# Install required packages

RUN yum -y install wget tar

ARG PACKAGE_VERSION=v3.0.3
# Download and extract Traefik
RUN wget https://github.com/containous/traefik/releases/download/$PACKAGE_VERSION/traefik_${PACKAGE_VERSION}_linux_ppc64le.tar.gz && \
    tar -xzvf traefik_${PACKAGE_VERSION}_linux_ppc64le.tar.gz && \
    rm -f traefik_${PACKAGE_VERSION}_linux_ppc64le.tar.gz

# Copy configuration file to the image
COPY traefik.toml /etc/traefik/

# Set the working directory

# Expose the port
EXPOSE 80

# Set the entrypoint to start Traefik
ENTRYPOINT ["./traefik"]

# Pass the configuration file as an argument
CMD ["--configFile=/etc/traefik/traefik.toml"]

