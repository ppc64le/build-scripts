FROM ppc64le/ubuntu:xenial

MAINTAINER "Yugandha Deshpande"

ENV DJANGO_VERSION 1.11.6

RUN apt-get -y update && \
        apt-get install -y  git python3 python3-dev python3-setuptools && \
        easy_install3 pip && \
        git clone https://github.com/django/django.git --branch=${DJANGO_VERSION} && \
        cd django/ && \
        python3 setup.py install && \
        cd /root && django-admin startproject my_project && \
        cd /root/my_project && \
        sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \['*'\]/" /root/my_project/my_project/settings.py && \
        apt-get purge -y git python3-dev && \
        apt-get -y autoremove && \
        rm -rf /django

EXPOSE 8000

RUN echo "cd /root/my_project" >> run.sh && \
    echo "python3 /root/my_project/manage.py runserver 0.0.0.0:8000 &" > run.sh && \
    echo "python3 /root/my_project/manage.py migrate" >> run.sh && \
    echo "/bin/bash" >> run.sh && \
    chmod +x run.sh
CMD ./run.sh

