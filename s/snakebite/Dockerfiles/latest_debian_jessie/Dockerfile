FROM ppc64le/openjdk:8-jdk

MAINTAINER Snehlata Mohite <smohite@us.ibm.com>

RUN apt-get update && apt-get install -y build-essential python python-dev python-pip curl wget tar && \
    export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el/ && \
    cd $HOME/ && git clone https://github.com/spotify/snakebite && \
    #virtualenv --python=python2 --system-site-packages env && source env/bin/activate && \
	ln -fs /usr/lib/python2.7/plat-powerpc64le-linux-gnu/_sysconfigdata_nd.py /usr/lib/python2.7/ && \
	cd $HOME/snakebite/ && pip install -r requirements-dev.txt && \
    cd $HOME/snakebite/ && python setup.py build && python setup.py install && export USER=root && \
    cd $HOME/snakebite/ && export TOX_ENV=py27-cdh && python setup.py test --tox-args="-e $TOX_ENV" && \
    cd $HOME/snakebite/ && export TOX_ENV=py27-hdp && python setup.py test --tox-args="-e $TOX_ENV" && \
    cd $HOME/ && rm -rf snakebite && apt-get purge -y build-essential python python-dev python-pip curl wget && apt-get -y autoremove

CMD ["python", "/bin/bash"]

