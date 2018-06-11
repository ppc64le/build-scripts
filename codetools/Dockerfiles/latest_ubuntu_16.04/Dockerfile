FROM ppc64le/r-base 
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install git -y \
	&& git clone https://github.com/cran/codetools.git \
	&& cd codetools && git checkout 0.2-15 \
	&& cd .. \
	&& R CMD build codetools \
	&& R CMD INSTALL codetools \
	&& R CMD check codetools --no-manual \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
