FROM ppc64le/r-base
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install git -y \
	&& git clone https://github.com/cran/cluster.git \
	&& cd cluster && git checkout 2.0.7-1 \
	&& cd .. \
	&& R CMD build cluster \
	&& R CMD INSTALL cluster \
	&& R CMD check cluster --no-manual \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
