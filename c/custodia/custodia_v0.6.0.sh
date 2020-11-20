#! /usr/bin/env bash

# Setting env variables
 export TOXENV=py36-noextras

# Installing Dependencies
 sudo apt-get update && sudo apt-get upgrade -yqq
 sudo apt-get install -yq software-properties-common
 sudo add-apt-repository -y ppa:deadsnakes/ppa && sudo apt-get update
 sudo apt-get install -yq --no-install-suggests \
      wget \
      git \
      python3.6 \
      python3.6-dev \
      python3-pip \
      git \
      enchant \
      locales \
      libffi-dev \
      libssl-dev

 # Generating en_US UTF-8
 locale-gen en_US.UTF-8
 export LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

 # Creating virtual environment
 python3 -m pip install --upgrade pip setuptools
 pip3 install virtualenv tox
 mkdir -p /tmp/project_root
 cd /tmp/project_root
 virtualenv --python=/usr/bin/python3.6 .
 source bin/activate

 # Cloning project
git clone https://github.com/latchset/custodia.git custodia
cd custodia
  
 # RUN project
 tox
 echo "Successfully Done!"
 exit 0
