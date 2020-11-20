FROM ppc64le/r-base
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install git -y \
	&& git clone https://github.com/cran/MASS.git \
	&& cd MASS && git checkout 7.3-50 \
	&& cd .. \
	&& R CMD build MASS \
	&& R CMD INSTALL MASS \
	&& R CMD check MASS --no-manual \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
