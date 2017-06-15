FROM ppc64le/ubuntu:16.04
MAINTAINER kiritim@us.ibm.com

# Install all the dependencies of Postgres before proceeding to install Postgres

RUN apt-get update -y
RUN apt-get install -y build-essential bison cmake git libncurses-dev

# Clone the repository and checkout the latest stable branch
RUN git clone https://github.com/MariaDB/server.git --branch 10.1

# Now and install and configure the mariadb server
RUN cd server && BUILD/autorun.sh && \
    ./configure &&  make && make install && make test

RUN useradd mysql
ENV PATH /usr/local/mysql/bin:$PATH
RUN cd /usr/local/mysql && chown -R mysql . && chgrp -R mysql .
RUN cd /usr/local/mysql && ./scripts/mysql_install_db --user=mysql
RUN cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql
RUN sed -i '/\[mysqld\]/a bind-address=0.0.0.0' /usr/local/mysql/support-files/my-small.cnf
RUN cp /usr/local/mysql/support-files/my-small.cnf /etc/my.cnf
RUN ln -s /usr/local/mysql/bin/* /usr/bin/.
RUN /etc/init.d/mysql start && mysqladmin -u root password root && \
     mysql -uroot -proot -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root'"

EXPOSE 3306

ENTRYPOINT ["/usr/bin/mysqld","--user=mysql"]

