
How to run drupal related modules test cases.
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

    #git clone https://git.drupalcode.org/project/views_infinite_scroll
    #git checkout <versions>   
  
Follow automate_drupal.sh for more detail:-
  
    #cd /opt/app-root/src/drupal
    
     bash-4.4#yum install -y git php php-json php-dom php-mbstring zip unzip gd gd-devel php-gd php-pdo php-mysqlnd
     bash-4.4#php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
     bash-4.4#composer require --dev phpunit/phpunit --with-all-dependencies ^8  --no-interaction

     bash-4.4# composer install
    
    #cd /opt/app-root/src/drupal/modules/views_infinite_scroll
    bash-4.4# pwd
    /opt/app-root/src/drupal/modules/views_infinite_scroll

    #composer require --dev drush/drush
    bash-4.4# ./vendor/bin/drush pm:enable views_infinite_scroll 

    cd /opt/app-root/src/drupal/core
    bash-4.4# pwd
      /opt/app-root/src/drupal/core
      
 
RUN Test Kernel/Functional:- 
-----------------------    

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/views_infinite_scroll/tests/
 
 
Test output
----------------

bash-4.4# pwd
/opt/app-root/src/drupal
bash-4.4# composer install
> Drupal\Composer\Composer::ensureComposerVersion
Installing dependencies from lock file (including require-dev)
Verifying lock file contents can be installed on current platform.
Nothing to install, update or remove
Package doctrine/reflection is abandoned, you should avoid using it. Use roave/better-reflection instead.
Package webmozart/path-util is abandoned, you should avoid using it. Use symfony/filesystem instead.
Generating autoload files
> Drupal\Core\Composer\Composer::preAutoloadDump
Hardening vendor directory with .htaccess and web.config files.
82 packages you are using are looking for funding.
Use the `composer fund` command to find out more!
drupal/drupal: This package is meant for core development,
               and not intended to be used for production sites.
               See: https://www.drupal.org/node/3082474
Cleaning installed packages.
bash-4.4# cd core/
bash-4.4# clear
bash-4.4# pwd
/opt/app-root/src/drupal/core

bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/views_infinite_scroll/tests/src/
PHPUnit 9.5.20 #StandWithUkraine

Warning:       Your XML configuration validates against a deprecated schema.
Suggestion:    Migrate your XML configuration using "--migrate-configuration"!

Testing /opt/app-root/src/drupal/modules/views_infinite_scroll/tests/src
.S                                                                  2 / 2 (100%)

Time: 00:43.921, Memory: 6.00 MB

OK, but incomplete, skipped, or risky tests!
Tests: 2, Assertions: 19, Skipped: 1.