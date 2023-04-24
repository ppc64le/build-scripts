FROM registry.access.redhat.com/ubi8/ubi:8.7
# Install required packages
RUN yum -y update && \
    yum -y install wget tar && \
    yum clean all

# Download and extract Traefik
RUN wget https://github.com/containous/traefik/releases/download/v2.9.10/traefik_v2.9.10_linux_ppc64le.tar.gz && \
    tar -xzvf traefik_v2.9.10_linux_ppc64le.tar.gz && \
    rm -f traefik_v2.9.10_linux_ppc64le.tar.gz

# Copy configuration file to the image
COPY traefik.toml /etc/traefik/

# Set the working directory

# Expose the port
EXPOSE 80

# Set the entrypoint to start Traefik
ENTRYPOINT ["./traefik"]

# Pass the configuration file as an argument
CMD ["--configFile=/etc/traefik/traefik.toml"]
