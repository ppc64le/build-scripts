Pakckage : bbolt 
Version : 1.3.3
Git URL : https://github.com/etcd-io/bbolt

Below is the test result:

Bolt package is successfully build and tested on Linux x86_64 architecture.

Bolt package is successfully build on ppc64le power architecture but few tests are failing.

FAIL: 

FAIL: TestBucket_Delete_FreelistOverflow (2613.18s)
    bucket_test.go:432: expected more than 0xFFFF free pages, got 9791

FAIL: TestBucket_Stats (62.54s)
    bucket_test.go:1222: unexpected BranchPageN: 0

FAIL: TestBucket_Stats_Large (19.84s)
    bucket_test.go:1601: unexpected BranchPageN: 1

FAIL: TestDB_Close_PendingTx_RO (0.31s)
    db_test.go:732: database did not close

On linux x86_64 all tests are passing.
On power architecture ppc64le few tests are taking longer time, more than 1-2 hours. Hence we ran the tests with -timeout 3h option.

