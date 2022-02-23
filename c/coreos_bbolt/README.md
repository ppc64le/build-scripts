Test cases failure details for version v1.3.4

panic: test timed out after 10m0s

goroutine 161921 [running]:
testing.(*M).startAlarm.func1()
        /usr/bin/go/src/testing/testing.go:1788 +0xcc
created by time.goFunc
        /usr/bin/go/src/time/sleep.go:180 +0x44

goroutine 1 [chan receive, 1 minutes]:
testing.(*T).Run(0xc000110d00, {0x1ac834, 0x26}, 0x1b04f8)
        /usr/bin/go/src/testing/testing.go:1307 +0x38c
testing.runTests.func1(0xc000110d00)
        /usr/bin/go/src/testing/testing.go:1598 +0x88
testing.tRunner(0xc000110d00, 0xc00009cbc0)
        /usr/bin/go/src/testing/testing.go:1259 +0xf0
testing.runTests(0xc000126018, {0x2cc420, 0xab, 0xab}, {0xc07da2c5568df3f1, 0x8bb2d3a4ff, 0x2cf1e0})
        /usr/bin/go/src/testing/testing.go:1596 +0x430
testing.(*M).Run(0xc000140000)
        /usr/bin/go/src/testing/testing.go:1504 +0x514
go.etcd.io/bbolt_test.TestMain(0xc000140000)
        /home/tester/bbolt/quick_test.go:37 +0x44c
main.main()
        _testmain.go:421 +0x164

goroutine 161900 [semacquire]:
sync.runtime_SemacquireMutex(0xc031c225b4, 0x0, 0x1)
        /usr/bin/go/src/runtime/sema.go:71 +0x44
sync.(*Mutex).lockSlow(0xc031c225b0)
        /usr/bin/go/src/sync/mutex.go:138 +0x19c
sync.(*Mutex).Lock(...)
        /usr/bin/go/src/sync/mutex.go:81
go.etcd.io/bbolt.(*DB).beginRWTx(0xc031c22400)
        /home/tester/bbolt/db.go:593 +0x9c
go.etcd.io/bbolt.(*DB).Begin(0xc031c22400, 0x1)
        /home/tester/bbolt/db.go:542 +0x38
go.etcd.io/bbolt_test.testSimulate.func1(0xc041199e20, 0xc041199e30, 0xc019392a00, 0xc03d028900, 0xc021b6df08, 0xc02cd085a0, 0xc041199e38, 0xc04bdf7650, 0x1, 0x1b06a8)
        /home/tester/bbolt/simulation_test.go:89 +0x88
created by go.etcd.io/bbolt_test.testSimulate
        /home/tester/bbolt/simulation_test.go:85 +0x4f0

goroutine 99091 [chan send]:
go.etcd.io/bbolt_test.testSimulate(0xc0018b49c0, 0xc0000100a0, 0x8, 0x2710, 0xa)
        /home/tester/bbolt/simulation_test.go:69 +0x3c0
go.etcd.io/bbolt_test.TestSimulateNoFreeListSync_10000op_10p(0xc0018b49c0)
        /home/tester/bbolt/simulation_no_freelist_sync_test.go:34 +0x64
testing.tRunner(0xc0018b49c0, 0x1b04f8)
        /usr/bin/go/src/testing/testing.go:1259 +0xf0
created by testing.(*T).Run
        /usr/bin/go/src/testing/testing.go:1306 +0x370

goroutine 161899 [semacquire]:
sync.runtime_SemacquireMutex(0xc031c225b4, 0x0, 0x1)
        /usr/bin/go/src/runtime/sema.go:71 +0x44
sync.(*Mutex).lockSlow(0xc031c225b0)
        /usr/bin/go/src/sync/mutex.go:138 +0x19c
sync.(*Mutex).Lock(...)
        /usr/bin/go/src/sync/mutex.go:81
go.etcd.io/bbolt.(*DB).beginRWTx(0xc031c22400)
        /home/tester/bbolt/db.go:593 +0x9c
go.etcd.io/bbolt.(*DB).Begin(0xc031c22400, 0x1)
        /home/tester/bbolt/db.go:542 +0x38
go.etcd.io/bbolt_test.testSimulate.func1(0xc041199e20, 0xc041199e30, 0xc019392a00, 0xc03d028900, 0xc021b6df08, 0xc02cd085a0, 0xc041199e38, 0xc04bdf7650, 0x1, 0x1b06a8)
        /home/tester/bbolt/simulation_test.go:89 +0x88
created by go.etcd.io/bbolt_test.testSimulate
        /home/tester/bbolt/simulation_test.go:85 +0x4f0

goroutine 161894 [semacquire]:
sync.runtime_SemacquireMutex(0xc031c225b4, 0x0, 0x1)
        /usr/bin/go/src/runtime/sema.go:71 +0x44
sync.(*Mutex).lockSlow(0xc031c225b0)
        /usr/bin/go/src/sync/mutex.go:138 +0x19c
sync.(*Mutex).Lock(...)
        /usr/bin/go/src/sync/mutex.go:81
go.etcd.io/bbolt.(*DB).beginRWTx(0xc031c22400)
        /home/tester/bbolt/db.go:593 +0x9c
go.etcd.io/bbolt.(*DB).Begin(0xc031c22400, 0x1)
        /home/tester/bbolt/db.go:542 +0x38
go.etcd.io/bbolt_test.testSimulate.func1(0xc041199e20, 0xc041199e30, 0xc019392a00, 0xc03d028900, 0xc021b6df08, 0xc02cd085a0, 0xc041199e38, 0xc04bdf7650, 0x1, 0x1b06a0)
        /home/tester/bbolt/simulation_test.go:89 +0x88
created by go.etcd.io/bbolt_test.testSimulate
        /home/tester/bbolt/simulation_test.go:85 +0x4f0

goroutine 161901 [semacquire]:
sync.runtime_SemacquireMutex(0xc031c225b4, 0x0, 0x1)
        /usr/bin/go/src/runtime/sema.go:71 +0x44
sync.(*Mutex).lockSlow(0xc031c225b0)
        /usr/bin/go/src/sync/mutex.go:138 +0x19c
sync.(*Mutex).Lock(...)
        /usr/bin/go/src/sync/mutex.go:81
go.etcd.io/bbolt.(*DB).beginRWTx(0xc031c22400)
        /home/tester/bbolt/db.go:593 +0x9c
go.etcd.io/bbolt.(*DB).Begin(0xc031c22400, 0x1)
        /home/tester/bbolt/db.go:542 +0x38
go.etcd.io/bbolt_test.testSimulate.func1(0xc041199e20, 0xc041199e30, 0xc019392a00, 0xc03d028900, 0xc021b6df08, 0xc02cd085a0, 0xc041199e38, 0xc04bdf7650, 0x1, 0x1b06a0)
        /home/tester/bbolt/simulation_test.go:89 +0x88
created by go.etcd.io/bbolt_test.testSimulate
        /home/tester/bbolt/simulation_test.go:85 +0x4f0

goroutine 161908 [semacquire]:
sync.runtime_SemacquireMutex(0xc031c225b4, 0x0, 0x1)
        /usr/bin/go/src/runtime/sema.go:71 +0x44
sync.(*Mutex).lockSlow(0xc031c225b0)
        /usr/bin/go/src/sync/mutex.go:138 +0x19c
sync.(*Mutex).Lock(...)
        /usr/bin/go/src/sync/mutex.go:81
go.etcd.io/bbolt.(*DB).beginRWTx(0xc031c22400)
        /home/tester/bbolt/db.go:593 +0x9c
go.etcd.io/bbolt.(*DB).Begin(0xc031c22400, 0x1)
        /home/tester/bbolt/db.go:542 +0x38
go.etcd.io/bbolt_test.testSimulate.func1(0xc041199e20, 0xc041199e30, 0xc019392a00, 0xc03d028900, 0xc021b6df08, 0xc02cd085a0, 0xc041199e38, 0xc04bdf7650, 0x1, 0x1b06a0)
        /home/tester/bbolt/simulation_test.go:89 +0x88
created by go.etcd.io/bbolt_test.testSimulate
        /home/tester/bbolt/simulation_test.go:85 +0x4f0

goroutine 161876 [semacquire]:
sync.runtime_SemacquireMutex(0xc031c225b4, 0x0, 0x1)
        /usr/bin/go/src/runtime/sema.go:71 +0x44
sync.(*Mutex).lockSlow(0xc031c225b0)
        /usr/bin/go/src/sync/mutex.go:138 +0x19c
sync.(*Mutex).Lock(...)
        /usr/bin/go/src/sync/mutex.go:81
go.etcd.io/bbolt.(*DB).beginRWTx(0xc031c22400)
        /home/tester/bbolt/db.go:593 +0x9c
go.etcd.io/bbolt.(*DB).Begin(0xc031c22400, 0x1)
        /home/tester/bbolt/db.go:542 +0x38
go.etcd.io/bbolt_test.testSimulate.func1(0xc041199e20, 0xc041199e30, 0xc019392a00, 0xc03d028900, 0xc021b6df08, 0xc02cd085a0, 0xc041199e38, 0xc04bdf7650, 0x1, 0x1b06a8)
        /home/tester/bbolt/simulation_test.go:89 +0x88
created by go.etcd.io/bbolt_test.testSimulate
        /home/tester/bbolt/simulation_test.go:85 +0x4f0

goroutine 161864 [runnable]:
sync.runtime_SemacquireMutex(0xc031c225b4, 0x0, 0x1)
        /usr/bin/go/src/runtime/sema.go:71 +0x44
sync.(*Mutex).lockSlow(0xc031c225b0)
        /usr/bin/go/src/sync/mutex.go:138 +0x19c
sync.(*Mutex).Lock(...)
        /usr/bin/go/src/sync/mutex.go:81
go.etcd.io/bbolt.(*DB).beginRWTx(0xc031c22400)
        /home/tester/bbolt/db.go:593 +0x9c
go.etcd.io/bbolt.(*DB).Begin(0xc031c22400, 0x1)
        /home/tester/bbolt/db.go:542 +0x38
go.etcd.io/bbolt_test.testSimulate.func1(0xc041199e20, 0xc041199e30, 0xc019392a00, 0xc03d028900, 0xc021b6df08, 0xc02cd085a0, 0xc041199e38, 0xc04bdf7650, 0x1, 0x1b06a8)
        /home/tester/bbolt/simulation_test.go:89 +0x88
created by go.etcd.io/bbolt_test.testSimulate
        /home/tester/bbolt/simulation_test.go:85 +0x4f0

goroutine 161904 [semacquire]:
sync.runtime_SemacquireMutex(0xc031c225b4, 0x0, 0x1)
        /usr/bin/go/src/runtime/sema.go:71 +0x44
sync.(*Mutex).lockSlow(0xc031c225b0)
        /usr/bin/go/src/sync/mutex.go:138 +0x19c
sync.(*Mutex).Lock(...)
        /usr/bin/go/src/sync/mutex.go:81
go.etcd.io/bbolt.(*DB).beginRWTx(0xc031c22400)
        /home/tester/bbolt/db.go:593 +0x9c
go.etcd.io/bbolt.(*DB).Begin(0xc031c22400, 0x1)
        /home/tester/bbolt/db.go:542 +0x38
go.etcd.io/bbolt_test.testSimulate.func1(0xc041199e20, 0xc041199e30, 0xc019392a00, 0xc03d028900, 0xc021b6df08, 0xc02cd085a0, 0xc041199e38, 0xc04bdf7650, 0x1, 0x1b06a0)
        /home/tester/bbolt/simulation_test.go:89 +0x88
created by go.etcd.io/bbolt_test.testSimulate
        /home/tester/bbolt/simulation_test.go:85 +0x4f0

goroutine 161910 [semacquire]:
sync.runtime_SemacquireMutex(0xc031c225b4, 0x0, 0x1)
        /usr/bin/go/src/runtime/sema.go:71 +0x44
sync.(*Mutex).lockSlow(0xc031c225b0)
        /usr/bin/go/src/sync/mutex.go:138 +0x19c
sync.(*Mutex).Lock(...)
        /usr/bin/go/src/sync/mutex.go:81
go.etcd.io/bbolt.(*DB).beginRWTx(0xc031c22400)
        /home/tester/bbolt/db.go:593 +0x9c
go.etcd.io/bbolt.(*DB).Begin(0xc031c22400, 0x1)
        /home/tester/bbolt/db.go:542 +0x38
go.etcd.io/bbolt_test.testSimulate.func1(0xc041199e20, 0xc041199e30, 0xc019392a00, 0xc03d028900, 0xc021b6df08, 0xc02cd085a0, 0xc041199e38, 0xc04bdf7650, 0x1, 0x1b06a0)
        /home/tester/bbolt/simulation_test.go:89 +0x88
created by go.etcd.io/bbolt_test.testSimulate
        /home/tester/bbolt/simulation_test.go:85 +0x4f0

goroutine 161898 [semacquire]:
sync.runtime_SemacquireMutex(0xc031c225b4, 0x0, 0x1)
        /usr/bin/go/src/runtime/sema.go:71 +0x44
sync.(*Mutex).lockSlow(0xc031c225b0)
        /usr/bin/go/src/sync/mutex.go:138 +0x19c
sync.(*Mutex).Lock(...)
        /usr/bin/go/src/sync/mutex.go:81
go.etcd.io/bbolt.(*DB).beginRWTx(0xc031c22400)
        /home/tester/bbolt/db.go:593 +0x9c
go.etcd.io/bbolt.(*DB).Begin(0xc031c22400, 0x1)
        /home/tester/bbolt/db.go:542 +0x38
go.etcd.io/bbolt_test.testSimulate.func1(0xc041199e20, 0xc041199e30, 0xc019392a00, 0xc03d028900, 0xc021b6df08, 0xc02cd085a0, 0xc041199e38, 0xc04bdf7650, 0x1, 0x1b06a8)
        /home/tester/bbolt/simulation_test.go:89 +0x88
created by go.etcd.io/bbolt_test.testSimulate
        /home/tester/bbolt/simulation_test.go:85 +0x4f0
FAIL    go.etcd.io/bbolt        600.056s
?       go.etcd.io/bbolt/cmd/bbolt      [no test files]
FAIL


