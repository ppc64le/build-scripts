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
docker run -itd --name poll drupal_image bash
```
2) Log on to the container:
```bash
docker exec -it poll bash
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
export PACKAGE_NAME=poll

cd /opt/app-root/src/drupal/modules
git clone  https://git.drupalcode.org/project/$PACKAGE_NAME
cd $PACKAGE_NAME
git checkout 8.x-1.4

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

Testing ../modules/poll/tests
..E................S..                                            22 / 22 (100%)

Time: 13.28 minutes, Memory: 4.00 MB

There was 1 error:

1) Drupal\Tests\poll\Functional\PollCreateTest::testPollClose
Exception: Notice: Trying to access array offset on value of type bool
template_preprocess_poll_meter()() (Line: 169)


/opt/app-root/src/drupal/core/lib/Drupal/Core/Test/HttpClientMiddleware/TestHttpClientMiddleware.php:51
/opt/app-root/src/drupal/vendor/guzzlehttp/promises/src/Promise.php:204
/opt/app-root/src/drupal/vendor/guzzlehttp/promises/src/Promise.php:153
/opt/app-root/src/drupal/vendor/guzzlehttp/promises/src/TaskQueue.php:48
/opt/app-root/src/drupal/vendor/guzzlehttp/promises/src/Promise.php:248
/opt/app-root/src/drupal/vendor/guzzlehttp/promises/src/Promise.php:224
/opt/app-root/src/drupal/vendor/guzzlehttp/promises/src/Promise.php:269
/opt/app-root/src/drupal/vendor/guzzlehttp/promises/src/Promise.php:226
/opt/app-root/src/drupal/vendor/guzzlehttp/promises/src/Promise.php:62
/opt/app-root/src/drupal/vendor/guzzlehttp/guzzle/src/Client.php:182
/opt/app-root/src/drupal/vendor/fabpot/goutte/Goutte/Client.php:180
/opt/app-root/src/drupal/vendor/symfony/browser-kit/Client.php:318
/opt/app-root/src/drupal/vendor/behat/mink-browserkit-driver/src/BrowserKitDriver.php:145
/opt/app-root/src/drupal/vendor/behat/mink/src/Session.php:148
/opt/app-root/src/drupal/core/tests/Drupal/Tests/UiHelperTrait.php:327
/opt/app-root/src/drupal/modules/poll/tests/src/Functional/PollCreateTest.php:73

ERRORS!
Tests: 22, Assertions: 895, Errors: 1, Skipped: 1.
```