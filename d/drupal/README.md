
How to run drupal related modules test cases (Unit/Functional/Intergration).
-------------

Summary :-
    
    To run test cases in drupal module we need drupal core package and drupal complete framework which incluse one database,apache server,and core package itself.
    There are 3 type of tests in drupal unit,functional,intergration. For unit test we dont need drupal full framework like database.
    Unit test does not use database testing.
 
*************************

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

    #git clone  https://git.drupalcode.org/project/cshs 
    #git checkout <versions>   
  
Follow automate_drupal.sh for more detail:-
  
    #cd /opt/app-root/src/drupal
    
     bash-4.4#yum install -y git php php-json php-dom php-mbstring zip unzip gd gd-devel php-gd php-pdo php-mysqlnd
     bash-4.4#php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
     bash-4.4#composer require --dev phpunit/phpunit --with-all-dependencies ^8  --no-interaction

     bash-4.4# composer install
    
    #cd /opt/app-root/src/drupal/modules/cshs
    bash-4.4# pwd
    /opt/app-root/src/drupal/modules/cshs

    #composer require --dev drush/drush
    bash-4.4# ./vendor/bin/drush pm:enable   

    cd /opt/app-root/src/drupal/core
    bash-4.4# pwd
      /opt/app-root/src/drupal/core
      
 
RUN TESTS:- 
----------

To run unit tests :-      

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/cshs/tests/src/Unit
    
To run Functional tests :-      

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/cshs/tests/src/Functional/
   
Run all tests in one go :-
    
    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/cshs/tests
    
    
Testcase Output :-
--------------------------------

[root@Power-vm-rhel81 ~]# docker ps
CONTAINER ID   IMAGE                                     COMMAND                  CREATED        STATUS        PORTS                NAMES
604cf8496284   registry.access.redhat.com/ubi8/ubi:8.5   "/bin/bash"              2 hours ago    Up 2 hours                         agitated_brahmagupta
69cabf536f6f   drupal_image                              "/bin/bash -c /bin/b…"   17 hours ago   Up 17 hours   8080/tcp, 8443/tcp   bold_yalow
[root@Power-vm-rhel81 ~]# docker exec -it 69cabf536f6f /bin/bash
bash-4.4# ls
automate_drupal.sh  drupal  drupal.zip  drupal_schema.sql  error_log.txt
bash-4.4# cd drupal
bash-4.4# ls
INSTALL.txt  autoload.php  composer-setup.php  composer.lock  example.gitignore  modules   robots.txt  themes      vendor
README.txt   composer      composer.json       core           index.php          profiles  sites       update.php  web.config
bash-4.4# pwd
/opt/app-root/src/drupal
bash-4.4#

bash-4.4# composer install

composer/installers contains a Composer plugin which is currently not in your allow-plugins config. See https://getcomposer.org/allow-plugins
Do you trust "composer/installers" to execute code and wish to enable it now? (writes "allow-plugins" to composer.json) [y,n,d,?] y
drupal/core-project-message contains a Composer plugin which is currently not in your allow-plugins config. See https://getcomposer.org/allow-plugins
Do you trust "drupal/core-project-message" to execute code and wish to enable it now? (writes "allow-plugins" to composer.json) [y,n,d,?] y
drupal/core-vendor-hardening contains a Composer plugin which is currently not in your allow-plugins config. See https://getcomposer.org/allow-plugins
Do you trust "drupal/core-vendor-hardening" to execute code and wish to enable it now? (writes "allow-plugins" to composer.json) [y,n,d,?] y
y> Drupal\Composer\Composer::ensureComposerVersion
Installing dependencies from lock file (including require-dev)
Verifying lock file contents can be installed on current platform.

Nothing to install, update or remove
Package container-interop/container-interop is abandoned, you should avoid using it. Use psr/container instead.
Package doctrine/reflection is abandoned, you should avoid using it. Use roave/better-reflection instead.
Package phpunit/php-token-stream is abandoned, you should avoid using it. No replacement was suggested.
Generating autoload files
> Drupal\Core\Composer\Composer::preAutoloadDump
Hardening vendor directory with .htaccess and web.config files.
67 packages you are using are looking for funding.
Use the `composer fund` command to find out more!
drupal/drupal: This package is meant for core development,
               and not intended to be used for production sites.
               See: https://www.drupal.org/node/3082474
Cleaning vendor directory.

bash-4.4# pwd
/opt/app-root/src/drupal
bash-4.4# cd core/
bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/cshs/tests/src/Unit
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/cshs/tests/src/Unit
..............                                                    14 / 14 (100%)

Time: 2.59 seconds, Memory: 4.00 MB

OK (14 tests, 110 assertions)
bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/cshs/tests/src/Functional/
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/cshs/tests/src/Functional/
.                                                                   1 / 1 (100%)

Time: 41.36 seconds, Memory: 4.00 MB

OK (1 test, 9 assertions)    
-------------


Note:-
----------

https://deninet.com/blog/2019/01/13/writing-automated-tests-drupal-8-part-2-functional-tests
https://deninet.com/blog/2018/12/31/writing-automated-tests-drupal-8-part-1-test-types-and-set

drupal-cshs can also work fine with drupal 9.4.x:-

-------
  9.4.x version is needed to run drupal-rules 8.x-3.x successfully. 
    For drupal 9.4.x    
    Remove existing drupal folder from directory /opt/app-root/src/drupal and clone the 9.4.x version.
        #  git clone https://github.com/drupal/drupal  
        #   cd /opt/app-root/src/drupal/core
        #   cp phpunit.xml.dist phpunit.xml
    Edit the phpunit.xml file to update database url and apache server url.
    <env name="SIMPLETEST_BASE_URL" value="http://0.0.0.0:8081"/>
    <env name="SIMPLETEST_DB" value="pgsql://postgres:postgres@localhost/dru2_pg"/>
    
-------