
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

    #git clone  https://git.drupalcode.org/project/legal
    #git checkout <requestedversions>   
----  
Follow automate_drupal.sh for more detail:-(Dependes on your package which version you need to install e.g ^7,^8)
  
    #cd /opt/app-root/src/drupal
    
     bash-4.4#yum install -y git php php-json php-dom php-mbstring zip unzip gd gd-devel php-gd php-pdo php-mysqlnd
     bash-4.4#php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
     bash-4.4#composer require --dev phpunit/phpunit --with-all-dependencies ^7  --no-interaction

     bash-4.4# composer install
    
    #cd /opt/app-root/src/drupal/modules/legal
    bash-4.4# pwd
    /opt/app-root/src/drupal/modules/legal

    #composer require --dev drush/drush
    bash-4.4# ./vendor/bin/drush pm:enable   

    cd /opt/app-root/src/drupal/core
    bash-4.4# pwd
      /opt/app-root/src/drupal/core
	  
	  
	  or can use below steps after checkout the requested version:
	  
	  cd /opt/app-root/src/drupal/core
	  composer config allow-plugins true
	  composer update --ignore-platform-req=ext-gd
	  
	  
      Note:drupal 8.9.11 used in this package.
 
RUN TESTS:- 
----------
    
To run Functional tests :-      

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/legal/tests/src/Functional
   
Run all tests in one go :-
    
    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/legal/tests
    
    
Testcase Output :-
--------------------------------

---------------------------------------------------------------------------
      
    Remove existing drupal folder from directory /opt/app-root/src/drupal and clone the 8.9.11 version.
        #  git clone https://github.com/drupal/drupal  
        #   cd /opt/app-root/src/drupal/core
        #   cp phpunit.xml.dist phpunit.xml
    Edit the phpunit.xml file to update database url and apache server url.
    <env name="SIMPLETEST_BASE_URL" value="http://0.0.0.0:8081"/>
    <env name="SIMPLETEST_DB" value="pgsql://postgres:postgres@localhost/dru2_pg"/>
    
-------

cd /opt/app-root/src/drupal
cd /opt/app-root/src/drupal/modules
ls
rm -rf legal
git clone https://git.drupalcode.org/project/legal.git
history
bash-4.4# pwd
/opt/app-root/src/drupal/modules
bash-4.4# cd legal
bash-4.4# git checkout 2.0.0
Note: switching to '2.0.0'.

You are in 'detached HEAD' state. You can look around, make experimental
changes and commit them, and you can discard any commits you make in this
state without impacting any branches by switching back to a branch.

If you want to create a new branch to retain commits you create, you may
do so (now or later) by using -c with the switch command. Example:

  git switch -c <new-branch-name>

Or undo this operation with:

  git switch -

Turn off this advice by setting config variable advice.detachedHead to false

HEAD is now at 891467b Merge branch 'master' into 8.x-1.x
bash-4.4# pwd
/opt/app-root/src/drupal/modules/legal
bash-4.4# cd ../..
bash-4.4# cd /opt/app-root/src/drupal
bash-4.4# cd core
bash-4.4#  ../vendor/phpunit/phpunit/phpunit ../modules/legal/tests/
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/legal/tests/
...........                                                       11 / 11 (100%)

Time: 3.78 minutes, Memory: 4.00 MB

OK (11 tests, 99 assertions)

Remaining deprecation notices (11)

  11x: Drupal\Tests\BrowserTestBase::$defaultTheme is required in drupal:9.0.0 when using an install profile that does not set a default theme. See https://www.drupal.org/node/3083055, which includes recommendations on which theme to use.
    1x in LoginTest::testLogin from Drupal\Tests\legal\Functional
    1x in LoginTest::testScrollBox from Drupal\Tests\legal\Functional
    1x in LoginTest::testScrollBoxCss from Drupal\Tests\legal\Functional
    1x in LoginTest::testHtml from Drupal\Tests\legal\Functional
    1x in LoginTest::testPageLink from Drupal\Tests\legal\Functional
    1x in PasswordResetTest::testPasswordReset from Drupal\Tests\legal\Functional
    1x in RegistrationTest::testRegistration from Drupal\Tests\legal\Functional
    1x in RegistrationTest::testScrollBox from Drupal\Tests\legal\Functional
    1x in RegistrationTest::testScrollBoxCss from Drupal\Tests\legal\Functional
    1x in RegistrationTest::testHtml from Drupal\Tests\legal\Functional
    1x in RegistrationTest::testPageLink from Drupal\Tests\legal\Functional

bash-4.4#  ../vendor/phpunit/phpunit/phpunit ../modules/legal/tests/src/Functional
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/legal/tests/src/Functional
...........                                                       11 / 11 (100%)

Time: 3.84 minutes, Memory: 4.00 MB

OK (11 tests, 99 assertions)

Remaining deprecation notices (11)

  11x: Drupal\Tests\BrowserTestBase::$defaultTheme is required in drupal:9.0.0 when using an install profile that does not set a default theme. See https://www.drupal.org/node/3083055, which includes recommendations on which theme to use.
    1x in LoginTest::testLogin from Drupal\Tests\legal\Functional
    1x in LoginTest::testScrollBox from Drupal\Tests\legal\Functional
    1x in LoginTest::testScrollBoxCss from Drupal\Tests\legal\Functional
    1x in LoginTest::testHtml from Drupal\Tests\legal\Functional
    1x in LoginTest::testPageLink from Drupal\Tests\legal\Functional
    1x in PasswordResetTest::testPasswordReset from Drupal\Tests\legal\Functional
    1x in RegistrationTest::testRegistration from Drupal\Tests\legal\Functional
    1x in RegistrationTest::testScrollBox from Drupal\Tests\legal\Functional
    1x in RegistrationTest::testScrollBoxCss from Drupal\Tests\legal\Functional
    1x in RegistrationTest::testHtml from Drupal\Tests\legal\Functional
    1x in RegistrationTest::testPageLink from Drupal\Tests\legal\Functional
