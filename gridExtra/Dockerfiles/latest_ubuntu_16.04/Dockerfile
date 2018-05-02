FROM ppc64le/r-base
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

RUN apt-get update \
	&& apt-get install git -y \
	&& git clone https://github.com/cran/gridExtra.git \
	&& cd gridExtra && git checkout 2.3 \
	&& R -e 'install.packages("knitr",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& R -e 'install.packages("egg",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& R -e 'install.packages("testthat",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& cd .. && R CMD build gridExtra \
	&& R CMD INSTALL gridExtra \
	&& R CMD check gridExtra --no-manual \
	&& apt-get purge --autoremove git -y \
	&& rm -rf gridExtra

CMD ["/bin/bash"]
