
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

export PACKAGE_NAME=views_slideshow

cd /opt/app-root/src/drupal/modules
git clone  https://git.drupalcode.org/project/$PACKAGE_NAME

#Install dependency module views_slideshow
git clone https://git.drupalcode.org/project/views_slideshow

cd $PACKAGE_NAME
git checkout 8.x-4.8

cd /opt/app-root/src/drupal/core/
../vendor/bin/drush pm:enable $PACKAGE_NAME

RUN TEST:---

bash-4.4#  ../vendor/phpunit/phpunit/phpunit ../modules/$PACKAGE_NAME/
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/views_slideshow/
..                                                                  2 / 2 (100%)

Time: 54.93 seconds, Memory: 4.00 MB

OK (2 tests, 11 assertions)

Remaining deprecation notices (8)

  4x: Support for asserting against non-boolean values in ::assertFalse is deprecated in drupal:8.8.0 and is removed from drupal:9.0.0. Use a different assert method, for example, ::assertEmpty(). See https://www.drupal.org/node/3082086
    4x in StyleSlideshowTest::testSlideshowWidgets from Drupal\views_slideshow\Tests\Plugin

  2x: Drupal\Tests\BrowserTestBase::$defaultTheme is required in drupal:9.0.0 when using an install profile that does not set a default theme. See https://www.drupal.org/node/3083055, which includes recommendations on which theme to use.
    1x in StyleSlideshowTest::testSlideshow from Drupal\views_slideshow\Tests\Plugin
    1x in StyleSlideshowTest::testSlideshowWidgets from Drupal\views_slideshow\Tests\Plugin

  2x: Support for asserting against non-boolean values in ::assertTrue is deprecated in drupal:8.8.0 and is removed from drupal:9.0.0. Use a different assert method, for example, ::assertNotEmpty(). See https://www.drupal.org/node/3082086
    2x in StyleSlideshowTest::testSlideshowWidgets from Drupal\views_slideshow\Tests\Plugin


bash-4.4#  ../vendor/phpunit/phpunit/phpunit ../modules/$PACKAGE_NAME/src/Tests/
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/views_slideshow/src/Tests/
..                                                                  2 / 2 (100%)

Time: 51.35 seconds, Memory: 4.00 MB

OK (2 tests, 11 assertions)

Remaining deprecation notices (8)

  4x: Support for asserting against non-boolean values in ::assertFalse is deprecated in drupal:8.8.0 and is removed from drupal:9.0.0. Use a different assert method, for example, ::assertEmpty(). See https://www.drupal.org/node/3082086
    4x in StyleSlideshowTest::testSlideshowWidgets from Drupal\views_slideshow\Tests\Plugin

  2x: Drupal\Tests\BrowserTestBase::$defaultTheme is required in drupal:9.0.0 when using an install profile that does not set a default theme. See https://www.drupal.org/node/3083055, which includes recommendations on which theme to use.
    1x in StyleSlideshowTest::testSlideshow from Drupal\views_slideshow\Tests\Plugin
    1x in StyleSlideshowTest::testSlideshowWidgets from Drupal\views_slideshow\Tests\Plugin

  2x: Support for asserting against non-boolean values in ::assertTrue is deprecated in drupal:8.8.0 and is removed from drupal:9.0.0. Use a different assert method, for example, ::assertNotEmpty(). See https://www.drupal.org/node/3082086
    2x in StyleSlideshowTest::testSlideshowWidgets from Drupal\views_slideshow\Tests\Plugin

bash-4.4#  ../vendor/phpunit/phpunit/phpunit ../modules/$PACKAGE_NAME/src/Tests/Plugin
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/views_slideshow/src/Tests/Plugin
..                                                                  2 / 2 (100%)

Time: 51.33 seconds, Memory: 4.00 MB

OK (2 tests, 11 assertions)

Remaining deprecation notices (8)

  4x: Support for asserting against non-boolean values in ::assertFalse is deprecated in drupal:8.8.0 and is removed from drupal:9.0.0. Use a different assert method, for example, ::assertEmpty(). See https://www.drupal.org/node/3082086
    4x in StyleSlideshowTest::testSlideshowWidgets from Drupal\views_slideshow\Tests\Plugin

  2x: Drupal\Tests\BrowserTestBase::$defaultTheme is required in drupal:9.0.0 when using an install profile that does not set a default theme. See https://www.drupal.org/node/3083055, which includes recommendations on which theme to use.
    1x in StyleSlideshowTest::testSlideshow from Drupal\views_slideshow\Tests\Plugin
    1x in StyleSlideshowTest::testSlideshowWidgets from Drupal\views_slideshow\Tests\Plugin

  2x: Support for asserting against non-boolean values in ::assertTrue is deprecated in drupal:8.8.0 and is removed from drupal:9.0.0. Use a different assert method, for example, ::assertNotEmpty(). See https://www.drupal.org/node/3082086
    2x in StyleSlideshowTest::testSlideshowWidgets from Drupal\views_slideshow\Tests\Plugin

#Unit test N/A.
