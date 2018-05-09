FROM ppc64le/r-base
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install texlive texinfo unixodbc unixodbc-dev git -y \
	&& git clone https://github.com/cran/RODBC.git \
	&& cd RODBC && git checkout 1.3-15 \
	&& cd .. \
	&& R CMD build RODBC \
	&& R CMD INSTALL RODBC \
	&& R CMD check RODBC --no-manual \
	&& apt-get purge --auto-remove texlive texinfo git -y

CMD ["/bin/bash"]
