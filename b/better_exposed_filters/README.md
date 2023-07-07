How to run drupal related modules test cases.
Summary :-

To run test cases in drupal module we need build drupal core package and drupal complete framework which include one database,apache server,and core package itself.
There are 3 type of tests in drupal unit,functional,intergration. For unit test we dont need drupal full framework like database.
Unit test does not use database testing.
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
Live drupal webserver will be available at http://:8081

After that we need to run below command inside container.Run it in single command . Step 1 will take sometime to exec.

Step 1:-

su - postgres -c 'if [[ $(psql -l | grep dru2_pg) ]]; then     echo "Database already configured..."; else    /usr/pgsql-13/bin/pg_ctl -D /var/lib/pgsql/13/data/ start;     /usr/pgsql-13/bin/createdb -T template0 dru2_pg;     psql dru2_pg < /opt/app-root/src/drupal_schema.sql; fi'
Step 2:-

/usr/sbin/httpd -k start;
Go to :-

#cd /opt/app-root/src/drupal/modules
Clone the module which you wanted to test :-

#git clone https://git.drupalcode.org/project/better_exposed_filters.git
#git checkout <versions>   
Follow automate_drupal.sh for more detail:-

#cd /opt/app-root/src/drupal

 bash-4.4#yum install -y git php php-json php-dom php-mbstring zip unzip gd gd-devel php-gd php-pdo php-mysqlnd
 bash-4.4#php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
 bash-4.4#composer require --dev phpunit/phpunit --with-all-dependencies ^8  --no-interaction

 bash-4.4# composer install

#cd /opt/app-root/src/drupal/modules/better_exposed_filters
bash-4.4# pwd
/opt/app-root/src/drupal/modules/better_exposed_filters

#composer require --dev drush/drush
bash-4.4# ./vendor/bin/drush pm:enable

cd /opt/app-root/src/drupal/core
bash-4.4# pwd
  /opt/app-root/src/drupal/core
RUN Test Kernel/Functional:-
bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/better_exposed_filters/tests/
Test output
bash-4.4# pwd /opt/app-root/src/drupal bash-4.4# composer install

Drupal\Composer\Composer::ensureComposerVersion Installing dependencies from lock file (including require-dev) Verifying lock file contents can be installed on current platform. Nothing to install, update or remove Package doctrine/reflection is abandoned, you should avoid using it. Use roave/better-reflection instead. Package webmozart/path-util is abandoned, you should avoid using it. Use symfony/filesystem instead. Generating autoload files Drupal\Core\Composer\Composer::preAutoloadDump Hardening vendor directory with .htaccess and web.config files. 82 packages you are using are looking for funding. Use the composer fund command to find out more! drupal/drupal: This package is meant for core development, and not intended to be used for production sites. See: https://www.drupal.org/node/3082474 Cleaning installed packages. bash-4.4# cd core/ bash-4.4# clear bash-4.4# pwd /opt/app-root/src/drupal/core




bash-4.4# ../vendor/bin/phpunit ../modules/better_exposed_filters/tests/src/Unit
PHPUnit 8.5.27 #StandWithUkraine

Testing ../modules/better_exposed_filters/tests/src/Unit
.................                                                 17 / 17 (100%)

Time: 2.19 seconds, Memory: 4.00 MB

OK (17 tests, 17 assertions)

Remaining self deprecation notices (17)

  17x: Drupal\Tests\UnitTestCase::assertArrayEquals() is deprecated in drupal:9.1.0 and is removed from drupal:10.0.0. Use ::assertEquals(), ::assertEqualsCanonicalizing(), or ::assertSame() instead. See https://www.drupal.org/node/3136304
    6x in BetterExposedFiltersHelperUnitTest::testRewriteOptions from Drupal\Tests\better_exposed_filters\Unit
    4x in BetterExposedFiltersHelperUnitTest::testRewriteTaxonomy from Drupal\Tests\better_exposed_filters\Unit
    3x in BetterExposedFiltersHelperUnitTest::testRewriteReorderOptions from Drupal\Tests\better_exposed_filters\Unit
    3x in BetterExposedFiltersHelperUnitTest::testSortOptions from Drupal\Tests\better_exposed_filters\Unit
    1x in BetterExposedFiltersHelperUnitTest::testSortNestedOptions from Drupal\Tests\better_exposed_filters\Unit
	
	bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/better_exposed_filters/tests
PHPUnit 8.5.27 #StandWithUkraine

Testing ../modules/better_exposed_filters/tests
SSS..................................                             37 / 37 (100%)

Time: 4.32 minutes, Memory: 6.00 MB

OK, but incomplete, skipped, or risky tests!
Tests: 37, Assertions: 259, Skipped: 3.

Remaining self deprecation notices (42)

  17x: Drupal\Tests\UnitTestCase::assertArrayEquals() is deprecated in drupal:9.1.0 and is removed from drupal:10.0.0. Use ::assertEquals(), ::assertEqualsCanonicalizing(), or ::assertSame() instead. See https://www.drupal.org/node/3136304
    6x in BetterExposedFiltersHelperUnitTest::testRewriteOptions from Drupal\Tests\better_exposed_filters\Unit
    4x in BetterExposedFiltersHelperUnitTest::testRewriteTaxonomy from Drupal\Tests\better_exposed_filters\Unit
    3x in BetterExposedFiltersHelperUnitTest::testRewriteReorderOptions from Drupal\Tests\better_exposed_filters\Unit
    3x in BetterExposedFiltersHelperUnitTest::testSortOptions from Drupal\Tests\better_exposed_filters\Unit
    1x in BetterExposedFiltersHelperUnitTest::testSortNestedOptions from Drupal\Tests\better_exposed_filters\Unit

  4x: AssertLegacyTrait::assertEqual() is deprecated in drupal:8.0.0 and is removed from drupal:10.0.0. Use $this->assertEquals() instead. See https://www.drupal.org/node/3129738
    1x in FilterWidgetKernelTest::testSortFilterOptions from Drupal\Tests\better_exposed_filters\Kernel\Plugin\filter
    1x in SortWidgetKernelTest::testCombineSortOptions from Drupal\Tests\better_exposed_filters\Kernel\Plugin\sort
    1x in SortWidgetKernelTest::testCombineRewriteSortOptions from Drupal\Tests\better_exposed_filters\Kernel\Plugin\sort
    1x in SortWidgetKernelTest::testResetSortOptions from Drupal\Tests\better_exposed_filters\Kernel\Plugin\sort

  3x: The Drupal\Tests\better_exposed_filters\FunctionalJavascript\BetterExposedFiltersTest::$modules property must be declared protected. See https://www.drupal.org/node/2909426
    3x in DrupalListener::startTest from Drupal\Tests\Listeners

  3x: The Drupal\Tests\better_exposed_filters\Kernel\Plugin\sort\SortWidgetKernelTest::$modules property must be declared protected. See https://www.drupal.org/node/2909426
    3x in DrupalListener::startTest from Drupal\Tests\Listeners

  2x: The Drupal\Tests\better_exposed_filters\Kernel\BetterExposedFiltersKernelTest::$modules property must be declared protected. See https://www.drupal.org/node/2909426
    2x in DrupalListener::startTest from Drupal\Tests\Listeners

  2x: The Drupal\Tests\better_exposed_filters\Kernel\Plugin\filter\FilterWidgetKernelTest::$modules property must be declared protected. See https://www.drupal.org/node/2909426
    2x in DrupalListener::startTest from Drupal\Tests\Listeners

  2x: The Drupal\Tests\better_exposed_filters\Kernel\Plugin\filter\HiddenFilterWidgetKernelTest::$modules property must be declared protected. See https://www.drupal.org/node/2909426
    2x in DrupalListener::startTest from Drupal\Tests\Listeners

  2x: The Drupal\Tests\better_exposed_filters\Kernel\Plugin\filter\RadioButtonsFilterWidgetKernelTest::$modules property must be declared protected. See https://www.drupal.org/node/2909426
    2x in DrupalListener::startTest from Drupal\Tests\Listeners

  1x: AssertLegacyTrait::assertNotEqual() is deprecated in drupal:8.0.0 and is removed from drupal:10.0.0. Use $this->assertNotEquals() instead. See https://www.drupal.org/node/3129738
    1x in FilterWidgetKernelTest::testSortFilterOptions from Drupal\Tests\better_exposed_filters\Kernel\Plugin\filter

  1x: The Drupal\Tests\better_exposed_filters\Kernel\Plugin\filter\LinksFilterWidgetKernelTest::$modules property must be declared protected. See https://www.drupal.org/node/2909426
    1x in DrupalListener::startTest from Drupal\Tests\Listeners

  1x: The Drupal\Tests\better_exposed_filters\Kernel\Plugin\filter\SingleFilterWidgetKernelTest::$modules property must be declared protected. See https://www.drupal.org/node/2909426
    1x in DrupalListener::startTest from Drupal\Tests\Listeners

  1x: The Drupal\Tests\better_exposed_filters\Kernel\Plugin\pager\LinksPagerWidgetKernelTest::$modules property must be declared protected. See https://www.drupal.org/node/2909426
    1x in DrupalListener::startTest from Drupal\Tests\Listeners

  1x: The Drupal\Tests\better_exposed_filters\Kernel\Plugin\pager\RadioButtonsPagerWidgetKernelTest::$modules property must be declared protected. See https://www.drupal.org/node/2909426
    1x in DrupalListener::startTest from Drupal\Tests\Listeners

  1x: The Drupal\Tests\better_exposed_filters\Kernel\Plugin\sort\LinksSortWidgetKernelTest::$modules property must be declared protected. See https://www.drupal.org/node/2909426
    1x in DrupalListener::startTest from Drupal\Tests\Listeners

  1x: The Drupal\Tests\better_exposed_filters\Kernel\Plugin\sort\RadioButtonsSortWidgetKernelTest::$modules property must be declared protected. See https://www.drupal.org/node/2909426
    1x in DrupalListener::startTest from Drupal\Tests\Listeners
	
	script output:
	**************************************
	Cloning into 'better_exposed_filters'...
remote: Enumerating objects: 3902, done.
remote: Counting objects: 100% (161/161), done.
remote: Compressing objects: 100% (83/83), done.
remote: Total 3902 (delta 93), reused 129 (delta 73), pack-reused 3741
Receiving objects: 100% (3902/3902), 711.94 KiB | 5.93 MiB/s, done.
Resolving deltas: 100% (2253/2253), done.
Note: switching to '8.x-5.0'.

You are in 'detached HEAD' state. You can look around, make experimental
changes and commit them, and you can discard any commits you make in this
state without impacting any branches by switching back to a branch.

If you want to create a new branch to retain commits you create, you may
do so (now or later) by using -c with the switch command. Example:

  git switch -c <new-branch-name>

Or undo this operation with:

  git switch -

Turn off this advice by setting config variable advice.detachedHead to false

HEAD is now at 0225b9d Issue #3182069 by vetal4ik, Yury N, pareshpatel, aludescher: Date picker no longer works with date range filters
PHP Warning:  PHP Startup: Unable to load dynamic library 'mongodb.so' (tried: /usr/lib64/php/modules/mongodb.so (/usr/lib64/php/modules/mongodb.so: undefined symbol: _zval_ptr_dtor), /usr/lib64/php/modules/mongodb.so.so (/usr/lib64/php/modules/mongodb.so.so: cannot open shared object file: No such file or directory)) in Unknown on line 0
PHP Warning:  PHP Startup: Unable to load dynamic library 'mongodb.so' (tried: /usr/lib64/php/modules/mongodb.so (/usr/lib64/php/modules/mongodb.so: undefined symbol: _zval_ptr_dtor), /usr/lib64/php/modules/mongodb.so.so (/usr/lib64/php/modules/mongodb.so.so: cannot open shared object file: No such file or directory)) in Unknown on line 0
PHP Warning:  PHP Startup: Unable to load dynamic library 'mongodb.so' (tried: /usr/lib64/php/modules/mongodb.so (/usr/lib64/php/modules/mongodb.so: undefined symbol: _zval_ptr_dtor), /usr/lib64/php/modules/mongodb.so.so (/usr/lib64/php/modules/mongodb.so.so: cannot open shared object file: No such file or directory)) in Unknown on line 0
PHP Warning:  PHP Startup: Unable to load dynamic library 'mongodb.so' (tried: /usr/lib64/php/modules/mongodb.so (/usr/lib64/php/modules/mongodb.so: undefined symbol: _zval_ptr_dtor), /usr/lib64/php/modules/mongodb.so.so (/usr/lib64/php/modules/mongodb.so.so: cannot open shared object file: No such file or directory)) in Unknown on line 0
PHP Warning:  PHP Startup: Unable to load dynamic library 'mongodb.so' (tried: /usr/lib64/php/modules/mongodb.so (/usr/lib64/php/modules/mongodb.so: undefined symbol: _zval_ptr_dtor), /usr/lib64/php/modules/mongodb.so.so (/usr/lib64/php/modules/mongodb.so.so: cannot open shared object file: No such file or directory)) in Unknown on line 0
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/better_exposed_filters/tests/src/Unit
.................                                                 17 / 17 (100%)

Time: 662 ms, Memory: 4.00 MB

OK (17 tests, 17 assertions)
------------------better_exposed_filters:install_&_test_both_success-------------------------

