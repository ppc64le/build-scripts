FROM ppc64le/r-base
MAINTAINER "Yugandha deshpande <yugandha@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install texinfo texlive-latex-extra git -y \
	&& git clone https://github.com/cran/SparseM.git \
	&& cd SparseM && git checkout 1.76 \
	&& cd .. \
	&& R CMD build SparseM \
	&& R CMD INSTALL SparseM \
	&& R CMD check SparseM --no-manual \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
