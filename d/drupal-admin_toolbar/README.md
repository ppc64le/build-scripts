
How to run drupal related modules test cases (Unit/Functional/Intergration).
-------------

Summary :-

    To run test cases in drupal module we need build drupal core package and drupal complete framework which include one database,apache server,and drupal core package.
    There are 3 type of tests in drupal unit,functional,intergration. For unit test we dont need drupal full framework like database.
    Unit test does not use database testing as i tested some packages.

*************************

Copy following files From local into VM thats needed to run docker file succesfully.

    1) automate_drupal.sh.txt
    2) Dockerfile.drupal.ubi
    3) drupal.zip
    4) drupal_schema.sql

Rename 2 below files:-

    #cp Dockerfile.drupal.ubi Dockerfile
    #cp automate_drupal.sh.txt automate_drupal.sh
    #chmod +x automate_drupal.sh


Now we can create an image  using below command from dockerfile (Dockerfile.drupal.ubi i.e Dockerfile)

     #docker build -t drupal_image .
     #docker images


Then run a container using that image.

    #docker run -it -d drupal_image /bin/bash
    #docker ps
    #docker exec -it a025d0a771a8 /bin/bash

Live drupal webserver will be available at http://<ip>:8081

After that we need to run below command inside container.Run it in single command . 
Step 1 will take sometime to exec. (configuration)

Step 1:- 

    su - postgres -c 'if [[ $(psql -l | grep dru2_pg) ]]; then     echo "Database already configured..."; else    /usr/pgsql-13/bin/pg_ctl -D /var/lib/pgsql/13/data/ start;     /usr/pgsql-13/bin/createdb -T template0 dru2_pg;     psql dru2_pg < /opt/app-root/src/drupal_schema.sql; fi'

Step 2:-

    /usr/sbin/httpd -k start;


step 3 Go to :-

    #cd /opt/app-root/src/drupal/modules

Clone the module which you wanted to test :-

/usr/sbin/httpd -k start

export PACKAGE_NAME=admin_toolbar

cd /opt/app-root/src/drupal/modules
git clone  https://git.drupalcode.org/project/$PACKAGE_NAME

#Install dependency module mailsystem
git clone https://git.drupalcode.org/project/mailsystem

cd $PACKAGE_NAME
git checkout 3.0.0

cd /opt/app-root/src/drupal/core/
../vendor/bin/drush pm:enable $PACKAGE_NAME

RUN TEST:---

bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/admin_toolbar/tests/
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/admin_toolbar/tests/
...                                                                 3 / 3 (100%)

Time: 1.36 minutes, Memory: 4.00 MB

OK (3 tests, 86 assertions)
bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/admin_toolbar/tests/src/Unit
Cannot open file "../modules/admin/toolbar/tests/src/Unit.php".

bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/admin_toolbar/tests/src/Functional
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/admin_toolbar/tests/src/Functional
...                                                                 3 / 3 (100%)

Time: 1.46 minutes, Memory: 4.00 MB

OK (3 tests, 86 assertions)
#Unit test N/A.
