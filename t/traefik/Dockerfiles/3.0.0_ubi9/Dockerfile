FROM registry.access.redhat.com/ubi9/ubi:9.3

RUN yum -y install wget tar

# Download and extract Traefik
RUN wget https://github.com/containous/traefik/releases/download/v3.0.0/traefik_v3.0.0_linux_ppc64le.tar.gz && \
    tar -xzvf traefik_v3.0.0_linux_ppc64le.tar.gz && \
    rm -f traefik_v3.0.0_linux_ppc64le.tar.gz

# Copy configuration file to the image
COPY traefik.toml /etc/traefik/

# Expose the port
EXPOSE 80

# Set the entrypoint to start Traefik
ENTRYPOINT ["./traefik"]

# Pass the configuration file as an argument
CMD ["--configFile=/etc/traefik/traefik.toml"]
