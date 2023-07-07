
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
    #docker exec -it 8079a763ed5b /bin/bash

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

    #git clone  https://git.drupalcode.org/project/avatars.git
    #git checkout <requestedversions>   
----  
Follow automate_drupal.sh for more detail:-(Dependes on your package which version you need to install e.g ^8,^7)
  
    #cd /opt/app-root/src/drupal
    
     bash-4.4#yum install -y git php php-json php-dom php-mbstring zip unzip gd gd-devel php-gd php-pdo php-mysqlnd
     bash-4.4#php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
     bash-4.4#composer require --dev phpunit/phpunit --with-all-dependencies ^7  --no-interaction
	 bash-4.4# composer require 'drupal/unlimited_number:2.0.0'
     bash-4.4# composer install
    
    #cd /opt/app-root/src/drupal/modules/avatars
    bash-4.4# pwd
    /opt/app-root/src/drupal/modules/avatars

    #composer require --dev drush/drush
    bash-4.4# ./vendor/bin/drush pm:enable avatars 
	or 
	cd /opt/app-root/src/drupal/core
	../vendor/bin/drush pm:enable avatars 
    --
    bash-4.4# pwd
      /opt/app-root/src/drupal/core
	  
	  
	  or can use below steps after checkout the requested version:
	  
	  cd /opt/app-root/src/drupal/core
	  composer config allow-plugins true
	  composer update --ignore-platform-req=ext-gd
	  
	  
      Note:drupal 9.0.x used in this package.
 
RUN TESTS:- 
----------

To run unit tests :-      

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/avatars/tests/src/Kernel
    
To run Functional tests :-      

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/avatars/tests/src/Functional
   
Run all tests in one go :-
    
    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/avatars/tests
    
    
Testcase Output :-
--------------------------------
bash-4.4# ../vendor/bin/phpunit ../modules/avatars/tests/src/Functional
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/avatars/tests/src/Functional
........                                                            8 / 8 (100%)

Time: 3.34 minutes, Memory: 4.00 MB

OK (8 tests, 72 assertions)

---------------------------------------------------------------------------
bash-4.4# ../vendor/bin/phpunit ../modules/avatars/tests/src/Kernel
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/avatars/tests/src/Kernel
......                                                              6 / 6 (100%)

Time: 18.59 seconds, Memory: 4.00 MB

OK (6 tests, 38 assertions)
-------------------------------------------------------------------------

bash-4.4# ../vendor/bin/phpunit ../modules/avatars/tests
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/avatars/tests
..............                                                    14 / 14 (100%)

Time: 3.69 minutes, Memory: 4.00 MB

OK (14 tests, 110 assertions)
---------------------------------------------------------------------------
      
    Remove existing drupal folder from directory /opt/app-root/src/drupal and clone the 9.0.x version.
        #  git clone https://github.com/drupal/drupal  
        #   cd /opt/app-root/src/drupal/core
        #   cp phpunit.xml.dist phpunit.xml
    Edit the phpunit.xml file to update database url and apache server url.
    <env name="SIMPLETEST_BASE_URL" value="http://0.0.0.0:8081"/>
    <env name="SIMPLETEST_DB" value="pgsql://postgres:postgres@localhost/dru2_pg"/>
    
-------
command
bash-4.4# history
    1  cd /opt/app-root/src/drupal
    2  git branch
    3  git switch -c 9.0.x
    4  composer require 'drupal/unlimited_number:2.0.0'
    5  cd /opt/app-root/src/drupal/core
    6  ../vendor/bin/phpunit ../modules/avatars/tests/src/Functional
