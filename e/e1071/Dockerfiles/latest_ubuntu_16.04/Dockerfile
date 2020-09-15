FROM ppc64le/r-base
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

RUN apt-get update \
        && apt-get install git -y \
	&& git clone https://github.com/cran/e1071.git \
	&& cd e1071 && git checkout 1.6-8 \
      && R -e 'install.packages("e1071",dependencies= TRUE,repos="http://cran.rstudio.com/")'  \
	&& R CMD check e1071 \
	&& cd .. && rm -rf e1071 \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
