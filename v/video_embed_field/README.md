
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
    #docker exec -it 33f80e2cc193 /bin/bash

Live drupal webserver will be available at http://<ip>:8081

After that we need to run below command inside container.Run it in single command . 
Step 1 will take sometime to exec. (configuration)

Step 1:- 

    su - postgres -c 'if [[ $(psql -l | grep dru2_pg) ]]; then     echo "Database already configured..."; else    /usr/pgsql-13/bin/pg_ctl -D /var/lib/pgsql/13/data/ start;     /usr/pgsql-13/bin/createdb -T template0 dru2_pg;     psql dru2_pg < /opt/app-root/src/drupal_schema.sql; fi'

Step 2:-

    /usr/sbin/httpd -k start;


step 3 Go to :-
	#cd /opt/app-root/src/drupal
composer require drupal/colorbox
composer require drupal/drupal/picture
    #cd /opt/app-root/src/drupal/modules

Clone the module which you wanted to test :-

    #git clone  https://git.drupalcode.org/project/video_embed_field.git
    #git checkout <requestedversions>   
----  
Follow automate_drupal.sh for more detail:-(Dependes on your package which version you need to install e.g ^8,^7)
  
    #cd /opt/app-root/src/drupal
    
     bash-4.4#yum install -y git php php-json php-dom php-mbstring zip unzip gd gd-devel php-gd php-pdo php-mysqlnd
     bash-4.4#php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
     bash-4.4#composer require --dev phpunit/phpunit --with-all-dependencies ^7  --no-interaction

     bash-4.4# composer install
    
    #cd /opt/app-root/src/drupal/modules/video_embed_field
    bash-4.4# pwd
    /opt/app-root/src/drupal/modules/video_embed_field
	 optional :
	 #composer require --dev drush/drush
direct we can also execute below command :--

  
	cd /opt/app-root/src/drupal/core
    bash-4.4# ./vendor/bin/drush pm:enable packagename 
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
Unit Test:

bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/video_embed_field/tests/src/Unit


To run Functional tests :-      

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/video_embed_field/tests/src/Functional
To run FunctionalJavascript tests :-      

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/video_embed_field/tests/src/FunctionalJavascript
To run Kernel tests :-      

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/video_embed_field/tests/src/Kernel
Run all tests in one go :-
    
    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/video_embed_field/tests/
    


Unit Testoutput:
*******************
bash-4.4# ../vendor/bin/phpunit ../modules/video_embed_field/tests/src/Unit
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/video_embed_field/tests/src/Unit
....................................................              52 / 52 (100%)

Time: 854 ms, Memory: 4.00 MB

OK (52 tests, 53 assertions)
bash-4.4# cd /opt/app-root/src/drupal/core
bash-4.4# ../vendor/bin/phpunit ../modules/video_embed_field/tests
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.
=====
Testing ../modules/video_embed_field/tests
.....SS.......................................................... 65 / 91 ( 71%)
..........................                                        91 / 91 (100%)

Time: 7.11 minutes, Memory: 4.00 MB

OK, but incomplete, skipped, or risky tests!
Tests: 91, Assertions: 314, Skipped: 2.
