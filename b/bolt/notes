Pakckage : bolt
Version  : 1.3.1
Git URL  : https://github.com/boltdb/bolt

As the bolt package is deprecated and last it was build with go version 1.7.x in year 2017, hence we have also tested with the same go version (1.7.4)

Below is the test result:

1. Bolt package is successfully build and tested on Linux x86_64 architecture.
2. Bolt package is successfully build on ppc64le power architecture but few tests are failing.

	FAIL: TestBucket_Stats (28.53s)
	        bucket_test.go:1172: unexpected BranchPageN: 0
	FAIL: TestBucket_Stats_Large (13.97s)
	        bucket_test.go:1551: unexpected BranchPageN: 1

3. Few tests are skipped.

	SKIP: TestBucket_Stats_RandomFill (0.00s)
        	bucket_test.go:1228: invalid page size for test
	SKIP: TestOpen_ErrVersionMismatch (0.00s)
        	db_test.go:111: page size mismatch
	SKIP: TestOpen_ErrChecksum (0.00s)
        	db_test.go:148: page size mismatch
	SKIP: TestOpen_MetaInitWriteError (0.00s)
        	db_test.go:339: pending

4. On power architecture ppc64le few tests are taking longer time, more than 1-2 hours. Hence we ran the tests with -timeout 3h option.

As the bolt package was build years ago and deprecated, we are not spending much time to investigate the failure of tests.

