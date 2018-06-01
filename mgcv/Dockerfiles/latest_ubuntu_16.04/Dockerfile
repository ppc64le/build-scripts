FROM ppc64le/r-base
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

RUN apt-get update \
        && apt-get install git -y \
	&& git clone https://github.com/cran/mgcv.git \ 
	&& cd mgcv && git checkout 1.8-7 && cd .. \
        && R CMD build mgcv \
	&& R CMD check mgcv --no-manual \
	&& R CMD INSTALL mgcv \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
