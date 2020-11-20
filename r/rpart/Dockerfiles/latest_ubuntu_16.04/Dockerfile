FROM ppc64le/r-base 
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install texlive texinfo r-cran-survival git -y \
	&& git clone https://github.com/cran/rpart.git \
	&& cd rpart && git checkout 4.1-13 \
	&& cd .. \
	&& R CMD build rpart \
	&& R CMD INSTALL rpart \
	&& R CMD check rpart --no-manual \
	&& apt-get purge --auto-remove texlive texinfo git -y

CMD ["/bin/bash"]
