FROM ppc64le/r-base 
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install git -y \
	&& git clone https://github.com/cran/lattice.git \
	&& cd lattice && git checkout 0.20-35 \
	&& cd .. \
	&& R CMD build lattice \
	&& R CMD INSTALL lattice \
	&& R CMD check lattice --no-manual \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
