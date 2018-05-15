FROM ppc64le/r-base
MAINTAINER "Yugandha deshpande <yugandha@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install git -y \
	&& R -e 'install.packages("testthat",dependencies= TRUE,repos="http://cran.rstudio.com/")' \ 
	&& git clone https://github.com/asl/svd \
	&& R CMD build svd \
	&& R CMD INSTALL svd \
	&& R CMD check svd --no-manual \
	&& rm -rf svd \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
