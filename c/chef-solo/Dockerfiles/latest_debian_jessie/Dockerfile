# Dockerfile for chef-solo
FROM ppc64le/openjdk:openjdk-9-jdk

# Dockerfile owner details
MAINTAINER "Amit Ghatwal <ghatwala@ibm.com>"

# Download chef binary/installer and install
RUN wget https://packages.chef.io/files/stable/chef/13.2.20/ubuntu/14.04/chef_13.2.20-1_ppc64el.deb && dpkg -i chef_13.2.20-1_ppc64el.deb && rm -rf chef_13.2.20-1_ppc64el.deb

# start chef shell
CMD ["chef-shell"]
