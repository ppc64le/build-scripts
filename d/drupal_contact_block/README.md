How to run drupal related modules test cases.
-------------

Summary :-

    To run test cases in drupal module we need drupal core package and drupal complete framework which incluse one database,apache server,and core package itself.
    There are 3 type of tests in drupal unit,functional,intergration. For unit test we dont need drupal full framework like database.
    Unit test does not use database testing.

*************************

Copy following files into VM thats needed to run docker file succesfully.

    1) automate_drupal.sh.txt
    2) Dockerfile.drupal.ubi
    3) drupal.zip
    4) drupal_schema.sql

Rename 2 files:-

    #cp Dockerfile.drupal.ubi Dockerfile
    #cp automate_drupal.sh.txt automate_drupal.sh
    #chmod +x automate_drupal.sh


Now create an image from dockerfile (Dockerfile.drupal.ubi i.e Dockerfile)

     #docker build -t drupal_image .
     #docker images


Then run a container using that image.

    #docker run -it -d drupal_image /bin/bash
    #docker ps
    #docker exec -it 69cabf536f6f /bin/bash

Live drupal webserver will be available at http://<ip>:8081

After that we need to run below command inside container.Run it in single command . Step 1 will take sometime to exec.

Step 1:-

    su - postgres -c 'if [[ $(psql -l | grep dru2_pg) ]]; then     echo "Database already configured..."; else    /usr/pgsql-13/bin/pg_ctl -D /var/lib/pgsql/13/data/ start;     /usr/pgsql-13/bin/createdb -T template0 dru2_pg;     psql dru2_pg < /opt/app-root/src/drupal_schema.sql; fi'

Step 2:-

    /usr/sbin/httpd -k start;


Go to :-

    #cd /opt/app-root/src/drupal/modules

Clone the module which you wanted to test :-

    #git clone https://git.drupalcode.org/project/contact_block.git
    #git checkout <versions>

Clone the prerequisite dependency like ctools

        #git clone https://git.drupalcode.org/project/ctools
        #git checkout <versions>

Follow automate_drupal.sh for more detail:-

    #cd /opt/app-root/src/drupal

    bash-4.4#yum install -y git php php-gd


    #cd /opt/app-root/src/drupal/modules/contact_block
    bash-4.4# pwd
    /opt/app-root/src/drupal/modules/contact_block

        bash-4.4# pwd
        /opt/app-root/src/drupal
        bash-4.4# ./vendor/bin/drush en ctools
        [success] Successfully enabled: ctools
        bash-4.4# ./vendor/bin/drush en contact_block
        [success] Successfully enabled: contact_block


    cd /opt/app-root/src/drupal/core
    bash-4.4# pwd
    /opt/app-root/src/drupal/core


RUN TEST:-
----------

    bash-4.4# ../vendor/phpunit/php ../modules/contact_block/tests


Test output
----------------
php-code-coverage/ php-file-iterator/ php-text-template/ php-timer/         php-token-stream/  phpunit/
bash-4.4# ../vendor/phpunit/phpunit/phpunit  ../modules/contact_block/tests
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/contact_block/tests
.                                                                   1 / 1 (100%)

Time: 1.88 seconds, Memory: 4.00 MB

OK (1 test, 2 assertions)

