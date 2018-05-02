FROM ppc64le/r-base 
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ 0 
RUN apt-get update \
	&& apt-get install git -y \
	&& git clone https://github.com/cran/labeling.git \
	&& cd labeling && git checkout 0.3 && cd .. \
	&& R CMD build labeling \
	&& R CMD INSTALL labeling \
	&& R CMD check labeling --no-manual \
	&& rm -rf labeling \
	&& apt-get purge git -y

CMD ["/bin/bash"]
