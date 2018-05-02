FROM ppc64le/r-base
MAINTAINER "Yugandha deshpande <yugandha@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install git -y \
	&& R -e 'install.packages("plyr",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("Rcpp",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("stringr",dependencies= TRUE,repos="http://cran.rstudio.com/");' \
	&& git clone https://github.com/cran/reshape2.git \
	&& cd reshape2 && git checkout 1.4.3 \
	&& R CMD build . \
	&& R CMD INSTALL reshape2_1.4.3.tar.gz && cd .. \
	&& cd .. && R CMD check reshape2 --no-manual \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
