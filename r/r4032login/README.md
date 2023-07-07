
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

    #git clone  https://git.drupalcode.org/project/r4032login
    #git checkout <requestedversions>   
----  
Follow automate_drupal.sh for more detail:-(Dependes on your package which version you need to install e.g ^8,^7)
  
    #cd /opt/app-root/src/drupal
    
     bash-4.4#yum install -y git php php-json php-dom php-mbstring zip unzip gd gd-devel php-gd php-pdo php-mysqlnd
     bash-4.4#php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
     bash-4.4#composer require --dev phpunit/phpunit --with-all-dependencies ^7  --no-interaction

     bash-4.4# composer install
    
    #cd /opt/app-root/src/drupal/modules/r4032login
    bash-4.4# pwd
    /opt/app-root/src/drupal/modules/r4032login

    #composer require --dev drush/drush
    bash-4.4# ./vendor/bin/drush pm:enable   

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

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/r4032login/tests/src/Unit
    
To run Functional tests :-      

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/r4032login/tests/src/Functional
   
Run all tests in one go :-
    
    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/r4032login/tests
    
    
Testcase Output :-
--------------------------------
> Drupal\Core\Composer\Composer::preAutoloadDump
Hardening vendor directory with .htaccess and web.config files.
67 packages you are using are looking for funding.
Use the `composer fund` command to find out more!
Vendor directory already clean.
PHP CodeSniffer Config installed_paths set to ../../drupal/coder/coder_sniffer,../../sirbrillig/phpcs-variable-analysis,../../slevomat/coding-standard
> Drupal\Composer\Composer::generateMetapackages
Updated metapackage file composer/Metapackage/CoreRecommended/composer.json.
Updated metapackage file composer/Metapackage/PinnedDevDependencies/composer.json.
If you make a patch, ensure that the files above are included.
r4032login  |  2.1.0 ------------------Build_success-------------------------
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing modules/r4032login/tests/src/Unit
......                                                              6 / 6 (100%)

Time: 928 ms, Memory: 4.00 MB

OK (6 tests, 14 assertions)
r4032login  |  2.1.0------------------Test_success-------------------------
---------------------------------------------------------------------------
      
    Remove existing drupal folder from directory /opt/app-root/src/drupal and clone the 8.9.0 version.
        #  git clone https://github.com/drupal/drupal  
        #   cd /opt/app-root/src/drupal/core
        #   cp phpunit.xml.dist phpunit.xml
    Edit the phpunit.xml file to update database url and apache server url.
    <env name="SIMPLETEST_BASE_URL" value="http://0.0.0.0:8081"/>
    <env name="SIMPLETEST_DB" value="pgsql://postgres:postgres@localhost/dru2_pg"/>
    
-------