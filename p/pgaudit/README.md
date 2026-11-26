
 Step to exec test cases successfully REL_11_STABLE and REL_12_STABLE:-  
 ---------
 ```Binaries for Power are available from postgresql```:-

      https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-8-ppc64le/pgaudit13_11-1.3.4-1.rhel8.ppc64le.rpm
      https://download.postgresql.org/pub/repos/yum/12/redhat/rhel-8-ppc64le/pgaudit14_12-1.4.3-1.rhel8.ppc64le.rpm
      https://download.postgresql.org/pub/repos/yum/14/redhat/rhel-8-aarch64/pgagent_14-4.2.1-1.rhel8.aarch64.rpm
      https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-8-ppc64le/pgaudit12_10-1.2.2-1.rhel8.ppc64le.rpm
      
       Install dependencies :-

       yum install -y git openssl-devel redhat-rpm-config wget automake cmake libtool autoconf-2.69 gcc-c++ make
       dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
       dnf install -y postgresql postgresql12-server postgresql12-devel
      
       dnf install -y postgresql postgresql11-server postgresql11-devel
       dnf install https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-8-ppc64le/postgresql11-libs-11.15-1PGDG.rhel8.ppc64le.rpm
       dnf install https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-8-ppc64le/postgresql11-server-11.15-1PGDG.rhel8.ppc64le.rpm
       dnf install https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-8-ppc64le/postgresql11-contrib-11.15-1PGDG.rhel8.ppc64le.rpm
       yum install readline-devel
       yum install perl-Carp-1.42-396.el8.noarch    perl-Exporter-5.72-396.el8.noarch    perl-libs-4:5.26.3-416.el8



    export PATH="/usr/pgsql-11/bin:$PATH"

    cd /var/lib/pgsql/11/data
    vim postgresql.conf

    Edit following line under postgresql :-

    shared_preload_libraries = 'pg_stat_statements' # (change requires restart)
    shared_preload_libraries = 'pgaudit'

    Restart the service :-

    service postgresql-11.service restart

    [root@Power-vm-rhel81 data]#  psql -U postgres
    psql (12.10, server 11.15)
    Type "help" for help.


      psql -c "alter user postgres with password '<pwd>'"

    postgres=# CREATE EXTENSION pg_stat_statements
    postgres=# CREATE EXTENSION pgaudit

    Run build:-

      make install USE_PGXS=1 PG_CONFIG=/usr/pgsql-11/bin/pg_config

    Run test :-

      PGUSER=postgres make installcheck USE_PGXS=1 PG_CONFIG=/usr/pgsql-11/bin/pg_config



    Note :-      https://www.postgresqltutorial.com/postgresql-cheat-sheet/     (Postgres check sheet) 
                 https://computingforgeeks.com/how-to-install-postgresql-11-on-centos-rhel-8/
                 https://pganalyze.com/docs/install/01_enabling_pg_stat_statements
                 
              
    For version REL_12_STABLE
    ------------------       

              service postgresql-12.service restart
              dnf install https://download.postgresql.org/pub/repos/yum/12/redhat/rhel-8-ppc64le/postgresql12-contrib-12.10-1PGDG.rhel8.ppc64le.rpm
              make install USE_PGXS=1 PG_CONFIG=/usr/pgsql-12/bin/pg_config
              PGUSER=postgres make installcheck USE_PGXS=1 PG_CONFIG=/usr/pgsql-12/bin/pg_config 
