FROM ppc64le/r-base
MAINTAINER "Yugandha deshpande <yugandha@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install git -y \
	&& git clone https://github.com/cran/chron.git \
	&& cd chron && git checkout 2.3-52 \
	&& cd .. \
	&& R CMD build chron \
	&& R CMD INSTALL chron \
	&& R CMD check chron --no-manual \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
