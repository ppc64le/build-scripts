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
docker run -itd --name svg_image_field drupal_image bash
```
2) Log on to the container:
```bash
docker exec -it svg_image_field bash
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
export PACKAGE_NAME=svg_image_field

cd /opt/app-root/src/drupal/modules
git clone  https://git.drupalcode.org/project/$PACKAGE_NAME
cd $PACKAGE_NAME
git checkout 2.1.0

cd /opt/app-root/src/drupal
composer config --no-plugins allow-plugins.composer/installers true
composer config --no-plugins allow-plugins.drupal/core-project-message true
composer config --no-plugins allow-plugins.drupal/core-vendor-hardening true
composer require enshrined/svg-sanitize

cd /opt/app-root/src/drupal/core/
../vendor/bin/drush pm:enable $PACKAGE_NAME

../vendor/phpunit/phpunit/phpunit ../modules/$PACKAGE_NAME/tests
```
Output:
```
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/svg_image_field/tests
F                                                                   1 / 1 (100%)

Time: 4.88 seconds, Memory: 4.00 MB

There was 1 failure:

1) Drupal\Tests\svg_image_field\Unit\FileValidationTest::testFileValidation
Check that <em class="placeholder">invalid_svg1.svg</em> is invalid
Failed asserting that false matches expected true.

/opt/app-root/src/drupal/modules/svg_image_field/tests/src/Unit/FileValidationTest.php:85

FAILURES!
Tests: 1, Assertions: 6, Failures: 1.
```