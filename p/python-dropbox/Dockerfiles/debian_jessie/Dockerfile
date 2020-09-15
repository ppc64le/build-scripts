FROM ppc64le/python:2.7

RUN apt-get update && apt-get install -y python-pip && \
    pip install --upgrade pip cython nose && \
	cd /$HOME/ && git clone https://github.com/enginoid/python-dropbox && \
	cd /$HOME/python-dropbox/ && python setup.py build && python setup.py install && nosetests && \
	cd /$HOME/ && rm -rf python-dropbox
	
CMD ["python", "/bin/bash"] 
