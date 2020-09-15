FROM ppc64le/r-base
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"
RUN apt-get update \
	&& apt-get install git -y \
	&& R -e 'install.packages("foreach",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& R -e 'install.packages("akima",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& git clone https://github.com/cran/gam.git \
	&& cd gam && git checkout 1.15 && cd .. \
	&& R CMD build gam && R CMD INSTALL gam \
	&& R CMD check gam --no-manual \
	&& apt-get purge --auto-remove git -y \
	&& rm -rf gam 
CMD ["/bin/bash"]
