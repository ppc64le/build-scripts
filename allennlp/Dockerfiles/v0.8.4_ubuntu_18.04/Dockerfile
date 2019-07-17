#This Dockerfile is based on and has been derived from the 
#official community version written and maintained by them at
#https://github.com/allenai/allennlp and has been modified 
#to work on Power
FROM docker.io/nvidia/cuda-ppc64le:10.1-devel-ubuntu18.04

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Tell nvidia-docker the driver spec that we need as well as to
# use all available devices, which are mounted at /usr/local/nvidia.
# The LABEL supports an older version of nvidia-docker, the env
# variables a newer one.
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
LABEL com.nvidia.volumes.needed="nvidia_driver"

ENV PATH $PATH:/conda/bin
ENV PYTHON_VERSION 3.6
ENV IBM_POWERAI_LICENSE_ACCEPT yes
ENV ALLENNLP_VERSION v0.8.4

COPY awscli_spacy_testfix.patch /

ARG CACHE_MODELS=false

# Install base packages.
RUN apt-get update --fix-missing && apt-get install -y \
    git \
    wget \
    build-essential && \
	#Set up conda environment and install allennlp from source
    	wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh && \
	sh Miniconda3-latest-Linux-ppc64le.sh -b -p /conda && \
	/conda/bin/conda update -y -n base conda && \
	conda create -n allennlp -y python=${PYTHON_VERSION} && \
	conda init bash && \
	. /conda/etc/profile.d/conda.sh && \
	echo "conda activate allennlp" >> ~/.bashrc && \
	conda activate allennlp && \
	git clone https://github.com/allenai/allennlp && \
	cd allennlp && git checkout ${ALLENNLP_VERSION} && \
	conda install -y -c "https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/linux-ppc64le" \
		-c "conda-forge"  pytorch spacy h5py scikit-learn && \
	git apply /awscli_spacy_testfix.patch && \
	pip install -r requirements.txt && \
	pip install --editable .  && \
	# Compile EVALB - required for parsing evaluation.
	# EVALB produces scary looking c-level output which we don't
	# care about, so we redirect the output to /dev/null.
	cd allennlp/tools/EVALB && make && \
	# Caching models when building the image makes a dockerized server start up faster, but is slow for
	# running tests and things, so we skip it by default.
	cd /allennlp && ./scripts/cache_models.py && \
	apt-get remove -y git build-essential

# Optional argument to set an environment variable with the Git SHA
ARG SOURCE_COMMIT
ENV ALLENNLP_SOURCE_COMMIT $SOURCE_COMMIT

LABEL maintainer="sethp@us.ibm.com"

EXPOSE 8000
CMD ["/bin/bash"]
