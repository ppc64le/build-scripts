 Test cases failure details for version v1.1.1
  -----
 ` ` `=== RUN   TestGolden
    golden_test.go:399: RUNNING:  protoc-min-version --version=3.0.0 -Itestdata --gogo_out=plugins=grpc,paths=source_relative:/tmp/proto-test012098502 testdata/imports/test_import_a1m1.proto testdata/imports/test_import_a1m2.proto testdata/imports/test_import_all.proto
    golden_test.go:402: panic: version string returned from protoc is seperated with a space:

        goroutine 1 [running]:
        github.com/gogo/protobuf/version.Get(0x5071c, 0x7fffdee9fd1a)
                /root/protobuf/version/version.go:43 +0x16c
        github.com/gogo/protobuf/version.AtLeast(0x7fffdee9fd1a, 0x5, 0x6)
                /root/protobuf/version/version.go:77 +0x24
        main.main()
                /root/protobuf/protoc-min-version/minversion.go:56 +0xa8

    golden_test.go:405: protoc: exit status 2
--- FAIL: TestGolden (0.04s)
=== RUN   TestParameters
    golden_test.go:219: TEST: defaults
    golden_test.go:399: RUNNING:  protoc-min-version --version=3.0.0 -I/tmp/proto-test840296045 --gogo_out=:/tmp/proto-test840296045/out /tmp/proto-test840296045/alpha/a.proto
    golden_test.go:402: panic: version string returned from protoc is seperated with a space:

        goroutine 1 [running]:
        github.com/gogo/protobuf/version.Get(0x5071c, 0x7ffff8d7fd78)
                /root/protobuf/version/version.go:43 +0x16c
        github.com/gogo/protobuf/version.AtLeast(0x7ffff8d7fd78, 0x5, 0x4)
                /root/protobuf/version/version.go:77 +0x24
        main.main()
                /root/protobuf/protoc-min-version/minversion.go:56 +0xa8

    golden_test.go:405: protoc: exit status 2
--- FAIL: TestParameters (0.04s)
=== RUN   TestPackageComment
    golden_test.go:399: RUNNING:  protoc-min-version --version=3.0.0 -I/tmp/proto-test242094312 --gogo_out=paths=source_relative:/tmp/proto-test242094312 /tmp/proto-test242094312/0.proto
    golden_test.go:402: panic: version string returned from protoc is seperated with a space:

        goroutine 1 [running]:
        github.com/gogo/protobuf/version.Get(0x5071c, 0x7fffcb81fd6d)
                /root/protobuf/version/version.go:43 +0x16c
        github.com/gogo/protobuf/version.AtLeast(0x7fffcb81fd6d, 0x5, 0x4)
                /root/protobuf/version/version.go:77 +0x24
        main.main()
                /root/protobuf/protoc-min-version/minversion.go:56 +0xa8

    golden_test.go:405: protoc: exit status 2
--- FAIL: TestPackageComment (0.03s)
FAIL
FAIL    github.com/gogo/protobuf/protoc-gen-gogo ` ` ` 