FROM ppc64le/r-base
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install texlive texinfo git -y \
	&& git clone https://github.com/cran/mvtnorm.git \
	&& cd mvtnorm && git checkout 1.0-7 \
	&& cd .. \
	&& R CMD build mvtnorm \
	&& R CMD INSTALL mvtnorm \
	&& R CMD check mvtnorm --no-manual \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
