FROM ppc64le/r-base
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

RUN apt-get update \
        && apt-get install git -y \
	&& git clone https://github.com/cran/prodlim.git \
	&& cd prodlim && git checkout 1.6.1 && cd .. \
	&& R -e 'install.packages("Rcpp",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("lava",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
        && R CMD build prodlim \
	&& R CMD check prodlim --no-manual \
	&& R CMD INSTALL prodlim \
	&& cd .. && rm -rf prodlim \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
