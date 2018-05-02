FROM ppc64le/r-base
MAINTAINER "Yugandha deshpande <yugandha@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install git -y \
	&& git clone https://github.com/cran/modeltools.git \
	&& cd modeltools && git checkout 0.2-21 \
	&& cd .. \
	&& R CMD build modeltools \
	&& R CMD INSTALL modeltools \
	&& R CMD check modeltools --no-manual \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
