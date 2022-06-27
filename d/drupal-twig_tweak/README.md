
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

    #git clone https://git.drupalcode.org/project/twig_tweak
    #git checkout <versions>   
  
Follow automate_drupal.sh for more detail:-
  
    #cd /opt/app-root/src/drupal
    
     bash-4.4#yum install -y git php php-json php-dom php-mbstring zip unzip gd gd-devel php-gd php-pdo php-mysqlnd
     bash-4.4#php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
     bash-4.4#composer require --dev phpunit/phpunit --with-all-dependencies ^8  --no-interaction

     bash-4.4# composer install
    
    #cd /opt/app-root/src/drupal/modules/twig_tweak
    bash-4.4# pwd
    /opt/app-root/src/drupal/modules/twig_tweak

    #composer require --dev drush/drush
    bash-4.4# ./vendor/bin/drush pm:enable twig_tweak   

    cd /opt/app-root/src/drupal/core
    bash-4.4# pwd
      /opt/app-root/src/drupal/core
      
 
RUN Test Kernel/Functional:- 
-----------------------    

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/twig_tweak/tests/
    
    
 
 
Test output
----------------

Tested with  drupal/core - 9.4.x
 

bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/twig_tweak/tests/
PHPUnit 8.5.26 #StandWithUkraine

Testing ../modules/twig_tweak/tests/
...........                                                       11 / 11 (100%)

Time: 1.42 minutes, Memory: 6.00 MB

OK (11 tests, 236 assertions)


Note :-
------

Following version needed to run twig_tweak 8.x-2.9

1. drupal/core 8.9.11
2. twig_tweak  2.9.0
3. composer require --dev phpunit/phpunit --with-all-dependencies ^7

 
bash-4.4# pwd
/opt/app-root/src/drupal/core

bash-4.4# cp phpunit.xml.dist phpunit.xml

bash-4.4# vim phpunit.xml
Edit it like

    <env name="SIMPLETEST_BASE_URL" value="http://0.0.0.0:8081"/>
   
    <env name="SIMPLETEST_DB" value="pgsql://postgres:postgres@localhost/dru2_pg"/>