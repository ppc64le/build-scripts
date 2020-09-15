FROM ppc64le/r-base
MAINTAINER "Yugandha deshpande <yugandha@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install git libxml2-dev -y \
	&& R -e 'install.packages("knitr",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("plogr",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("pkgconfig",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("memoise",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("blob",dependencies= TRUE,repos="http://cran.rstudio.com/") ; install.packages("bit64",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("DBItest",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("testthat",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& git clone https://github.com/r-dbi/RSQLite.git \
	&& cd RSQLite && git checkout v2.1.0 \
	&& R -e 'install.packages("RSQLite", dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& R CMD check RSQLite --no-manual \
	&& cd .. && rm -rf RSQLite \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
