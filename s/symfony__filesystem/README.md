The following test failure was noted for the versions v4.4.17, v4.4.18, v4.4.22, v4.4.27, v5.1.8, v5.2.1, v5.3.4

PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

......S...S..........EEEEFE.S..........SSSS..SSSSS..SE.E..E....  63 / 156 ( 40%)
............................................................E.. 126 / 156 ( 80%)
...........ES.................                                  156 / 156 (100%)

Time: 482 ms, Memory: 6.00 MB

There were 10 errors:

1) Symfony\Component\Filesystem\Tests\FilesystemTest::testRemoveCleansFilesAndDirectoriesIteratively
Error: Call to undefined method Symfony\Component\Filesystem\Tests\FilesystemTest::assertFileDoesNotExist()

/symfony/filesystem/Tests/FilesystemTest.php:287
phpvfscomposer:///symfony/filesystem/vendor/phpunit/phpunit/phpunit:60

2) Symfony\Component\Filesystem\Tests\FilesystemTest::testRemoveCleansArrayOfFilesAndDirectories
Error: Call to undefined method Symfony\Component\Filesystem\Tests\FilesystemTest::assertFileDoesNotExist()

/symfony/filesystem/Tests/FilesystemTest.php:303
phpvfscomposer:///symfony/filesystem/vendor/phpunit/phpunit/phpunit:60

3) Symfony\Component\Filesystem\Tests\FilesystemTest::testRemoveCleansTraversableObjectOfFilesAndDirectories
Error: Call to undefined method Symfony\Component\Filesystem\Tests\FilesystemTest::assertFileDoesNotExist()

/symfony/filesystem/Tests/FilesystemTest.php:320
phpvfscomposer:///symfony/filesystem/vendor/phpunit/phpunit/phpunit:60

4) Symfony\Component\Filesystem\Tests\FilesystemTest::testRemoveIgnoresNonExistingFiles
Error: Call to undefined method Symfony\Component\Filesystem\Tests\FilesystemTest::assertFileDoesNotExist()

/symfony/filesystem/Tests/FilesystemTest.php:336
phpvfscomposer:///symfony/filesystem/vendor/phpunit/phpunit/phpunit:60

5) Symfony\Component\Filesystem\Tests\FilesystemTest::testRemoveCleansInvalidLinks
Error: Call to undefined method Symfony\Component\Filesystem\Tests\FilesystemTest::assertFileDoesNotExist()

/symfony/filesystem/Tests/FilesystemTest.php:382
phpvfscomposer:///symfony/filesystem/vendor/phpunit/phpunit/phpunit:60

6) Symfony\Component\Filesystem\Tests\FilesystemTest::testRename
Error: Call to undefined method Symfony\Component\Filesystem\Tests\FilesystemTest::assertFileDoesNotExist()

/symfony/filesystem/Tests/FilesystemTest.php:776
phpvfscomposer:///symfony/filesystem/vendor/phpunit/phpunit/phpunit:60

7) Symfony\Component\Filesystem\Tests\FilesystemTest::testRenameOverwritesTheTargetIfItAlreadyExists
Error: Call to undefined method Symfony\Component\Filesystem\Tests\FilesystemTest::assertFileDoesNotExist()

/symfony/filesystem/Tests/FilesystemTest.php:802
phpvfscomposer:///symfony/filesystem/vendor/phpunit/phpunit/phpunit:60

8) Symfony\Component\Filesystem\Tests\FilesystemTest::testRemoveSymlink
Error: Call to undefined method Symfony\Component\Filesystem\Tests\FilesystemTest::assertDirectoryDoesNotExist()

/symfony/filesystem/Tests/FilesystemTest.php:848
phpvfscomposer:///symfony/filesystem/vendor/phpunit/phpunit/phpunit:60

9) Symfony\Component\Filesystem\Tests\FilesystemTest::testMirrorContentsWithSameNameAsSourceOrTargetWithDeleteOption
Error: Call to undefined method Symfony\Component\Filesystem\Tests\FilesystemTest::assertFileDoesNotExist()

/symfony/filesystem/Tests/FilesystemTest.php:1328
phpvfscomposer:///symfony/filesystem/vendor/phpunit/phpunit/phpunit:60

10) Symfony\Component\Filesystem\Tests\FilesystemTest::testTempnamWithPHPTempSchemeFails
Error: Call to undefined method Symfony\Component\Filesystem\Tests\FilesystemTest::assertFileDoesNotExist()

/symfony/filesystem/Tests/FilesystemTest.php:1461
phpvfscomposer:///symfony/filesystem/vendor/phpunit/phpunit/phpunit:60

--

There was 1 failure:

1) Symfony\Component\Filesystem\Tests\FilesystemTest::testRemoveThrowsExceptionOnPermissionDenied
Filesystem::remove() should throw an exception

/symfony/filesystem/Tests/FilesystemTest.php:351
phpvfscomposer:///symfony/filesystem/vendor/phpunit/phpunit/phpunit:60

ERRORS!
Tests: 156, Assertions: 262, Errors: 10, Failures: 1, Skipped: 14.
------------------symfony/filesystem:install_success_but_test_fails---------------------
https://github.com/symfony/filesystem symfony/filesystem
symfony/filesystem  |  https://github.com/symfony/filesystem | v4.4.18 | "Red Hat Enterprise Linux 8.5 (Ootpa)" | GitHub | Fail |  Install_success_but_test_Fails
