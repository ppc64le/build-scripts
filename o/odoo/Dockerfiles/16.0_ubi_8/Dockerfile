FROM registry.access.redhat.com/ubi8/ubi:latest

ARG PACKAGE_VERSION=16.0

RUN yum install -y wget git yum-utils openldap-devel libffi libffi-devel libxml2 libxml2-devel libxslt libxslt-devel libjpeg-devel openssl openssl-devel postgresql-devel gcc gcc-c++ libicu lz4 make bzip2-devel zlib-devel && \
    wget https://www.python.org/ftp/python/3.10.8/Python-3.10.8.tgz && \
    tar xzf Python-3.10.8.tgz && \
    cd Python-3.10.8 && \
    ./configure --with-system-ffi --with-computed-gotos --enable-loadable-sqlite-extensions && \
    make -j ${nproc} && \
    make altinstall && \
    rm Python-3.10.8.tgz && \
    cd .. && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    source "$HOME/.cargo/env" && \
    python3.10 -m venv odoo-venv && \
    . ./odoo-venv/bin/activate && \
    git clone https://github.com/odoo/odoo && \
    cd odoo && git checkout $PACKAGE_VERSION && \
    python3.10 -m pip install pip wheel && \
    python3.10 -m pip install -r requirements.txt && \
    wget https://raw.githubusercontent.com/odoo/docker/master/$PACKAGE_VERSION/entrypoint.sh && \
    wget https://raw.githubusercontent.com/odoo/docker/master/16.0/wait-for-psql.py && \
    wget https://raw.githubusercontent.com/odoo/docker/master/16.0/odoo.conf

EXPOSE 8069 8071 8072

ENV ODOO_RC /odoo/odoo.conf

USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]