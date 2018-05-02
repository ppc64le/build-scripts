FROM ppc64le/r-base
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

RUN apt-get update \
        && apt-get install git -y \
	&& git clone https://github.com/cran/hash.git \
	&& cd hash && git checkout 3.0.1 \
     	&& R -e 'install.packages("hash",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& cd .. && rm -rf hash \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
