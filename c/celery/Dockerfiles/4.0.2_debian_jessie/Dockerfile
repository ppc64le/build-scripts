FROM ppc64le/python:3.5-slim

MAINTAINER Snehlata Mohite (smohite@us.ibm.com)

ENV CELERY_VERSION 4.0.2
WORKDIR /home/user

RUN groupadd user && useradd --create-home --home-dir /home/user -g user user\
    && pip install redis\
    && pip install --upgrade pip\
    &&  pip install celery=="$CELERY_VERSION" \
    && { \
        echo 'import os'; \
        echo "BROKER_URL = os.environ.get('CELERY_BROKER_URL', 'amqp://')"; \
     } > celeryconfig.py


 # --link some-rabbit:rabbit "just works"
ENV CELERY_BROKER_URL amqp://guest@rabbit


USER user
CMD ["celery", "worker"]
