
How to run drupal related modules test cases (Unit/Functional/Intergration).
-------------

Summary :-

    To run test cases in drupal module, we need drupal core package and drupal complete framework which includes a database, apache server and core package itself.
    There are 3 type of tests in drupal unit, functional, integration. For unit tests, we don't need drupal full framework like database.
    Unit tests don't use database.
*************************

Copy following files into the VM that is needed to run docker file successfully.
    1) automate_drupal.sh.txt
    2) Dockerfile.drupal.ubi
    3) drupal.zip
    4) drupal_schema.sql

Rename following 2 files:-
    # cp Dockerfile.drupal.ubi Dockerfile
    # cp automate_drupal.sh.txt automate_drupal.sh
    # chmod +x automate_drupal.sh

Now create an image from dockerfile (Dockerfile.drupal.ubi i.e Dockerfile)
     # docker build -t drupal_image .
     # docker images

Then run a container using that image.
    # docker run -it -d drupal_image /bin/bash
    # docker ps
    # docker exec -it a025d0a771a8 /bin/bash

Live drupal webserver will be available at http://<ip>:8081

After that we need to run below command inside the container. Run it in single command. Step 1 will take some time to exec.

Step 1:-
    su - postgres -c 'if [[ $(psql -l | grep dru2_pg) ]]; then     echo "Database already configured..."; else    /usr/pgsql-13/bin/pg_ctl -D /var/lib/pgsql/13/data/ start;     /usr/pgsql-13/bin/createdb -T template0 dru2_pg;     psql dru2_pg < /opt/app-root/src/drupal_schema.sql; fi'

Step 2:-
    /usr/sbin/httpd -k start;

step 3 Go to :-
    # cd /opt/app-root/src/drupal/modules

Clone the module which you wanted to test :-

/usr/sbin/httpd -k start

export PACKAGE_NAME=libraries

cd /opt/app-root/src/drupal/modules
git clone  https://git.drupalcode.org/project/$PACKAGE_NAME
cd $PACKAGE_NAME
git checkout 8.x-3.0-beta1

cd /opt/app-root/src/drupal/core/
../vendor/bin/drush pm:enable $PACKAGE_NAME

RUN TEST:---

# ../vendor/phpunit/phpunit/phpunit ../modules/$PACKAGE_NAME/tests
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/libraries/tests
.........................                                         25 / 25 (100%)

Time: 58.19 seconds, Memory: 4.00 MB

OK (25 tests, 48 assertions)

Remaining deprecation notices (1)

  1x: Drupal\Tests\BrowserTestBase::$defaultTheme is required in drupal:9.0.0 when using an install profile that does not set a default theme. See https://www.drupal.org/node/3083055, which includes recommendations on which theme to use.
    1x in DefinitionDiscoveryFactoryTest::testDiscovery from Drupal\Tests\libraries\Functional\ExternalLibrary\Definition

# ../vendor/phpunit/phpunit/phpunit ../modules/$PACKAGE_NAME/tests/src/Unit
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/libraries/tests/src/Unit
.......                                                             7 / 7 (100%)

Time: 925 ms, Memory: 4.00 MB

OK (7 tests, 7 assertions)
# ../vendor/phpunit/phpunit/phpunit ../modules/$PACKAGE_NAME/tests/src/Functional
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/libraries/tests/src/Functional
.                                                                   1 / 1 (100%)

Time: 14.77 seconds, Memory: 4.00 MB

OK (1 test, 10 assertions)

Remaining deprecation notices (1)

  1x: Drupal\Tests\BrowserTestBase::$defaultTheme is required in drupal:9.0.0 when using an install profile that does not set a default theme. See https://www.drupal.org/node/3083055, which includes recommendations on which theme to use.
    1x in DefinitionDiscoveryFactoryTest::testDiscovery from Drupal\Tests\libraries\Functional\ExternalLibrary\Definition

# ../vendor/phpunit/phpunit/phpunit ../modules/$PACKAGE_NAME/tests/src/Kernel
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/libraries/tests/src/Kernel
.................                                                 17 / 17 (100%)

Time: 43.72 seconds, Memory: 4.00 MB

OK (17 tests, 31 assertions)
