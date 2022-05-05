
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
  
Follow automate_drupal.sh for more detail:-
  
    #cd /opt/app-root/src/drupal
    
     bash-4.4#yum install -y git php php-json php-dom php-mbstring zip unzip gd gd-devel php-gd php-pdo php-mysqlnd
     bash-4.4#php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
     bash-4.4#composer require --dev phpunit/phpunit --with-all-dependencies ^8  --no-interaction

     bash-4.4# composer install
 
    bash-4.4# pwd
      /opt/app-root/src/drupal/core
      
 
RUN TESTS:- 
----------

drupal-Core test cases will take huge time i.e few hours to complete.KernelTestSuite completed in 13 hours.

bash-4.4# pwd
      /opt/app-root/src/drupal/core
      
../vendor/phpunit/phpunit/phpunit ./tests/TestSuites/BuildTestSuite.php 
../vendor/phpunit/phpunit/phpunit ./tests/TestSuites/TestSuiteBase.php 
../vendor/phpunit/phpunit/phpunit ./tests/TestSuites/BuildTestSuite.php
../vendor/phpunit/phpunit/phpunit ./tests/TestSuites/FunctionalJavascriptTestSuite.php          


To run unit tests :-      

    bash-4.4#  ../vendor/phpunit/phpunit/phpunit ./tests/TestSuites/UnitTestSuite.php
    
To run Functional tests :-      

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ./tests/TestSuites/FunctionalTestSuite.php
    
To run KernelTestSuite tests :-      

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ./tests/TestSuites/KernelTestSuite.php
   
    
Testcase Output :-
--------------------------------
 bash-4.4# ../vendor/phpunit/phpunit/phpunit ./tests/TestSuites/BuildTestSuite.php
PHPUnit 8.5.8 by Sebastian Bergmann and contributors.

Testing build
...................................composer require 'drupal/slick_views:^2.6'..............                 49 / 49 (100%)

Time: 3.74 minutes, Memory: 22.00 MB

OK (49 tests, 190 assertions)

Testing kernel
-----
        
 ../vendor/phpunit/phpunit/phpunit ./tests/TestSuites/KernelTestSuite.php

PHPUnit 8.5.8 by Sebastian Bergmann and contributors.

Testing kernel
...........S..SSS...SSS.SS..SSSS.SSS.S.....S.S.S..SSS...S.S.S   61 / 3975 (  1%)
S.SS.SSSS..SS.S....S.SS.....S.S.SSSS.S.......................  122 / 3975 (  3%)
.......................EEEEEEEEEEEF...F...........E...E......  183 / 3975 (  4%)
.E....E........F...F......E...E......SS......................  244 / 3975 (  6%)
.............................................................  305 / 3975 (  7%)
................F.............S.............S...S...S........  366 / 3975 (  9%)
....................S...F....................................  427 / 3975 ( 10%)
....S..................SS..............S.....................  488 / 3975 ( 12%)
.............................................................  549 / 3975 ( 13%)
.............................................................  610 / 3975 ( 15%)
.............................................................  671 / 3975 ( 16%)
.............................................................  732 / 3975 ( 18%)
.............................................................  793 / 3975 ( 19%)
.............................................................  854 / 3975 ( 21%)
...........................................SS...SSS......SSS.  915 / 3975 ( 23%)
S.SSSSS..SSSS.S..SSS...S.SSS..SS.SSS.S.SS.S....SSSSS..S......  976 / 3975 ( 24%)
............................................................. 1037 / 3975 ( 26%)
............................................................. 1098 / 3975 ( 27%)
............................................................. 1159 / 3975 ( 29%)
.......................................................F..... 1220 / 3975 ( 30%)
............................................................. 1281 / 3975 ( 32%)
............................................................. 1342 / 3975 ( 33%)
............................................................. 1403 / 3975 ( 35%)
............................................................. 1464 / 3975 ( 36%)
............................................................. 1525 / 3975 ( 38%)
............................................................. 1586 / 3975 ( 39%)
............................................................. 1647 / 3975 ( 41%)
............................................................. 1708 / 3975 ( 42%)
............................................................. 1769 / 3975 ( 44%)
............................................................. 1830 / 3975 ( 46%)
..SSSS....................................................... 1891 / 3975 ( 47%)
............................................................. 1952 / 3975 ( 49%)
............................................................. 2013 / 3975 ( 50%)
............................................................. 2074 / 3975 ( 52%)
............................................................. 2135 / 3975 ( 53%)
.........................................F................... 2196 / 3975 ( 55%)
............................................................. 2257 / 3975 ( 56%)
.....F.....FF................................................ 2318 / 3975 ( 58%)
............................................................. 2379 / 3975 ( 59%)
...................................................I......... 2440 / 3975 ( 61%)
....................................S........................ 2501 / 3975 ( 62%)
............................................................. 2562 / 3975 ( 64%)
............................................................. 2623 / 3975 ( 65%)
....................FFFFFF................................... 2684 / 3975 ( 67%)
............................................................. 2745 / 3975 ( 69%)
............................................................. 2806 / 3975 ( 70%)
............................................................. 2867 / 3975 ( 72%)
............................................................S 2928 / 3975 ( 73%)
.............F.......F....................................... 2989 / 3975 ( 75%)
............................................................. 3050 / 3975 ( 76%)
............................................................. 3111 / 3975 ( 78%)
............................................................. 3172 / 3975 ( 79%)
............................................................. 3233 / 3975 ( 81%)
............................................................. 3294 / 3975 ( 82%)
........................................F.................... 3355 / 3975 ( 84%)
..........SS................................................. 3416 / 3975 ( 85%)
............................................................. 3477 / 3975 ( 87%)
............................................................. 3538 / 3975 ( 89%)
............................................................. 3599 / 3975 ( 90%)
............................................................. 3660 / 3975 ( 92%)
............................................................. 3721 / 3975 ( 93%)
............................................................. 3782 / 3975 ( 95%)
............................................................. 3843 / 3975 ( 96%)
............................................................. 3904 / 3975 ( 98%)
............................................................. 3965 / 3975 ( 99%)
..........                                                    3975 / 3975 (100%)

Time: 13.14 hours, Memory: 330.00 MB

There were 17 errors:
-------
Unit test suites:-
-------------
        
        ../vendor/phpunit/phpunit/phpunit ./tests/TestSuites/UnitTestSuite.php

PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing unit
...........................................................    59 / 19221 (  0%)
...........................................................   118 / 19221 (  0%)
...........................................................   177 / 19221 (  0%)
..........FF........................F...............S......   236 / 19221 (  1%)
...........................................................   295 / 19221 (  1%)
...........................................................   354 / 19221 (  1%)
...........................................................   413 / 19221 (  2%)
...........................................................   472 / 19221 (  2%)
...........................................................   531 / 19221 (  2%)
...........................................................   590 / 19221 (  3%)
...........................................................   649 / 19221 (  3%)
...........................................................   708 / 19221 (  3%)
...........................................................   767 / 19221 (  3%)
..............................................SSSSSSS......   826 / 19221 (  4%)
..........................SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS   885 / 19221 (  4%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS   944 / 19221 (  4%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  1003 / 19221 (  5%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  1062 / 19221 (  5%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  1121 / 19221 (  5%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  1180 / 19221 (  6%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  1239 / 19221 (  6%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  1298 / 19221 (  6%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  1357 / 19221 (  7%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  1416 / 19221 (  7%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  1475 / 19221 (  7%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  1534 / 19221 (  7%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  1593 / 19221 (  8%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  1652 / 19221 (  8%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  1711 / 19221 (  8%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  1770 / 19221 (  9%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  1829 / 19221 (  9%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  1888 / 19221 (  9%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  1947 / 19221 ( 10%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  2006 / 19221 ( 10%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  2065 / 19221 ( 10%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  2124 / 19221 ( 11%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  2183 / 19221 ( 11%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  2242 / 19221 ( 11%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  2301 / 19221 ( 11%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  2360 / 19221 ( 12%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  2596 / 19221 ( 13%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  2655 / 19221 ( 13%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  2714 / 19221 ( 14%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  2773 / 19221 ( 14%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  2832 / 19221 ( 14%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  2891 / 19221 ( 15%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  2950 / 19221 ( 15%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  3009 / 19221 ( 15%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  3068 / 19221 ( 15%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  3127 / 19221 ( 16%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  3186 / 19221 ( 16%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  3245 / 19221 ( 16%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  3304 / 19221 ( 17%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  3363 / 19221 ( 17%)
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS....................  3422 / 19221 ( 17%)
...........................................................  3481 / 19221 ( 18%)
...........................................................  3540 / 19221 ( 18%)
...........................................................  3599 / 19221 ( 18%)
...........................................................  3658 / 19221 ( 19%)
...........................................................  3717 / 19221 ( 19%)
..FFFF.....................................................  3776 / 19221 ( 19%)
...........................................................  3835 / 19221 ( 19%)
...........................................................  3894 / 19221 ( 20%)
...........................................................  3953 / 19221 ( 20%)
...........................................................  4012 / 19221 ( 20%)
...........................................................  4071 / 19221 ( 21%)
...........................................................  4130 / 19221 ( 21%)
...........................................................  4189 / 19221 ( 21%)
...........................................................  4248 / 19221 ( 22%)
...........................................................  4307 / 19221 ( 22%)
...........................................................  4366 / 19221 ( 22%)
...........................................................  4425 / 19221 ( 23%)
...........................................................  4484 / 19221 ( 23%)
...........................................................  4543 / 19221 ( 23%)
...........................................................  4602 / 19221 ( 23%)
...........................................................  4661 / 19221 ( 24%)
...........................................................  4720 / 19221 ( 24%)
...........................................................  4779 / 19221 ( 24%)
             
                                                                                     
                                                                                     
                                                                                      ........................................................... 18998 / 19221 ( 98%)
........................................................... 19057 / 19221 ( 99%)
........................................................... 19116 / 19221 ( 99%)
........................................................... 19175 / 19221 ( 99%)
.............

Time: 8.14 minutes, Memory: 450.00 MB

There were 6 errors:

There were 17 failures:

1) Drupal\Tests\Component\Annotation\Doctrine\DocParserTest::testAnnotationEnumeratorException
Failed asserting that exception message '[Enum Error] Attribute "value" of @Drupal\Tests\Component\Annotation\Doctrine\Fixtures\AnnotationEnum declared on property SomeClassName::invalidProperty. accepts only [ONE, TWO, THREE], but got FOUR.' contains 'Attribute "value" of @Drupal\Tests\Component\Annotation\Doctrine\Fixtures\AnnotationEnum declared on property SomeClassName::invalidProperty. accept only [ONE, TWO, THREE], but got FOUR.'.

2) Drupal\Tests\Component\Annotation\Doctrine\DocParserTest::testAnnotationEnumeratorLiteralException
Failed asserting that exception message '[Enum Error] Attribute "value" of @Drupal\Tests\Component\Annotation\Doctrine\Fixtures\AnnotationEnumLiteral declared on property SomeClassName::invalidProperty. accepts only [AnnotationEnumLiteral::ONE, AnnotationEnumLiteral::TWO, AnnotationEnumLiteral::THREE], but got 4.' contains 'Attribute "value" of @Drupal\Tests\Component\Annotation\Doctrine\Fixtures\AnnotationEnumLiteral declared on property SomeClassName::invalidProperty. accept only [AnnotationEnumLiteral::ONE, AnnotationEnumLiteral::TWO, AnnotationEnumLiteral::THREE], but got 4.'.

3) Drupal\Tests\Component\Annotation\Doctrine\DocParserTest::testAnnotationWithInvalidTargetDeclarationError
Failed asserting that exception message 'Invalid Target "Foo". Available targets: [ALL, CLASS, METHOD, PROPERTY, FUNCTION, ANNOTATION]' contains 'Invalid Target "Foo". Available targets: [ALL, CLASS, METHOD, PROPERTY, ANNOTATION]'.

4) Drupal\Tests\Component\Utility\HtmlTest::testTransformRootRelativeUrlsToAbsoluteAssertion with data set "only relative path" ('llama')
Failed asserting that exception of type "AssertionError" is thrown.

5) Drupal\Tests\Component\Utility\HtmlTest::testTransformRootRelativeUrlsToAbsoluteAssertion with data set "only root-relative path" ('/llama')
Failed asserting that exception of type "AssertionError" is thrown.

6) Drupal\Tests\Component\Utility\HtmlTest::testTransformRootRelativeUrlsToAbsoluteAssertion with data set "host and path" ('example.com/llama')
Failed asserting that exception of type "AssertionError" is thrown.

7) Drupal\Tests\Component\Utility\HtmlTest::testTransformRootRelativeUrlsToAbsoluteAssertion with data set "scheme, host and path" ('http://example.com/llama')
Failed asserting that exception of type "AssertionError" is thrown.

8) Drupal\Tests\Core\Asset\LibraryDependencyResolverTest::testGetMinimalRepresentativeSubsetInvalidInput
Failed asserting that exception of type "AssertionError" is thrown.

9) Drupal\Tests\Core\Cache\CacheTagsInvalidatorTest::testInvalidateTagsWithInvalidTags
Failed asserting that exception of type "Error" matches expected exception "AssertionError". Message was: "Call to a member function getParameter() on null" at
/opt/app-root/src/drupal/core/lib/Drupal/Core/Cache/CacheTagsInvalidator.php:71
/opt/app-root/src/drupal/core/lib/Drupal/Core/Cache/CacheTagsInvalidator.php:34
/opt/app-root/src/drupal/core/tests/Drupal/Tests/Core/Cache/CacheTagsInvalidatorTest.php:21
.
                                                                                           

11) Drupal\Tests\Core\Command\QuickStartTest::testQuickStartInstallAndServerCommands
Failed asserting that 'Drupal development server started: <http://127.0.0.1:8889>\n
This server is not meant for production use.\n
' contains "127.0.0.1:8889/user/reset/1/".

/opt/app-root/src/drupal/core/tests/Drupal/Tests/Core/Command/QuickStartTest.php:218

12) Drupal\Tests\Core\DependencyInjection\ContainerBuilderTest::testSerialize
Failed asserting that exception of type "AssertionError" is thrown.

13) Drupal\Tests\Core\DependencyInjection\ContainerTest::testSerialize
Failed asserting that exception of type "AssertionError" is thrown.

14) Drupal\Tests\Core\Render\Placeholder\ChainedPlaceholderStrategyTest::testProcessPlaceholdersNoStrategies
Failed asserting that exception of type "AssertionError" is thrown.

15) Drupal\Tests\Core\Render\Placeholder\ChainedPlaceholderStrategyTest::testProcessPlaceholdersWithRoguePlaceholderStrategy
Failed asserting that exception of type "AssertionError" is thrown.

16) Drupal\Tests\big_pipe\Unit\Render\BigPipeResponseAttachmentsProcessorTest::testNonHtmlResponse with data set "AjaxResponse, which implements AttachmentsInterface" ('Drupal\Core\Ajax\AjaxResponse')
Failed asserting that exception of type "TypeError" matches expected exception "AssertionError". Message was: "Argument 1 passed to Drupal\Core\Render\HtmlResponseAttachmentsProcessor::renderPlaceholders() must be an instance of Drupal\Core\Render\HtmlResponse, instance of Drupal\Core\Ajax\AjaxResponse given, called in /opt/app-root/src/drupal/core/modules/big_pipe/src/Render/BigPipeResponseAttachmentsProcessor.php on line 71" at
/opt/app-root/src/drupal/core/lib/Drupal/Core/Render/HtmlResponseAttachmentsProcessor.php:273
/opt/app-root/src/drupal/core/modules/big_pipe/src/Render/BigPipeResponseAttachmentsProcessor.php:71
/opt/app-root/src/drupal/core/modules/big_pipe/tests/src/Unit/Render/BigPipeResponseAttachmentsProcessorTest.php:37
.

17) Drupal\Tests\big_pipe\Unit\Render\BigPipeResponseAttachmentsProcessorTest::testNonHtmlResponse with data set "A dummy that implements AttachmentsInterface" ('Double\AttachmentsInterface\P13')
Failed asserting that exception of type "TypeError" matches expected exception "AssertionError". Message was: "Argument 1 passed to Drupal\Core\Render\HtmlResponseAttachmentsProcessor::renderPlaceholders() must be an instance of Drupal\Core\Render\HtmlResponse, instance of Double\AttachmentsInterface\P13 given, called in /opt/app-root/src/drupal/core/modules/big_pipe/src/Render/BigPipeResponseAttachmentsProcessor.php on line 71" at
/opt/app-root/src/drupal/core/lib/Drupal/Core/Render/HtmlResponseAttachmentsProcessor.php:273
/opt/app-root/src/drupal/core/modules/big_pipe/src/Render/BigPipeResponseAttachmentsProcessor.php:71
/opt/app-root/src/drupal/core/modules/big_pipe/tests/src/Unit/Render/BigPipeResponseAttachmentsProcessorTest.php:37
.


ERRORS!
Tests: 19221, Assertions: 34248, Errors: 6, Failures: 17, Skipped: 2567, Incomplete: 3.
--------------------   
    

Note:-
----------

https://deninet.com/blog/2019/01/13/writing-automated-tests-drupal-8-part-2-functional-tests
https://deninet.com/blog/2018/12/31/writing-automated-tests-drupal-8-part-1-test-types-and-set

  
-------
