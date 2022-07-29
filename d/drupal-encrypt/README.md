
How to run drupal related modules test cases.
-------------

Summary :-
    
    To run test cases in drupal module, we need drupal core package and drupal complete framework which incluse one database, apache server, and core package itself.
    There are 3 type of tests in drupal unit, functional, intergration. For unit test we don't need drupal full framework like database.
    Unit test don't use database testing.
 
*************************

Copy following files into VM thats needed to run docker file succesfully.

    1) automate_drupal.sh.txt
    2) Dockerfile.drupal.ubi
    3) drupal.zip
    4) drupal_schema.sql

Rename 2 files:-

    # cp Dockerfile.drupal.ubi Dockerfile
    # cp automate_drupal.sh.txt automate_drupal.sh
    # chmod +x automate_drupal.sh
     

Now create an image from dockerfile (Dockerfile.drupal.ubi i.e Dockerfile)
  
     # docker build -t drupal_image .
     # docker images
 
 
Then run a container using that image.

    # docker run -it -d drupal_image /bin/bash
    # docker ps
    # docker exec -it <Container_Id> /bin/bash

Live drupal webserver will be available at http://<ip>:8081

After that we need to run below command inside container.Run it in single command . Step 1 will take sometime to exec. 

Step 1:- 

    su - postgres -c 'if [[ $(psql -l | grep dru2_pg) ]]; then     echo "Database already configured..."; else    /usr/pgsql-13/bin/pg_ctl -D /var/lib/pgsql/13/data/ start;     /usr/pgsql-13/bin/createdb -T template0 dru2_pg;     psql dru2_pg < /opt/app-root/src/drupal_schema.sql; fi'

Step 2:-

    /usr/sbin/httpd -k start;


Go to :-

    # cd /opt/app-root/src/drupal/modules

Clone the module which you wanted to test :-

    # git clone https://git.drupalcode.org/project/encrypt
    # git checkout <versions>   
    
Follow automate_drupal.sh for more detail:-
  
    # cd /opt/app-root/src/drupal
    
     bash-4.4# yum install -y git php php-json php-dom php-mbstring zip unzip gd gd-devel php-gd php-pdo php-mysqlnd
     bash-4.4# php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
 
     bash-4.4# composer install
     bash-4.4# composer require drupal/key:1.15.0
     bash-4.4# composer require drupal/encrypt
	 
    # cd /opt/app-root/src/drupal/modules/encrypt
    bash-4.4# pwd
    /opt/app-root/src/drupal/modules/encrypt

    # composer require --dev drush/drush
    bash-4.4# ./vendor/bin/drush pm:enable encrypt   

    cd /opt/app-root/src/drupal/core
    bash-4.4# pwd
      /opt/app-root/src/drupal/core
      
 
RUN Test Kernel/Functional:- 
-----------------------    

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/encrypt/tests/
     
Test output
----------------

bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/encrypt/tests/src/
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/encrypt/tests/src/
................                                                  16 / 16 (100%)

Time: 1.85 minutes, Memory: 6.00 MB

OK (16 tests, 95 assertions)
