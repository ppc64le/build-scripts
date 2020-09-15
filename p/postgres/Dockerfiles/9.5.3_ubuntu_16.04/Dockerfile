FROM ppc64le/ubuntu:16.04
MAINTAINER kiritim@us.ibm.com

# Install all the dependencies of Postgres before proceeding to install Postgres

RUN apt-get update -y
RUN apt-get install -y make automake gcc flex bison perl git libreadline-dev zlib1g-dev

# Now checkout the latest source code from git and switch to branch REL9_5_3

RUN git clone https://github.com/postgres/postgres.git
RUN cd postgres && git checkout tags/REL9_5_3

#Now proceed with the installation of postgres

RUN cd postgres && ./configure && make && make install

RUN mkdir -p /usr/local/pgsql/data
RUN useradd postgres && chown -R postgres /usr/local/pgsql
RUN ln -s /usr/local/pgsql/bin/* /usr/bin/.

#Configure and start DB as postgres user
USER postgres
RUN cd /usr/local/pgsql/bin && \
     ./initdb -E UTF8 -D /usr/local/pgsql/data && \
     ./pg_ctl -D /usr/local/pgsql/data start

ENV PATH /usr/local/pgsql/bin:$PATH
ENV PGDATA /usr/local/pgsql/data
EXPOSE 5432
RUN echo "listen_addresses='*'" >> /usr/local/pgsql/data/postgresql.conf

RUN echo "host    all             all             0.0.0.0/0                 trust" >> /usr/local/pgsql/data/pg_hba.conf

ENTRYPOINT ["postgres"]

