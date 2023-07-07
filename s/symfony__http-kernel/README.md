## The following test failure was noted for v4.4.23

```PHPUnit 9.5.21 #StandWithUkraine

Warning:       Your XML configuration validates against a deprecated schema.
Suggestion:    Migrate your XML configuration using "--migrate-configuration"!

Testing
...............................................................  63 / 823 (  7%)
............................................................... 126 / 823 ( 15%)
............................................................... 189 / 823 ( 22%)
...........................................F...........F....... 252 / 823 ( 30%)
............................................................... 315 / 823 ( 38%)
............................................................... 378 / 823 ( 45%)
............................................................... 441 / 823 ( 53%)
............................................................... 504 / 823 ( 61%)
..............................................F................ 567 / 823 ( 68%)
............................................................... 630 / 823 ( 76%)
............................................................... 693 / 823 ( 84%)
............................................................... 756 / 823 ( 91%)
............................................................... 819 / 823 ( 99%)
....                                                            823 / 823 (100%)

Time: 00:00.885, Memory: 20.00 MB

There were 3 failures:

1) Symfony\Component\HttpKernel\Tests\DependencyInjection\RegisterControllerArgumentLocatorsPassTest::testNoExceptionOnNonExistentTypeHintOptionalArg
Failed asserting that two arrays are identical.
--- Expected
+++ Actual
@@ @@
 Array &0 (
-    0 => 'foo::barAction'
-    1 => 'foo::fooAction'
+    0 => 'foo::fooAction'
+    1 => 'foo::barAction'
 )

/symfony/http-kernel/Tests/DependencyInjection/RegisterControllerArgumentLocatorsPassTest.php:239

2) Symfony\Component\HttpKernel\Tests\DependencyInjection\RemoveEmptyControllerArgumentLocatorsPassTest::testProcess
Failed asserting that two arrays are identical.
--- Expected
+++ Actual
@@ @@
 Array &0 (
-    0 => 'Symfony\Component\HttpKernel\DependencyInjection\RemoveEmptyControllerArgumentLocatorsPass: Removing service-argument resolver for controller "c2::fooAction": no corresponding services exist for the referenced types.'
-    1 => 'Symfony\Component\HttpKernel\DependencyInjection\RemoveEmptyControllerArgumentLocatorsPass: Removing method "setTestCase" of service "c2" from controller candidates: the method is called at instantiation, thus cannot be an action.'
+    0 => 'Symfony\Component\HttpKernel\DependencyInjection\RemoveEmptyControllerArgumentLocatorsPass: Removing method "setTestCase" of service "c2" from controller candidates: the method is called at instantiation, thus cannot be an action.'
+    1 => 'Symfony\Component\HttpKernel\DependencyInjection\RemoveEmptyControllerArgumentLocatorsPass: Removing service-argument resolver for controller "c2::fooAction": no corresponding services exist for the referenced types.'
 )

/symfony/http-kernel/Tests/DependencyInjection/RemoveEmptyControllerArgumentLocatorsPassTest.php:60

3) Symfony\Component\HttpKernel\Tests\HttpCache\HttpCacheTest::testRespondsWith304OnlyIfIfNoneMatchAndIfModifiedSinceBothMatch
Failed asserting that 304 matches expected 200.

/symfony/http-kernel/Tests/HttpCache/HttpCacheTest.php:175

FAILURES!
Tests: 823, Assertions: 1999, Failures: 3.

Remaining direct deprecation notices (18)

Legacy deprecation notices (31)

Other deprecation notices (1)
------------------symfony/http-kernel:install_success_but_test_fails---------------------
https://github.com/symfony/http-kernel symfony/http-kernel
symfony/http-kernel  |  https://github.com/symfony/http-kernel | v4.4.23 |  | GitHub | Fail |  Install_success_but_test_Fails ```
