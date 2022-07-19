
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

    #git clone  https://git.drupalcode.org/project/redirect
    #git checkout <requestedversions>   
----  
Follow automate_drupal.sh for more detail:-(Dependes on your package which version you need to install e.g ^8,^7)
  
    #cd /opt/app-root/src/drupal
    
     bash-4.4#yum install -y git php php-json php-dom php-mbstring zip unzip gd gd-devel php-gd php-pdo php-mysqlnd
     bash-4.4#php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
     bash-4.4#composer require --dev phpunit/phpunit --with-all-dependencies ^7  --no-interaction

     bash-4.4# composer install
    
    #cd /opt/app-root/src/drupal/modules/redirect
    bash-4.4# pwd
    /opt/app-root/src/drupal/modules/redirect
optional:---
    #composer require --dev drush/drush
    bash-4.4# ./vendor/bin/drush pm:enable   
------
    cd /opt/app-root/src/drupal/core
    bash-4.4# pwd
      /opt/app-root/src/drupal/core
	  
	  
	  or can use below steps after checkout the requested version:
	  
	  cd /opt/app-root/src/drupal/core
	  composer config allow-plugins true
	  composer update --ignore-platform-req=ext-gd
	  
	  
      Note:drupal 8.9.0 used in this package.
 
RUN TESTS:- 
----------

To run unit tests :-      

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/redirect/tests/src/Unit
    
To run Functional tests :-      

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/redirect/tests/src/Functional
To run Kernel tests :- 

	bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/redirect/tests/src/Functional
	
To run FunctionalJavascript tests :- 

	bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/redirect/tests/src/Functional
   
Run all tests in one go :-
    
    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/redirect/tests
    
Testoutput:
--------------------------

PHP CodeSniffer Config installed_paths set to ../../drupal/coder/coder_sniffer,.                                                                             ./../sirbrillig/phpcs-variable-analysis,../../slevomat/coding-standard
> Drupal\Composer\Composer::generateMetapackages
Updated metapackage file composer/Metapackage/CoreRecommended/composer.json.
Updated metapackage file composer/Metapackage/PinnedDevDependencies/composer.jso                                                                             n.
If you make a patch, ensure that the files above are included.
> Drupal\Composer\Composer::ensureComposerVersion
Installing dependencies from lock file (including require-dev)
Verifying lock file contents can be installed on current platform.
Nothing to install, update or remove
Package doctrine/reflection is abandoned, you should avoid using it. Use roave/b                                                                             etter-reflection instead.
Package symfony/debug is abandoned, you should avoid using it. Use symfony/error                                                                             -handler instead.
Package phpunit/php-token-stream is abandoned, you should avoid using it. No rep                                                                             lacement was suggested.
Generating autoload files
> Drupal\Core\Composer\Composer::preAutoloadDump
Hardening vendor directory with .htaccess and web.config files.
67 packages you are using are looking for funding.
Use the `composer fund` command to find out more!
drupal/drupal: This package is meant for core development,
               and not intended to be used for production sites.
               See: https://www.drupal.org/node/3082474
Cleaning vendor directory.
./composer.json has been updated
Running composer update phpunit/phpunit --with-all-dependencies
> Drupal\Composer\Composer::ensureComposerVersion
Loading composer repositories with package information
Updating dependencies
Nothing to modify in lock file
Writing lock file
Installing dependencies from lock file (including require-dev)
Nothing to install, update or remove
Package doctrine/reflection is abandoned, you should avoid using it. Use roave/b                                                                             etter-reflection instead.
Package symfony/debug is abandoned, you should avoid using it. Use symfony/error                                                                             -handler instead.
Package phpunit/php-token-stream is abandoned, you should avoid using it. No rep                                                                             lacement was suggested.
Generating autoload files
> Drupal\Core\Composer\Composer::preAutoloadDump
Hardening vendor directory with .htaccess and web.config files.
67 packages you are using are looking for funding.
Use the `composer fund` command to find out more!
Cleaning vendor directory.
> Drupal\Composer\Composer::generateMetapackages
Updated metapackage file composer/Metapackage/DevDependencies/composer.json.
If you make a patch, ensure that the files above are included.
Cloning into 'redirect'...
remote: Enumerating objects: 3649, done.
remote: Counting objects: 100% (224/224), done.
remote: Compressing objects: 100% (123/123), done.
remote: Total 3649 (delta 88), reused 224 (delta 88), pack-reused 3425
Receiving objects: 100% (3649/3649), 746.46 KiB | 3.95 MiB/s, done.
Resolving deltas: 100% (2083/2083), done.
Note: switching to '8.x-1.6'.

You are in 'detached HEAD' state. You can look around, make experimental
changes and commit them, and you can discard any commits you make in this
state without impacting any branches by switching back to a branch.

If you want to create a new branch to retain commits you create, you may
do so (now or later) by using -c with the switch command. Example:

  git switch -c <new-branch-name>

Or undo this operation with:

  git switch -

Turn off this advice by setting config variable advice.detachedHead to false

HEAD is now at 45ccc33 Issue #3135968 by Berdir: Fixing new/remaining Drupal 9 t                                                                             est fails
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/redirect/tests/src/Unit
.............                                                     13 / 13 (100%)

Time: 968 ms, Memory: 6.00 MB

OK (13 tests, 62 assertions)
------------------redirect:install_&_test_both_success-------------------------
https://git.drupalcode.org/project/redirect.git redirect
redirect  |  https://git.drupalcode.org/project/redirect.git | 8.x-1.6 | Red Hat                                                                              Enterprise Linux 8.6 (Ootpa) | GitHub  | Pass |  Both_Install_and_Test_Success

TestOutput for all tests:
Functional/Kernel/FunctionalJavascript
*********************************************************************************

bash-4.4# pwd /opt/app-root/src/drupal/core
bash-4.4# cp phpunit.xml.dist phpunit.xml
bash-4.4# vim phpunit.xml Edit it like

<env name="SIMPLETEST_BASE_URL" value="http://0.0.0.0:8081"/>
<env name="SIMPLETEST_DB" value="pgsql://postgres:postgres@localhost/dru2_pg"/>

bash-4.4# ../vendor/bin/phpunit ../modules/redirect/tests/src/Functional
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/redirect/tests/src/Functional
..............                                                    14 / 14 (100%)

Time: 8.8 minutes, Memory: 4.00 MB

OK (14 tests, 274 assertions)
bash-4.4# ../vendor/bin/phpunit ../modules/redirect/tests/src/FunctionalJavascript
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/redirect/tests/src/FunctionalJavascript
S                                                                   1 / 1 (100%)

Time: 31.37 seconds, Memory: 4.00 MB

OK, but incomplete, skipped, or risky tests!
Tests: 1, Assertions: 1, Skipped: 1.
bash-4.4# ../vendor/bin/phpunit ../modules/redirect/tests/src/Kernel
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/redirect/tests/src/Kernel
..........                                                        10 / 10 (100%)

Time: 36.37 seconds, Memory: 4.00 MB

OK (10 tests, 101 assertions)
