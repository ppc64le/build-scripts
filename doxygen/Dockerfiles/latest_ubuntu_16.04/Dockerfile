FROM ubuntu:16.04

MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

RUN apt-get update \
	&& apt-get install make flex bison gcc g++ git python cmake texlive-latex-extra texlive texlive-latex-extra libxml2-utils cmake-data -y \
	&& git clone https://github.com/doxygen/doxygen.git \
	&& cd doxygen && git checkout Release_1_8_14 \
	&& mkdir build && cd build \
	&& cmake -G "Unix Makefiles" ../ &&  make \
	&& make test \
	&& make install \ 
	&& cd ../.. && rm -rf doxygen \
	&& apt-get purge --auto-remove make flex gcc g++ python git cmake -y

CMD ["doxygen", "-h"]
