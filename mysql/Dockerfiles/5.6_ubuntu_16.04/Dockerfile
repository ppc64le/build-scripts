FROM ppc64le/ubuntu:16.04

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN useradd mysql

ENV PATH /usr/local/mysql/bin:$PATH

RUN apt-get update -y && \
        apt-get install -y wget build-essential bison cmake git libncurses-dev && \
        wget https://github.com/mysql/mysql-server/archive/mysql-5.6.37.tar.gz && \
        tar -zxvf mysql-5.6.37.tar.gz && \
        cd mysql-server-mysql-5.6.37 && \
        cmake . && make && make test && make install && \
        apt-get purge -y  build-essential cmake git libncurses-dev wget bison && \
        apt-get autoremove -y && \
        cd /usr/local/mysql && chown -R mysql . && chgrp -R mysql . && \
        cp /mysql-server-mysql-5.6.37/support-files/my-default.cnf /etc/my.cnf && \
        cd /usr/local/mysql && ./scripts/mysql_install_db --user=mysql && \
        cp /mysql-server-mysql-5.6.37/support-files/mysql.server /etc/init.d/mysql && \
        sed -i '/\[mysqld\]/a bind-address=0.0.0.0' /etc/my.cnf && \
        ln -s /usr/local/mysql/bin/* /usr/bin/ && \
        rm -rf /mysql-5.6.37.tar.gz mysql-server-mysql-5.6.37/*

EXPOSE 3306
CMD ["mysqld_safe", "--user=mysql"]


