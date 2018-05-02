FROM ppc64le/r-base
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false 
RUN apt-get update \
	&& apt-get install git -y \
	&& R -e 'install.packages("RItools",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("coin",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("tables",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("penalized",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& git clone https://github.com/cran/uplift.git \
	&& cd uplift && git checkout 0.3.5 \
	&& cd .. && R CMD build uplift \
	&& R CMD INSTALL uplift \
	&& R CMD check uplift --no-manual \
	&& rm -rf uplift \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"] 
