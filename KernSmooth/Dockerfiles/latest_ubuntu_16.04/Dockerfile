FROM ppc64le/r-base
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

RUN apt-get update \
        && apt-get install git -y \
	&& git clone https://github.com/cran/KernSmooth \
	&& cd KernSmooth && git checkout 2.23-15 && cd .. \
        && R CMD build KernSmooth \
	&& R CMD check KernSmooth --no-manual \
	&& R CMD INSTALL KernSmooth \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
