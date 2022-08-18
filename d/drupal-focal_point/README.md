How to run drupal related modules test cases.
-------------

Summary :-

    To run test cases in drupal module, we need drupal core package and drupal complete framework which includes a database, apache server and core package itself.
    There are 3 type of tests in drupal unit, functional, FunctionalJavascript. For unit tests, we don't need drupal full framework like database.
    Unit tests don't use database.
    

*************************

Copy following files into the VM that is needed to run docker file successfully.

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
    # docker exec -it <container-id> /bin/bash

Live drupal webserver will be available at http://<ip>:8081

After that we need to run below command inside the container. Run it in single command. Step 1 will take some time to exec.

Step 1:-

    su - postgres -c 'if [[ $(psql -l | grep dru2_pg) ]]; then     echo "Database already configured..."; else    /usr/pgsql-13/bin/pg_ctl -D /var/lib/pgsql/13/data/ start;     /usr/pgsql-13/bin/createdb -T template0 dru2_pg;     psql dru2_pg < /opt/app-root/src/drupal_schema.sql; fi'

Step 2:-

    /usr/sbin/httpd -k start;


Go to :-

    # cd /opt/app-root/src/drupal/modules

Clone the module which you wanted to test :-

    # git clone https://git.drupalcode.org/project/focal_point.git
    # git checkout <versions>

Follow automate_drupal.sh for more detail:-
    # cd /opt/app-root/src/drupal

    # yum install -y git php php-dom php-mbstring zip unzip gd gd-devel php-gd php-pdo php-mysqlnd
    # php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
    # composer require drupal/crop:2.2.0
    # bash-4.4# ./vendor/bin/drush pm:enable focal_point
        The following module(s) will be enabled: focal_point, crop

        Do you want to continue? (yes/no) [yes]:
        > yes

       [success] Successfully enabled: focal_point, crop
    # cd /opt/app-root/src/drupal/core


RUN TEST:-
----------
    # ../vendor/phpunit/phpunit/phpunit ../modules/focal_point/tests/

Test output
---------------
    bash-4.4# cd core/
    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/focal_point/tests/src/
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/focal_point/tests/src/
.S.............................................................  63 / 158 ( 39%)
............................................................... 126 / 158 ( 79%)
................................                                158 / 158 (100%)

Time: 1.48 minutes, Memory: 10.00 MB

OK, but incomplete, skipped, or risky tests!
Tests: 158, Assertions: 170, Skipped: 1.
bash-4.4#
