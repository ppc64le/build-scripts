FROM ppc64le/r-base 
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ 0
RUN apt-get update \
	&& apt-get install git -y \
	&&  R -e 'install.packages("Hmisc",dependencies= TRUE,repos="http://cran.rstudio.com/")' \ 
	&& git clone https://github.com/cran/nlme.git \
	&& cd nlme && git checkout 3.1-122 \
	&& cd .. && R CMD build nlme \
	&& R CMD INSTALL nlme \
	&& R CMD check nlme --no-manual \
	&& rm -rf nlme \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
