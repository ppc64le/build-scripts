FROM ppc64le/python:3.5-slim

MAINTAINER Snehlata Mohite <smohite@us.ibm.com>

RUN apt-get update && apt-get install -y qt5-qmake qt5-default wget libpq-dev gfortran libatlas-base-dev freetds-dev python3-dev libffi-dev libssl-dev build-essential git pyqt5-dev python3-pyqt5 && \
    cd $HOME/ && git clone https://github.com/biolab/orange3.git && \
	cd $HOME/ && wget https://sourceforge.net/projects/pyqt/files/sip/sip-4.19.3/sip-4.19.3.tar.gz && tar -xzf sip-4.19.3.tar.gz && cd sip-4.19.3/ && python configure.py && make && make install && \
	cd $HOME/ && wget https://sourceforge.net/projects/pyqt/files/PyQt5/PyQt-5.9/PyQt5_gpl-5.9.tar.gz && tar -xzf PyQt5_gpl-5.9.tar.gz && cd PyQt5_gpl-5.9/ && printf "yes\n" |  python3 configure.py && make && make install && \
	pip install --upgrade pip && pip install beautifulsoup4 docutils numpydoc recommonmark>=0.1.1 Sphinx>=1.3 && cd $HOME/orange3/ && pip install -r requirements-core.txt && pip install -r requirements-dev.txt && pip install -r requirements-gui.txt && pip install -r requirements-sql.txt && pip install -e . && \
    cd $HOME/orange3/ && python setup.py build && python setup.py install && python setup.py test && \
    cd $HOME/ && rm -rf orange3 PyQt5_gpl-5.9 PyQt5_gpl-5.9.tar.gz sip-4.19.3 sip-4.19.3.tar.gz && apt-get purge -y qt5-qmake qt5-default python-sip-dev python-sip-dbg wget libpq-dev gfortran libatlas-base-dev freetds-dev python3-dev libffi-dev libssl-dev build-essential git pyqt5-dev python3-pyqt5 && apt-get -y autoremove

CMD ["python", "/bin/bash"]

