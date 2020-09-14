FROM ppc64le/r-base
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install texlive texinfo git -y \
	&& git clone https://github.com/cran/hexbin.git \
	&& cd hexbin && git checkout 1.27.2 \
	&& cd .. \
	&& R CMD build hexbin \
	&& R CMD INSTALL hexbin \
	&& R CMD check hexbin --no-manual \
	&& apt-get purge --auto-remove texlive texinfo git -y

CMD ["/bin/bash"]
