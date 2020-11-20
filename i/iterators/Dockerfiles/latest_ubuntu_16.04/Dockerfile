FROM ppc64le/r-base 
MAINTAINER "Yugandha deshpande <yugandha@us.ibm.com>"

ENV build_vignettes FALSE
ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install texinfo texlive-latex-extra git -y \
	&& R -e 'install.packages("texi2dvi",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& git clone https://github.com/cran/iterators.git \
	&& cd iterators && git checkout 1.0.9 \
	&& cd .. \
	&& R CMD build iterators \
	&& R CMD INSTALL iterators \
	&& R CMD check iterators --no-manual \
	&& apt-get purge --auto-remove git texlive-latex-extra -y

CMD ["/bin/bash"]
