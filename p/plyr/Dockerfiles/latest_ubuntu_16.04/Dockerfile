FROM ppc64le/r-base
MAINTAINER "Yugandha deshpande <yugandha@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install git -y \
	&& R -e 'install.packages("Rcpp",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("testthat",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("abind",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& git clone https://github.com/hadley/plyr.git \
	&& cd plyr && git checkout v1.8.4 \
	&& R CMD build . \
	&& R CMD check plyr_1.8.4.tar.gz --no-manual \
	&& cd .. && R CMD INSTALL plyr \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
