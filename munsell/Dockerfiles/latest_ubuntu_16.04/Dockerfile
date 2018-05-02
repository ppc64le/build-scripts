FROM ppc64le/r-base
MAINTAINER "Yugandha deshpande <yugandha@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install git -y \
	&& R -e 'install.packages("colorspace",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("testthat",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("ggplot2",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& git clone https://github.com/cran/munsell.git \
	&& cd munsell && git checkout 0.4.3 \
	&& cd .. \
	&& R CMD build munsell \
	&& R CMD INSTALL munsell \
	&& R CMD check munsell --no-manual \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
