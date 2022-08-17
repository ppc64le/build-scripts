Pakckage    : swag
Version     : f3f9494671f93fcff853e3c6e9e948b3eb71e590
Source repo : https://github.com/go-openapi/swag
Tested on   : UBI 8.5

1. Below is the test result for one failing test case:
		
=== RUN   TestToGoName
    util_test.go:61:
                Error Trace:    /home/tester/go/src/github.com/go-openapi/strfmt/gojsonpointer/gojsonpointer/jsonreference/swag/swag/util_test.go:61
                Error:          Not equal:
                                expected: "X日本語sample2Text"
                                actual  : "X�\xbf\xbd��本語sample2Text"

                                Diff:
                                --- Expected
                                +++ Actual
                                @@ -1 +1 @@
                                -X日本語sample2Text
                                +X�▒▒��本語sample2Text
                Test:           TestToGoName
    util_test.go:61:
                Error Trace:    /home/tester/go/src/github.com/go-openapi/strfmt/gojsonpointer/gojsonpointer/jsonreference/swag/swag/util_test.go:61
                Error:          Not equal:
                                expected: "X日本語findThingByID"
                                actual  : "X�\xbf\xbd��本語findThingByID"

                                Diff:
                                --- Expected
                                +++ Actual
                                @@ -1 +1 @@
                                -X日本語findThingByID
                                +X�▒▒��本語findThingByID
                Test:           TestToGoName
--- FAIL: TestToGoName (0.21s)

2. Observed that one failing test case is in parity with Intel. 
3. Also noticed some code changes between the version f3f9494671f93fcff853e3c6e9e948b3eb71e590 and latest version i.e. v0.22.1, moreover one failing test case is fixed for the latest version i.e. v0.22.1.


