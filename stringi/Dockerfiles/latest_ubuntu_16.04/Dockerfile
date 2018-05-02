FROM ppc64le/r-base
MAINTAINER "Yugandha deshpande <yugandha@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install git -y \
	&& git clone https://github.com/gagolews/stringi.git \
	&& cd stringi && git checkout v1.1.6 \
	&& cd .. \
	&& R CMD build stringi \
	&& R CMD INSTALL stringi \
	&& R CMD check stringi --no-manual \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
