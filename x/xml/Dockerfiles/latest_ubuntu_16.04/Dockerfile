FROM ppc64le/r-base
MAINTAINER "Yugandha deshpande <yugandha@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install git libxml2-dev -y \
	&& git clone https://github.com/cran/XML.git \
	&& cd XML && git checkout 3.98-1.8 \
	&& cd .. \
	&& R CMD build XML \
	&& R CMD INSTALL XML \
	&& R CMD check XML --no-manual \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
