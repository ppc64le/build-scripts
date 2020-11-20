FROM ppc64le/r-base
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

RUN apt-get update \
        && apt-get install git -y \
	&& git clone https://github.com/cran/class.git \
	&& cd class && git checkout 7.3-14 \
        && R -e 'install.packages("class",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& R CMD check class \
	&& cd .. && rm -rf class \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
