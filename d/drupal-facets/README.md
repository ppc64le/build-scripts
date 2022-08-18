
How to run drupal related modules test cases (Functional/FunctionalJavascript/Kernel).
-------------

Summary :-
    
    To run test cases in drupal module we need drupal core package and drupal complete framework which incluse one database,apache server,and core package itself.
    There are different types of tests in drupal. For unit test we dont need drupal full framework like database.
    Unit test does not use database testing.
	
	Some packages may require drupal 9.4.x version to run successfully. 
	For drupal 9.4.x: 
    Remove existing drupal folder from directory /opt/app-root/src/drupal and clone the 9.4.x version.
        #  git clone https://github.com/drupal/drupal  
        #  cd /opt/app-root/src/drupal/core
        #  cp phpunit.xml.dist phpunit.xml
    Edit the phpunit.xml file to update database url and apache server url.
    <env name="SIMPLETEST_BASE_URL" value="http://0.0.0.0:8081"/>
    <env name="SIMPLETEST_DB" value="pgsql://postgres:postgres@localhost/dru2_pg"/>
    
-------
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

    #docker run --name drupal_container -it -d drupal_image /bin/bash
	#docker ps
	#docker exec -it drupal_container /bin/bash

Live drupal webserver will be available at http://:8081

After that we need to run below command inside container.Run it in single command . Step 1 will take some time to execute. 

Step 1:- 

    su - postgres -c 'if [[ $(psql -l | grep dru2_pg) ]]; then     echo "Database already configured..."; else    /usr/pgsql-13/bin/pg_ctl -D /var/lib/pgsql/13/data/ -l logfile start;     /usr/pgsql-13/bin/createdb -T template0 dru2_pg;     psql dru2_pg < /opt/app-root/src/drupal_schema.sql; fi'

Step 2:-

    /usr/sbin/httpd -k start;


Go to :-

    #cd /opt/app-root/src/drupal/modules

Clone the module which you wanted to test :-

    #git clone  https://git.drupalcode.org/project/<package_name>
    #cd <package_name>
    #git checkout <version>   
  
Follow automate_drupal.sh for more detail:-

	#cd /opt/app-root/src/drupal

	bash-4.4#yum install -y git php php-json php-dom php-mbstring zip unzip gd gd-devel php-gd php-pdo php-mysqlnd
	bash-4.4#php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
	bash-4.4#composer require --dev phpunit/phpunit --with-all-dependencies ^8  --no-interaction

	bash-4.4# composer install
	bash-4.4# composer require drupal/views:*
	bash-4.4# composer require drupal/search_api:*
	
	bash-4.4# cd /opt/app-root/src/drupal/modules/<package_name>
	
	
	#composer require --dev drush/drush
	bash-4.4# ./vendor/bin/drush pm:enable   
	
	bash-4.4# cd /opt/app-root/src/drupal/core
	    
     
	
RUN TESTS:- 
----------

To run Functional tests :-      

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/<package_name>/tests/src/Functional

To run FunctionalJavascript tests :-      

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/<package_name>/tests/src/FunctionalJavascript
  
To run Kernel tests :-      

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/<package_name>/tests/src/Kernel/

  
Run all tests in one go :-
    
    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/<package_name>/tests
    
    
Testcase Output :-
--------------------------------

Kernel tests :-

	bash-4.4#  ../vendor/phpunit/phpunit/phpunit ../modules/facets/tests/src/Kernel/
  PHPUnit 7.5.20 by Sebastian Bergmann and contributors.
  
  Testing ../modules/facets/tests/src/Kernel/
  ....................................                              36 / 36 (100%)
  
  Time: 2.39 minutes, Memory: 4.00 MB
    
  OK (36 tests, 353 assertions)

FunctionalJavascript tests :-

	bash-4.4#  ../vendor/phpunit/phpunit/phpunit ../modules/facets/tests/src/FunctionalJavascript/
  PHPUnit 7.5.20 by Sebastian Bergmann and contributors.
  
  Testing ../modules/facets/tests/src/FunctionalJavascript/
  SSSSSSSS                                                            8 / 8 (100%)
  
  Time: 28.64 minutes, Memory: 4.00 MB
  
  OK, but incomplete, skipped, or risky tests!
  Tests: 8, Assertions: 8, Skipped: 8.

Functional tests :-
    
  bash-4.4#  ../vendor/phpunit/phpunit/phpunit ../modules/facets/tests/src/Functional
  PHPUnit 7.5.20 by Sebastian Bergmann and contributors.
  
  Testing ../modules/facets/tests/src/Functional
  ..S............................................................  63 / 114 ( 55%)
  ...............SS..SS..SS..SS..SS..SS..............             114 / 114 (100%)
  
  Time: 4.38 hours, Memory: 4.00 MB
  
  OK, but incomplete, skipped, or risky tests!
  Tests: 114, Assertions: 4050, Skipped: 13.
  
  Remaining deprecation notices (192)

  192x: The deprecated alter hook hook_search_api_db_query_alter() is implemented in these functions: search_api_test_db_search_api_db_query_alter. This hook is deprecated in search_api:8.x-1.16 and is removed from search_api:2.0.0. Please use the "search_api_db.query_pre_execute" event instead. See https://www.drupal.org/node/3103591
    18x in BreadcrumbIntegrationTest::testGroupingIntegration from Drupal\Tests\facets\Functional
    15x in HierarchicalFacetIntegrationTest::testHierarchicalFacet from Drupal\Tests\facets\Functional
    11x in ProcessorIntegrationTest::testProcessorIntegration from Drupal\Tests\facets\Functional
    11x in LanguageIntegrationTest::testUrlAliasTranslation from Drupal\Tests\facets\Functional
    10x in ProcessorIntegrationTest::testSortingWidgets from Drupal\Tests\facets\Functional
    9x in IntegrationTest::testFacetDependencies from Drupal\Tests\facets\Functional
    6x in UrlIntegrationTest::testResetPager from Drupal\Tests\facets\Functional
    6x in UrlIntegrationTest::testUrlIntegration from Drupal\Tests\facets\Functional
    6x in IntegrationTest::testAndOrFacet from Drupal\Tests\facets\Functional
    6x in WidgetIntegrationTest::testAllLink from Drupal\Tests\facets\Functional
    5x in IntegrationTest::testFacetSourceVisibility from Drupal\Tests\facets\Functional
    5x in WidgetIntegrationTest::testLinksShowHideCount from Drupal\Tests\facets\Functional
    4x in IntegrationTest::testUrlAlias from Drupal\Tests\facets\Functional
    4x in ProcessorIntegrationTest::testBooleanProcessorIntegration from Drupal\Tests\facets\Functional
    4x in IntegrationTest::testExcludeFacet from Drupal\Tests\facets\Functional
    4x in IntegrationTest::testExcludeFacetDate from Drupal\Tests\facets\Functional
    4x in IntegrationTest::testFacetCountCalculations from Drupal\Tests\facets\Functional
    4x in BreadcrumbIntegrationTest::testBreadcrumbLabel from Drupal\Tests\facets\Functional
    4x in IntegrationTest::testMultipleFacets from Drupal\Tests\facets\Functional
    4x in IntegrationTest::testFramework from Drupal\Tests\facets\Functional
    3x in UrlIntegrationTest::testIncompleteFacetUrl from Drupal\Tests\facets\Functional
    3x in FacetsUrlGeneratorTest::testWithAlreadySetFacet from Drupal\Tests\facets\Functional
    3x in ProcessorIntegrationTest::testResultSorting from Drupal\Tests\facets\Functional
    3x in IntegrationTest::testBlockView from Drupal\Tests\facets\Functional
    3x in ProcessorIntegrationTest::testNumericGranularity from Drupal\Tests\facets\Functional
    3x in LanguageIntegrationTest::testLanguageDifferences from Drupal\Tests\facets\Functional
    3x in HierarchicalFacetIntegrationTest::testHierarchyBreadcrumb from Drupal\Tests\facets\Functional
    3x in IntegrationTest::testAllowOneActiveItem from Drupal\Tests\facets\Functional
    2x in HierarchicalFacetIntegrationTest::testWeightSort from Drupal\Tests\facets\Functional
    2x in WidgetIntegrationTest::testLinksWidget from Drupal\Tests\facets\Functional
    2x in UrlIntegrationTest::testFacetUrlCanBeChanged from Drupal\Tests\facets\Functional
    2x in IntegrationTest::testHardLimit from Drupal\Tests\facets\Functional
    2x in IntegrationTest::testMinimumAmount from Drupal\Tests\facets\Functional
    2x in UrlIntegrationTest::testColonValue from Drupal\Tests\facets\Functional
    2x in IntegrationTest::testShowTitle from Drupal\Tests\facets\Functional
    2x in ProcessorIntegrationTest::testEntityTranslateWithUnderScores from Drupal\Tests\facets\Functional
    2x in ProcessorIntegrationTest::testListProcessor from Drupal\Tests\facets\Functional
    2x in LanguageIntegrationTest::testSpecialCharacters from Drupal\Tests\facets\Functional
    2x in HierarchicalFacetIntegrationTest::testHierarchySorting from Drupal\Tests\facets\Functional
    2x in LanguageIntegrationTest::testLanguageIntegration from Drupal\Tests\facets\Functional
    1x in ProcessorIntegrationTest::testHideOnlyOneItemProcessor from Drupal\Tests\facets\Functional
    1x in ProcessorIntegrationTest::testPreQueryProcessor from Drupal\Tests\facets\Functional
    1x in WidgetIntegrationTest::testCheckboxWidget from Drupal\Tests\facets\Functional
    1x in WidgetIntegrationTest::testDropdownWidget from Drupal\Tests\facets\Functional

Note:-
----------

https://deninet.com/blog/2019/01/13/writing-automated-tests-drupal-8-part-2-functional-tests
https://deninet.com/blog/2018/12/31/writing-automated-tests-drupal-8-part-1-test-types-and-set

-------