#Dockerfile for building "ipywidgets"

FROM node:10.9.0-stretch
MAINTAINER Priya Seth <sethp@us.ibm.com>

RUN apt-get update && apt-get install -y python-dev python-pip python-setuptools git \
	&& pip install pytest \
	&& npm install -g yarn \
        && cd ../ && git clone https://github.com/ipython/ipywidgets \
	&& cd ipywidgets/ && bash dev-install.sh --sys-prefix \
        && bash ./scripts/travis_before_install_py.sh \
	&& bash ./scripts/travis_install_py.sh && bash ./scripts/travis_script_py.sh \
        && cd ../ && apt-get -y autoremove && rm -rf /ipywidgets/

CMD ["python", "/bin/bash"]

