FROM openjdk:8
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

RUN apt-get update -y \
    && apt-get install openssl libssl-dev libncurses5 libncurses5-dev \
       unixodbc unixodbc-dev make tar gcc wget git locales -y \
    && cd $HOME \
    && wget http://erlang.org/download/otp_src_20.0.tar.gz \
    && tar xvzf otp_src_20.0.tar.gz \
    && cd otp_src_20.0 \
    && rm -rf ../otp_src_20.0.tar.gz \
    && export ERL_TOP=`pwd` && export PATH=$PATH:$ERL_TOP/bin \
    && ./configure && make && make install \
    && make \
    && make install \
    && cd .. \
    && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen en_US en_US.UTF-8 \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && echo "export LC_ALL=en_US.UTF-8" >> ~/.bashrc \
    && echo "export LANG=en_US.UTF-8" >> ~/.bashrc \
    && echo "export LANGUAGE=en_US.UTF-8" >> ~/.bashrc \
    && git clone https://github.com/elixir-lang/elixir.git \
    && cd elixir \
    && make clean test \
    && make install \
    && cd .. \
    && git clone https://github.com/bradleyd/exgrid.git \
    && cd exgrid \
    && export MIX_ENV=test \
    && mix local.rebar --force \
    && mix local.hex --force \
    && mix deps.get --force \
    && mix test \
    && apt-get purge --auto-remove git wget make tar -y

CMD ["/bin/bash"]
