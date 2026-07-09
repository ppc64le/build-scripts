How to run drupal related modules test cases.
-------------

Summary :-

    To run test cases in drupal module, we need drupal core package and drupal complete framework which incluse a database,apache server and core package itself.
    There are 3 type of tests in drupal unit, functional, intergration. For unit tests we don't need drupal full framework like database.
    Unit tests does not use database.

*************************

Copy following files into VM thats needed to run docker file succesfully.

    1) automate_drupal.sh.txt
    2) Dockerfile.drupal.ubi
    3) drupal.zip
    4) drupal_schema.sql

Rename 2 files:-

    # cp Dockerfile.drupal.ubi Dockerfile
    # cp automate_drupal.sh.txt automate_drupal.sh
    # chmod +x automate_drupal.sh


Now create an image from dockerfile (Dockerfile.drupal.ubi i.e Dockerfile)

     # docker build -t drupal_image .
     # docker images


Then run a container using that image.

    # docker run -it -d drupal_image /bin/bash
    # docker ps
    # docker exec -it 69cabf536f6f /bin/bash

Live drupal webserver will be available at http://<ip>:8081

After that we need to run below command inside container.Run it in single command . Step 1 will take sometime to exec.

Step 1:-

    su - postgres -c 'if [[ $(psql -l | grep dru2_pg) ]]; then     echo "Database already configured..."; else    /usr/pgsql-13/bin/pg_ctl -D /var/lib/pgsql/13/data/ start;     /usr/pgsql-13/bin/createdb -T template0 dru2_pg;     psql dru2_pg < /opt/app-root/src/drupal_schema.sql; fi'

Step 2:-

    /usr/sbin/httpd -k start;


Go to :-

    # cd /opt/app-root/src/drupal/modules

Clone the module which you wanted to test :-

    # git clone https://git.drupalcode.org/project/flag.git
    # git checkout <versions>

Follow automate_drupal.sh for more detail:-
    # cd /opt/app-root/src/drupal/modules/flag
    bash-4.4# pwd
    /opt/app-root/src/drupal/modules/flag
    # cd /opt/app-root/src/drupal

    bash-4.4# yum install -y git php php-gd


        bash-4.4# pwd
        /opt/app-root/src/drupal
	bash-4.4# ./vendor/bin/drush en flag
           [notice] Already enabled: flag

    cd /opt/app-root/src/drupal/core
    bash-4.4# pwd
    /opt/app-root/src/drupal/core


RUN TEST:-
----------

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/flag/tests/src


Test output
----------------

bash-4.4# cd core
bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/flag/tests/src
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/flag/tests/src
................SSSSSS...................                         41 / 41 (100%)

Time: 17.22 minutes, Memory: 6.00 MB

OK, but incomplete, skipped, or risky tests!
Tests: 41, Assertions: 682, Skipped: 6.
