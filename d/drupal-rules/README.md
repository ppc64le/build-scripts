
How to run drupal related modules test cases (Unit/Functional/Intergration).
-------------

Summary :-
    
    To run test cases in drupal module we need drupal core package and drupal complete framework which incluse one database,apache server,and core package itself.    
    There are 3 type of tests in drupal unit,functional,intergration. For unit test we dont need drupal full framework like database.
    Unit test does not use database testing.
    
    9.4.x version is needed to run drupal-rules 8.x-3.x successfully. 
    For drupal 9.4.x    
    Remove existing drupal folder from directory /opt/app-root/src/drupal and clone the 9.4.x version.
        #  git clone https://github.com/drupal/drupal  
        #  cd /opt/app-root/src/drupal/core
        #  cp phpunit.xml.dist phpunit.xml
    Edit the phpunit.xml file to update database url and apache server url.
    <env name="SIMPLETEST_BASE_URL" value="http://0.0.0.0:8081"/>
    <env name="SIMPLETEST_DB" value="pgsql://postgres:postgres@localhost/dru2_pg"/>
 
-----------------

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

Live drupal webserver will be available at http://<ip>:8081

After that we need to run below command inside container.Run it in single command . Step 1 will take sometime to exec. 

Step 1:- 

    su - postgres -c 'if [[ $(psql -l | grep dru2_pg) ]]; then     echo "Database already configured..."; else    /usr/pgsql-13/bin/pg_ctl -D /var/lib/pgsql/13/data/ start;     /usr/pgsql-13/bin/createdb -T template0 dru2_pg;     psql dru2_pg < /opt/app-root/src/drupal_schema.sql; fi'

Step 2:-

    /usr/sbin/httpd -k start;


Go to :-

    #cd /opt/app-root/src/drupal/modules

Clone the module which you wanted to test :-

    #git clone  https://git.drupalcode.org/project/rules
    #git checkout <versions>   
  
Follow automate_drupal.sh for more detail:-
  
    #cd /opt/app-root/src/drupal
    
     bash-4.4#yum install -y git php php-json php-dom php-mbstring zip unzip gd gd-devel php-gd php-pdo php-mysqlnd
     bash-4.4#php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
     bash-4.4#composer require --dev phpunit/phpunit --with-all-dependencies ^8  --no-interaction

     bash-4.4# composer install
     bash-4.4# composer require 'drupal/typed_data:^1.0@beta'
     bash-4.4# composer require drupal/console:~1.0 --prefer-dist --optimize-autoloader --sort-packages
    
    #cd /opt/app-root/src/drupal/modules/rules
    bash-4.4# pwd
    /opt/app-root/src/drupal/modules/rules

    #composer require --dev drush/drush
    bash-4.4# ./vendor/bin/drush pm:enable   

    cd /opt/app-root/src/drupal/core
    bash-4.4# pwd
      /opt/app-root/src/drupal/core
      
 
RUN TESTS:- 
----------

To run unit tests :-      

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/rules/tests/src/Unit/
    
To run Functional tests :-      

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/rules/tests/src/Functional
    
To run Kernel/Integration tests :- 
 
    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/rules/tests/src/Kernel/

To run FunctionalJavascript tests :- 

    bash-4.4#  ../vendor/phpunit/phpunit/phpunit ../modules/rules/tests/src/FunctionalJavascript/
   
 
    
    
Testcase Output :-
--------------------------------
 

 bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/rules/tests/src/FunctionalJavascript/
PHPUnit 8.5.21 by Sebastian Bergmann and contributors.

Testing ../modules/rules/tests/src/FunctionalJavascript/
S                                                                   1 / 1 (100%)

Time: 26.41 seconds, Memory: 4.00 MB

OK, but incomplete, skipped, or risky tests!
Tests: 1, Assertions: 1, Skipped: 1.
bash-4.4#

-------------


bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/rules/tests/src/Kernel/

PHPUnit 8.5.21 by Sebastian Bergmann and contributors.

Testing ../modules/rules/tests/src/Kernel/
......................................................            54 / 54 (100%)

Time: 3.18 minutes, Memory: 8.00 MB

OK (54 tests, 351 assertions)
bash-4.4#

--------------

Functional test :-  40 mins to complete
--------------------
Edit :- phpunit.xml


    <env name="SIMPLETEST_BASE_URL" value="http://0.0.0.0:8081"/>
    
    <env name="SIMPLETEST_DB" value="pgsql://postgres:postgres@localhost/dru2_pg"/>

--------------------


bash-4.4# pwd
/opt/app-root/src/drupal/core
bash-4.4# cd ..
bash-4.4# pwd
/opt/app-root/src/drupal
bash-4.4# ls
INSTALL.txt  autoload.php  composer.json  core               index.php  profiles    sites   update.php  web.config
README.md    composer      composer.lock  example.gitignore  modules    robots.txt  themes  vendor
bash-4.4# cd co
bash: cd: co: No such file or directory
bash-4.4# cd core/
bash-4.4# ls
CHANGELOG.txt       INSTALL.txt      assets         core.libraries.yml            includes     package.json       rebuild.php
COPYRIGHT.txt       LICENSE.txt      authorize.php  core.link_relation_types.yml  install.php  phpcs.xml.dist     scripts
INSTALL.mysql.txt   MAINTAINERS.txt  composer.json  core.services.yml             lib          phpunit.xml.dist   tests
INSTALL.pgsql.txt   UPDATE.txt       config         drupalci.yml                  misc         postcss.config.js  themes
INSTALL.sqlite.txt  USAGE.txt        core.api.php   globals.api.php               modules      profiles           yarn.lock
bash-4.4# cp phpunit.xml.dist phpunit.xml
bash-4.4# ls
CHANGELOG.txt       INSTALL.txt      assets         core.libraries.yml            includes     package.json       profiles     yarn.lock
COPYRIGHT.txt       LICENSE.txt      authorize.php  core.link_relation_types.yml  install.php  phpcs.xml.dist     rebuild.php
INSTALL.mysql.txt   MAINTAINERS.txt  composer.json  core.services.yml             lib          phpunit.xml        scripts
INSTALL.pgsql.txt   UPDATE.txt       config         drupalci.yml                  misc         phpunit.xml.dist   tests
INSTALL.sqlite.txt  USAGE.txt        core.api.php   globals.api.php               modules      postcss.config.js  themes
bash-4.4# vim phpunit.xml
bash-4.4# ls
CHANGELOG.txt       INSTALL.txt      assets         core.libraries.yml            includes     package.json       profiles     yarn.lock
COPYRIGHT.txt       LICENSE.txt      authorize.php  core.link_relation_types.yml  install.php  phpcs.xml.dist     rebuild.php
INSTALL.mysql.txt   MAINTAINERS.txt  composer.json  core.services.yml             lib          phpunit.xml        scripts
INSTALL.pgsql.txt   UPDATE.txt       config         drupalci.yml                  misc         phpunit.xml.dist   tests
INSTALL.sqlite.txt  USAGE.txt        core.api.php   globals.api.php               modules      postcss.config.js  themes
bash-4.4# pwd
/opt/app-root/src/drupal/core

-----------
bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/rules/tests/src/Functional
PHPUnit 8.5.21 by Sebastian Bergmann and contributors.

Testing ../modules/rules/tests/src/Functional
................................................................. 65 / 90 ( 72%)
.........................                                         90 / 90 (100%)

Time: 39.63 minutes, Memory: 8.00 MB

OK (90 tests, 1015 assertions)

-----------


Unit test case:-

----------

[root@Power-vm-rhel81 core]# cd ..
 
[root@Power-vm-rhel81 core]# composer require drupal/console:~1.0 \
--prefer-dist \
--optimize-autoloader \
--sort-packages

[root@Power-vm-rhel81 drupal]#  composer require 'drupal/typed_data:^1.0@beta'
./composer.json has been updated
Running composer update drupal/typed_data
> Drupal\Composer\Composer::ensureComposerVersion
Loading composer repositories with package information
Updating dependencies
Lock file operations: 1 install, 1 update, 0 removals
  - Upgrading drupal/core (9.4.x-dev 5ee7c27 => 9.4.x-dev 938a9c8)
  - Locking drupal/typed_data (1.0.0-beta1)
Writing lock file
Installing dependencies from lock file (including require-dev)
Package operations: 1 install, 1 update, 0 removals
  - Downloading drupal/typed_data (1.0.0-beta1)
  - Upgrading drupal/core (9.4.x-dev 5ee7c27 => 9.4.x-dev 938a9c8): Source already present
  - Installing drupal/typed_data (1.0.0-beta1): Extracting archive
Package doctrine/reflection is abandoned, you should avoid using it. Use roave/better-reflection instead.
Package webmozart/path-util is abandoned, you should avoid using it. Use symfony/filesystem instead.
Package phpunit/php-token-stream is abandoned, you should avoid using it. No replacement was suggested.
Generating autoload files
> Drupal\Core\Composer\Composer::preAutoloadDump
Hardening vendor directory with .htaccess and web.config files.
77 packages you are using are looking for funding.
Use the `composer fund` command to find out more!
Cleaning installed packages.
> Drupal\Composer\Composer::generateMetapackages
Updated metapackage file composer/Metapackage/CoreRecommended/composer.json.
If you make a patch, ensure that the files above are included.
[root@Power-vm-rhel81 drupal]# cd core/


-------

[root@Power-vm-rhel81 core]# ../vendor/phpunit/phpunit/phpunit ../modules/rules/tests/src/Unit/
PHPUnit 8.5.21 by Sebastian Bergmann and contributors.

Testing ../modules/rules/tests/src/Unit/
...............................................................  63 / 269 ( 23%)
............................................................... 126 / 269 ( 46%)
............................................................... 189 / 269 ( 70%)
............................................................... 252 / 269 ( 93%)
.................                                               269 / 269 (100%)

Time: 11.76 seconds, Memory: 116.00 MB

OK (269 tests, 819 assertions)
[root@Power-vm-rhel81 core]#

-------------


Note:-
----------

https://deninet.com/blog/2019/01/13/writing-automated-tests-drupal-8-part-2-functional-tests
https://deninet.com/blog/2018/12/31/writing-automated-tests-drupal-8-part-1-test-types-and-set