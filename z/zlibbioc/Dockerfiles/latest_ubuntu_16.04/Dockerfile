FROM ppc64le/r-base
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install texlive texinfo git -y \
	&& git clone https://github.com/Bioconductor/zlibbioc.git \
	&& R CMD build zlibbioc \
	&& R CMD INSTALL zlibbioc \
	&& R CMD check zlibbioc --no-manual \
	&& apt-get purge --auto-remove git texlive texinfo -y

CMD ["/bin/bash"]
