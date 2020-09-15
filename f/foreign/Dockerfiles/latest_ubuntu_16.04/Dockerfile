FROM ppc64le/r-base
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

RUN apt-get update \
	&& apt-get install git -y \
	&& git clone https://github.com/cran/foreign.git \
	&& cd foreign && git checkout 0.8-69 \ 
	&& R -e 'install.packages("foreign",dependencies= TRUE,repos="http://cran.rstudio.com/")' \ 
	&& R CMD check foreign \
	&& apt-get purge --auto-remove git -y \
	&& rm -rf foreign

CMD [ "/bin/bash" ]
