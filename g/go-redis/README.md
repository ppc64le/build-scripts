Test failures observed on Intel and POWER:
------------------------------------------
```
Summarizing 3 Failures:

[Fail] Commands server [It] should Command
/root/redis/commands_test.go:251

[Fail] ClusterClient ClusterClient failover [BeforeEach] supports Pipeline hook
/root/redis/cluster_test.go:889

[Fail] ClusterClient ClusterClient with RouteByLatency [BeforeEach] supports WithContext
/root/redis/cluster_test.go:939

Ran 436 of 439 Specs in 212.680 seconds
FAIL! -- 433 Passed | 3 Failed | 1 Pending | 2 Skipped
```
