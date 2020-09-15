FROM ppc64le/r-base
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

RUN apt-get update \
	&& apt-get install git -y \
	&& git clone https://github.com/cran/akima.git \
	&& cd akima && git checkout 0.6-2 \
	&& R -e 'install.packages("sp",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& cd .. && R CMD build akima \
	&& R CMD INSTALL akima \
	&& apt-get purge --auto-remove git -y \
	&& rm -rf akima

CMD [ "/bin/bash" ]
