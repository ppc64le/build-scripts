FROM ppc64le/r-base 
MAINTAINER "Vibhuti Sawant <Vibhuti.Sawant@ibm.com>"


ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install texlive texinfo git -y \
	&& git clone https://github.com/cran/Formula.git \
	&& cd Formula && git checkout 1.2-3 \
	&& cd .. \
	&& R CMD build Formula \
	&& R CMD INSTALL Formula \
	&& R CMD check Formula --no-manual \
	&& apt-get purge --auto-remove texlive texinfo git -y

CMD ["/bin/bash"]
