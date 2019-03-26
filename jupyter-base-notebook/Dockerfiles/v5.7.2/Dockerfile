# Copyright (c) IBM Corporation 2016
# Distributed under the terms of the Modified BSD License.

# Ubuntu image
FROM ubuntu:18.04

LABEL maintainer="Ilsiyar Gaynutdinov <ilsiyar_gaynutdinov@ru.ibm.com>"

USER root

# Configure environment
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH
ENV SHELL /bin/bash
ENV NB_USER jovyan
ENV NB_UID 1000
ENV HOME /home/$NB_USER
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8


# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get -yq dist-upgrade && \
        apt-get install -yq --no-install-recommends \
        build-essential bzip2 ca-certificates cmake git locales sudo wget && \
        rm -rf /var/lib/apt/lists/* && \
        echo "LANGUAGE=en_US.UTF-8" >> /etc/default/locale && \
        echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale && \
        echo "LC_TYPE=en_US.UTF-8" >> /etc/default/locale && \
        locale-gen en_US en_US.UTF-8 && \
        #build and install Tini for ppc64le
        wget https://github.com/krallin/tini/archive/v0.18.0.tar.gz && \
        tar zxvf v0.18.0.tar.gz && \
        rm -rf v0.18.0.tar.gz && \
        cd tini-0.18.0/ && \
        cmake . && make install && \
        mv ./tini /usr/local/bin/tini  && \
        chmod +x /usr/local/bin/tini && \
        cd .. &&\
        # Create jovyan user with UID=1000 and in the 'users' group
        useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
        mkdir -p $CONDA_DIR && \
        chown $NB_USER $CONDA_DIR

USER $NB_UID

# Setup jovyan home directory
RUN mkdir /home/$NB_USER/work && \
        mkdir /home/$NB_USER/.jupyter && \
        echo "cacert=/etc/ssl/certs/ca-certificates.crt" > /home/$NB_USER/.curlrc && \
        # Install conda as jovyan
        cd /tmp && \
        mkdir -p $CONDA_DIR && \
        wget https://repo.continuum.io/miniconda/Miniconda3-4.5.11-Linux-ppc64le.sh && \
        /bin/bash Miniconda3-4.5.11-Linux-ppc64le.sh -f -b -p $CONDA_DIR && \
        rm -rf Miniconda3-4.5.11-Linux-ppc64le.sh && \
        $CONDA_DIR/bin/conda install --quiet --yes conda=4.5.11  && \
        $CONDA_DIR/bin/conda config --system --add channels conda-forge && \
        $CONDA_DIR/bin/conda config --system --set auto_update_conda false && \
        conda clean -tipsy && \
        # Install Jupyter notebook and Hub
        pip install --upgrade pip && \
        pip install --quiet --no-cache-dir \
            'notebook==5.7.2' \
            'jupyterhub==0.9.4' \
            'jupyterlab==0.35.4' && \
        # downgrade tornado version
        pip install "tornado<6"

USER root

EXPOSE 8888
WORKDIR /home/$NB_USER/work

# Configure container startup
ENTRYPOINT ["tini", "-g", "--"]
CMD ["start-notebook.sh"]

# Add local files as late as possible to avoid cache busting
COPY start.sh /usr/local/bin/
COPY start-notebook.sh /usr/local/bin/
COPY start-singleuser.sh /usr/local/bin/
COPY jupyter_notebook_config.py /home/$NB_USER/.jupyter/
RUN echo "ALL            ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers && \
        chown -R $NB_USER:users /home/$NB_USER/.jupyter && \
        # remove build time dependencies
        apt-get purge -y build-essential bzip2 ca-certificates cmake git wget && \
        apt-get autoremove -y

# Switch back to jovyan to avoid accidental container runs as root
USER $NB_UID
