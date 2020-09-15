# Original credit: https://github.com/jpetazzo/dockvpn

# Smallest base image
FROM ppc64le/ubuntu:16.04

MAINTAINER Priya Seth <sethp@us.ibm.com>
# Needed by scripts
ENV OPENVPN /etc/openvpn
ENV EASYRSA /easy-rsa-3.0.1/easyrsa3/
ENV EASYRSA_PKI $OPENVPN/pki
ENV EASYRSA_VARS_FILE $OPENVPN/vars


RUN apt-get update -y  && \
    apt-get install -y openvpn pamtester openssl wget python iptables && \
    wget --no-check-certificate https://github.com/OpenVPN/easy-rsa/archive/3.0.1.tar.gz && \
    tar -xvzf 3.0.1.tar.gz && \
    ln -s /easy-rsa-3.0.1/easyrsa3/easyrsa /usr/local/bin && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* && \
    apt-get purge -y wget python && apt-get autoremove -y && rm -rf 3.0.1.tar.gz

WORKDIR /etc/openvpn

ADD ./bin /usr/local/bin
RUN chmod a+x /usr/local/bin/*

# Add support for OTP authentication using a PAM module
ADD ./otp/openvpn /etc/pam.d/

# Enable silent generation of PKI generation
RUN sed -i '/build-ca/c\easyrsa --batch build-ca nopass' /usr/local/bin/ovpn_initpki

# Internally uses port 1194/udp, remap using `docker run -p 443:1194/tcp`
EXPOSE 1194/udp
EXPOSE 443
EXPOSE 943

CMD ["bash"]
