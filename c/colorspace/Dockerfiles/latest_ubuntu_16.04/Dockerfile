FROM ppc64le/r-base 
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

RUN apt-get update \
        && apt-get install git -y \
	&& git clone https://github.com/cran/colorspace.git \
	&& cd colorspace && git checkout 1.3-2 \
        && R -e 'install.packages("colorspace",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& R CMD check colorspace \
	&& cd .. && rm -rf colorspace \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
