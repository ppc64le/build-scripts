FROM ppc64le/r-base 

MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

RUN apt-get update \
	&& apt-get install git -y \
	&& git clone https://github.com/cran/boot.git \
	&& cd boot && git checkout 1.3-20 \
	&& R -e 'install.packages("boot",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& R CMD check boot --no-manual \
	&& apt-get purge --auto-remove git -y \
	&& cd .. && rm -rf boot

CMD [ "/bin/bash" ]
