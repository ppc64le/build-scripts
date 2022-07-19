
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

export PACKAGE_NAME=contact_storage

cd /opt/app-root/src/drupal/modules
git clone  https://git.drupalcode.org/project/$PACKAGE_NAME

#clone the dependency module token
git clone  https://git.drupalcode.org/project/token

cd $PACKAGE_NAME
git checkout 8.x-1.1

cd /opt/app-root/src/drupal/core/
../vendor/bin/drush pm:enable $PACKAGE_NAME

RUN TEST:---

bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/$PACKAGE_NAME/tests
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/contact_storage/tests
........                                                            8 / 8 (100%)

Time: 4.36 minutes, Memory: 4.00 MB

OK (8 tests, 291 assertions)

Remaining deprecation notices (5)

  3x: \Drupal\Component\Utility\Unicode::strlen() is deprecated in Drupal 8.6.0 and will be removed before Drupal 9.0.0. Use mb_strlen() instead. See https://www.drupal.org/node/2850048.
    3x in ContactStorageTest::testContactStorage from Drupal\Tests\contact_storage\Functional

  2x: Drupal\Core\Field\AllowedTagsXssTrait::displayAllowedTags is deprecated in drupal:8.0.0 and is removed in drupal:9.0.0. Use \Drupal\Core\Field\FieldFilteredMarkup::displayAllowedTags() instead.
    2x in ContactStorageTest::testContactStorage from Drupal\Tests\contact_storage\Functional

bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/$PACKAGE_NAME/tests/src/Functional
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/contact_storage/tests/src/Functional
.......                                                             7 / 7 (100%)

Time: 4.26 minutes, Memory: 4.00 MB

OK (7 tests, 289 assertions)

Remaining deprecation notices (5)

  3x: \Drupal\Component\Utility\Unicode::strlen() is deprecated in Drupal 8.6.0 and will be removed before Drupal 9.0.0. Use mb_strlen() instead. See https://www.drupal.org/node/2850048.
    3x in ContactStorageTest::testContactStorage from Drupal\Tests\contact_storage\Functional

  2x: Drupal\Core\Field\AllowedTagsXssTrait::displayAllowedTags is deprecated in drupal:8.0.0 and is removed in drupal:9.0.0. Use \Drupal\Core\Field\FieldFilteredMarkup::displayAllowedTags() instead.
    2x in ContactStorageTest::testContactStorage from Drupal\Tests\contact_storage\Functional

bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/$PACKAGE_NAME/tests/src/Kernel
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/contact_storage/tests/src/Kernel
.                                                                   1 / 1 (100%)

Time: 8.42 seconds, Memory: 4.00 MB

OK (1 test, 2 assertions)

#Unit tests N/A
