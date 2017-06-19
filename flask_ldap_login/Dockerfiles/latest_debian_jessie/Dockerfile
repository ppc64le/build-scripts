FROM ppc64le/python:2.7
MAINTAINER  snehlata mohite <smohite@us.ibm.com>

RUN apt-get update && apt-get install -y libldap2-dev libsasl2-dev libssl-dev \
    && pip install --upgrade pip\
    && pip install flask flask-wtf python-ldap mock Flask-Testing pytest\
    && git clone https://github.com/ContinuumIO/flask-ldap-login\
    && cd flask-ldap-login/ && python setup.py install &&  python setup.py test && pytest\
    && cd ../ && rm -rf flask-ldap-login/

CMD ["python", "/bin/bash"]

