FROM 	registry.access.redhat.com/ubi7/ubi:latest

RUN 	yum -y update 
RUN	yum install -y unzip wget openssh iptables git xz xz-devel xz-libs java-1.8.0-openjdk-headless 
RUN	wget https://download.docker.com/linux/static/stable/ppc64le/docker-18.06.3-ce.tgz  
RUN	tar xzvf docker-18.06.3-ce.tgz && cp docker/* /usr/bin/ 

EXPOSE 22
ENV JAVA_HOME /usr/lib/jvm/jre-1.8.0-openjdk

# Install the magic wrapper.
ADD ./wrapdocker /usr/local/bin/wrapdocker
RUN chmod +x /usr/local/bin/wrapdocker

# Define additional metadata for our image.
VOLUME /var/lib/docker
CMD ["wrapdocker"]
