## How to run Drupal modules related test cases.
Summary :-
To run test cases in drupal module we need drupal core package and drupal complete framework which include one database, apache server, and core package itself.
There are 3 type of tests in drupal unit, functional, intergration. For unit test we don't need drupal full framework like database.
Unit test does not use database testing.

### Creating a docker image to run Functional and Kernel tests:
Copy following files to a directory:
1) automate_drupal.sh.txt
2) Dockerfile.drupal.ubi
3) drupal.zip
4) drupal_schema.sql

Rename files:
```bash
mv Dockerfile.drupal.ubi Dockerfile
mv automate_drupal.sh.txt automate_drupal.sh
chmod +x automate_drupal.sh
```
Run docker build command to create the image:
```bash
docker build -t drupal_image .
```

Once the image is created, it can be used to run execute functional and kernel test cases.

### Steps to prepare for running test cases
1) Create a container using the docker image created earlier:
```bash
docker run -itd --name select_or_other drupal_image bash
```
2) Log on to the container:
```bash
docker exec -it select_or_other bash
```
3) Load the drupal DB with drupal schema:
```bash
su - postgres -c 'if [[ $(psql -l | grep dru2_pg) ]]; then     echo "Database already configured..."; else    /usr/pgsql-13/bin/pg_ctl -D /var/lib/pgsql/13/data/ start;     /usr/pgsql-13/bin/createdb -T template0 dru2_pg;     psql dru2_pg < /opt/app-root/src/drupal_schema.sql; fi'
```
4) Start the http server:
```bash
/usr/sbin/httpd -k start
```
Live drupal webserver will be available at http://localhost:8081

### Steps to run the test cases
```bash
export PACKAGE_NAME=select_or_other

cd /opt/app-root/src/drupal/modules
git clone  https://git.drupalcode.org/project/$PACKAGE_NAME
cd $PACKAGE_NAME
git checkout 8.x-1.x

cd /opt/app-root/src/drupal/core/
../vendor/bin/drush pm:enable $PACKAGE_NAME

../vendor/phpunit/phpunit/phpunit ../modules/$PACKAGE_NAME/tests
```
Output:
```
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/select_or_other/tests
..........EEEEEEEEEEEE..                                          24 / 24 (100%)

Time: 2.23 minutes, Memory: 4.00 MB

There were 12 errors:

1) Drupal\Tests\select_or_other\Unit\ListWidgetTest::testGetOptions
ReflectionException: Class Mock_AccountProxyInterface_fcc6af61 does not have a constructor, so you cannot pass any constructor arguments

/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:72
/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:61
/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:34

2) Drupal\Tests\select_or_other\Unit\ListWidgetTest::testFormElement
ReflectionException: Class Mock_AccountProxyInterface_fcc6af61 does not have a constructor, so you cannot pass any constructor arguments

/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:72
/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:61
/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:34

3) Drupal\Tests\select_or_other\Unit\ListWidgetTest::massageFormValuesReturnsValuesPassedToIt
ReflectionException: Class Mock_AccountProxyInterface_fcc6af61 does not have a constructor, so you cannot pass any constructor arguments

/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:72
/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:61
/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:34

4) Drupal\Tests\select_or_other\Unit\ListWidgetTest::massageFormValuesRemovesSelectValueIfPresent
ReflectionException: Class Mock_AccountProxyInterface_fcc6af61 does not have a constructor, so you cannot pass any constructor arguments

/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:72
/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:61
/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:34

5) Drupal\Tests\select_or_other\Unit\ListWidgetTest::massageFormValuesRemovesOtherValueIfPresent
ReflectionException: Class Mock_AccountProxyInterface_fcc6af61 does not have a constructor, so you cannot pass any constructor arguments

/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:72
/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:61
/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:34

6) Drupal\Tests\select_or_other\Unit\ListWidgetTest::massageFormValuesAddsNewValuesToAllowedValues
ReflectionException: Class Mock_AccountProxyInterface_fcc6af61 does not have a constructor, so you cannot pass any constructor arguments

/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:72
/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:61
/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:34

7) Drupal\Tests\select_or_other\Unit\ListWidgetTest::massageFormValuesDoNotAddOtherValuesToAllowedValues
ReflectionException: Class Mock_AccountProxyInterface_fcc6af61 does not have a constructor, so you cannot pass any constructor arguments

/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:72
/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:61
/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:34

8) Drupal\Tests\select_or_other\Unit\ReferenceWidgetTest::testGetOptions
ReflectionException: Class Mock_AccountProxyInterface_fcc6af61 does not have a constructor, so you cannot pass any constructor arguments

/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:72
/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:61
/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:34

9) Drupal\Tests\select_or_other\Unit\ReferenceWidgetTest::testFormElement
ReflectionException: Class Mock_AccountProxyInterface_fcc6af61 does not have a constructor, so you cannot pass any constructor arguments

/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:72
/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:61
/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:34

10) Drupal\Tests\select_or_other\Unit\ReferenceWidgetTest::testPrepareElementValuesForValidation
ReflectionException: Class Mock_AccountProxyInterface_fcc6af61 does not have a constructor, so you cannot pass any constructor arguments

/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:72
/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:61
/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:34

11) Drupal\Tests\select_or_other\Unit\ReferenceWidgetTest::testIsApplicable
ReflectionException: Class Mock_AccountProxyInterface_fcc6af61 does not have a constructor, so you cannot pass any constructor arguments

/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:72
/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:61
/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:34

12) Drupal\Tests\select_or_other\Unit\ReferenceWidgetTest::testPrepareSelectedOptions
ReflectionException: Class Mock_AccountProxyInterface_fcc6af61 does not have a constructor, so you cannot pass any constructor arguments

/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:72
/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:61
/opt/app-root/src/drupal/modules/select_or_other/tests/src/Unit/UnitTestBase.php:34

ERRORS!
Tests: 24, Assertions: 187, Errors: 12.

Remaining deprecation notices (35)

  32x: Providing settings under 'handler_settings' is deprecated in drupal:8.4.0 support for 'handler_settings' is removed from drupal:9.0.0. Move the settings in the root of the configuration array. See https://www.drupal.org/node/2870971
    32x in ReferenceTest::testEmptyOption from Drupal\Tests\select_or_other\Functional

  3x: Drupal\Tests\BrowserTestBase::$defaultTheme is required in drupal:9.0.0 when using an install profile that does not set a default theme. See https://www.drupal.org/node/3083055, which includes recommendations on which theme to use.
    1x in ListTest::testEmptyOption from Drupal\Tests\select_or_other\Functional
    1x in ListTest::testIllegalChoice from Drupal\Tests\select_or_other\Functional
    1x in ReferenceTest::testEmptyOption from Drupal\Tests\select_or_other\Functional
```
