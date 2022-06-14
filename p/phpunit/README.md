       Test cases failure details for version 9.5.10
  -----

There were 6 failures:

1) PHPUnit\Framework\AssertTest::testAssertDirectoryIsNotReadable
Failed asserting that "/tmp/unreadable_dir_62a6d021a48096.41274515" is not readable.

/root/phpunit/src/Framework/Constraint/Constraint.php:121
/root/phpunit/src/Framework/Constraint/Constraint.php:55
/root/phpunit/src/Framework/Assert.php:2344
/root/phpunit/src/Framework/Assert.php:749
/root/phpunit/src/Framework/Assert.php:868
/root/phpunit/tests/unit/Framework/AssertTest.php:560
/root/phpunit/src/Framework/TestCase.php:1527
/root/phpunit/src/Framework/TestCase.php:1133
/root/phpunit/src/Framework/TestResult.php:722
/root/phpunit/src/Framework/TestCase.php:885
/root/phpunit/src/Framework/TestSuite.php:678
/root/phpunit/src/Framework/TestSuite.php:678
/root/phpunit/src/Framework/TestSuite.php:678
/root/phpunit/src/TextUI/TestRunner.php:670
/root/phpunit/src/TextUI/Command.php:143
/root/phpunit/src/TextUI/Command.php:96

2) PHPUnit\Framework\AssertTest::testAssertDirectoryIsNotWritable
Failed asserting that "/tmp/not_writable_dir_62a6d021a4cde8.28981114" is not writable.

/root/phpunit/src/Framework/Constraint/Constraint.php:121
/root/phpunit/src/Framework/Constraint/Constraint.php:55
/root/phpunit/src/Framework/Assert.php:2344
/root/phpunit/src/Framework/Assert.php:788
/root/phpunit/src/Framework/Assert.php:910
/root/phpunit/tests/unit/Framework/AssertTest.php:590
/root/phpunit/src/Framework/TestCase.php:1527
/root/phpunit/src/Framework/TestCase.php:1133
/root/phpunit/src/Framework/TestResult.php:722
/root/phpunit/src/Framework/TestCase.php:885
/root/phpunit/src/Framework/TestSuite.php:678
/root/phpunit/src/Framework/TestSuite.php:678
/root/phpunit/src/Framework/TestSuite.php:678
/root/phpunit/src/TextUI/TestRunner.php:670
/root/phpunit/src/TextUI/Command.php:143
/root/phpunit/src/TextUI/Command.php:96

3) PHPUnit\Framework\AssertTest::testAssertFileIsNotReadable
Failed asserting that "/tmp/unreadableg3Pif1" is not readable.

/root/phpunit/src/Framework/Constraint/Constraint.php:121
/root/phpunit/src/Framework/Constraint/Constraint.php:55
/root/phpunit/src/Framework/Assert.php:2344
/root/phpunit/src/Framework/Assert.php:749
/root/phpunit/src/Framework/Assert.php:991
/root/phpunit/tests/unit/Framework/AssertTest.php:642
/root/phpunit/src/Framework/TestCase.php:1527
/root/phpunit/src/Framework/TestCase.php:1133
/root/phpunit/src/Framework/TestResult.php:722
/root/phpunit/src/Framework/TestCase.php:885
/root/phpunit/src/Framework/TestSuite.php:678
/root/phpunit/src/Framework/TestSuite.php:678
/root/phpunit/src/Framework/TestSuite.php:678
/root/phpunit/src/TextUI/TestRunner.php:670
/root/phpunit/src/TextUI/Command.php:143
/root/phpunit/src/TextUI/Command.php:96

4) PHPUnit\Framework\AssertTest::testAssertFileIsNotWritable
Failed asserting that "/tmp/not_writableIcKBK0" is not writable.

/root/phpunit/src/Framework/Constraint/Constraint.php:121
/root/phpunit/src/Framework/Constraint/Constraint.php:55
/root/phpunit/src/Framework/Assert.php:2344
/root/phpunit/src/Framework/Assert.php:788
/root/phpunit/src/Framework/Assert.php:1033
/root/phpunit/tests/unit/Framework/AssertTest.php:660
/root/phpunit/src/Framework/TestCase.php:1527
/root/phpunit/src/Framework/TestCase.php:1133
/root/phpunit/src/Framework/TestResult.php:722
/root/phpunit/src/Framework/TestCase.php:885
/root/phpunit/src/Framework/TestSuite.php:678
/root/phpunit/src/Framework/TestSuite.php:678
/root/phpunit/src/Framework/TestSuite.php:678
/root/phpunit/src/TextUI/TestRunner.php:670
/root/phpunit/src/TextUI/Command.php:143
/root/phpunit/src/TextUI/Command.php:96

5) /root/phpunit/tests/end-to-end/mock-objects/generator/return_type_declarations_generator_empty_by_default.phpt
Failed asserting that string matches format description.
--- Expected
+++ Actual
@@ @@
+Standard input code:15:
array(0) {
}
+Standard input code:16:
array(0) {
}
+Standard input code:17:
array(0) {
}

/root/phpunit/tests/end-to-end/mock-objects/generator/return_type_declarations_generator_empty_by_default.phpt:1
/root/phpunit/src/Framework/TestSuite.php:678
/root/phpunit/src/Framework/TestSuite.php:678
/root/phpunit/src/TextUI/TestRunner.php:670
/root/phpunit/src/TextUI/Command.php:143
/root/phpunit/src/TextUI/Command.php:96

6) /root/phpunit/tests/end-to-end/phpt/expect-location-hint.phpt
Failed asserting that string matches format description.
--- Expected
+++ Actual
@@ @@
+++ Actual
@@ @@
-'Nothing to see here, move along'
-+'Fatal error: Uncaught Error: Call to undefined function some_unknown_function() in %s:2\n
-+Stack trace:\n
-+#0 {main}\n
-+  thrown in %s on line 2'
++'Fatal error: Uncaught Error: Call to undefined function some_unknown_function() in Standard input code on line 2\n
++\n
++Error: Call to undefined function some_unknown_function() in Standard input code on line 2\n
++\n
++Call Stack:\n
++    0.0001     352248   1. {main}() Standard input code:0'

-%stests%eend-to-end%e_files%ephpt-expect-location-hint-example.phpt:9
+/root/phpunit/tests/end-to-end/_files/phpt-expect-location-hint-example.phpt:9

FAILURES!
Tests: 1, Assertions: 1, Failures: 1.