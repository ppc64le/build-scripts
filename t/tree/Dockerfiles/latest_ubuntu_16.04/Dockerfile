FROM ppc64le/r-base
MAINTAINER "Yugandha deshpande <yugandha@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install git -y \
	&& git clone https://github.com/cran/tree.git \
	&& cd tree && git checkout 1.0-39 \
	&& cd .. \
	&& R CMD build tree \
	&& R CMD INSTALL tree \
	&& R CMD check tree --no-manual \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
