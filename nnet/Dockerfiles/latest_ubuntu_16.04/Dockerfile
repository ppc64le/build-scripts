FROM ppc64le/r-base 
MAINTAINER "Vibhuti Sawant <Vibhuti.Sawant@ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install git -y \
	&& git clone https://github.com/cran/nnet.git \
	&& cd nnet && git checkout 7.3-12 \
	&& cd .. \
	&& R CMD build nnet \
	&& R CMD INSTALL nnet \
	&& R CMD check nnet --no-manual \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
