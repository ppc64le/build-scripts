FROM registry.access.redhat.com/ubi8/ubi:latest

ADD https://github.com/krallin/tini/releases/download/v0.18.0/tini-ppc64el /bin/tini
ADD utils/entrypoint.sh /bin/entrypoint
ADD demo/project /runner/project
ADD demo/env /runner/env
ADD demo/inventory /runner/inventory

# Install Ansible Runner
RUN yum update -y && yum install -y git && \
        yum install -y glibc-langpack-en python3-pip.noarch openssl-devel.ppc64le gcc libffi-devel.ppc64le platform-python-devel.ppc64le sudo rsync openssh-clients && \
        pip3 install -U setuptools ansible && \
        git clone https://github.com/ansible/ansible-runner.git && cd ansible-runner && pip3 install . &&\
        cp /usr/local/bin/ansible-runner /bin && chmod +x /bin/ansible-runner &&\
        #localedef -c -i en_US -f UTF-8 en_US.UTF-8 && \
        chmod +x /bin/tini /bin/entrypoint && rm -rf /var/cache/yum

# In OpenShift, container will run as a random uid number and gid 0. Make sure things
# are writeable by the root group.
RUN mkdir -p /runner/inventory /runner/project /runner/artifacts /runner/.ansible/tmp && \
        chmod -R g+w /runner && chgrp -R root /runner && \
        chmod g+w /etc/passwd
VOLUME /runner/inventory
VOLUME /runner/project
VOLUME /runner/artifacts
#ENV LANG=en_US.UTF-8
#ENV LANGUAGE=en_US:en
#ENV LC_ALL=en_US.UTF-8
ENV RUNNER_BASE_COMMAND=ansible-playbook
ENV HOME=/runner
WORKDIR /runner
ENTRYPOINT ["entrypoint"]
CMD ["ansible-runner", "run", "/runner"]