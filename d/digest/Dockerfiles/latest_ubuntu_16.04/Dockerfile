FROM ppc64le/r-base
MAINTAINER "Yugandha deshpande <yugandha@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install git openssl -y \
	&& R -e 'install.packages("knitr",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& git clone https://github.com/cran/digest.git \
	&& cd digest && git checkout 0.6.14 && cd .. \
	&& R CMD build digest \
	&& R CMD check "digest" --no-build-vignettes --no-manual \
	&& R CMD INSTALL digest \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
