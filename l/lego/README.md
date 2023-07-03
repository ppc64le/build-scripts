Pakckage    : go-acme/lego
Version     : v0.2.5
Source repo : https://github.com/go-acme/lego
Tested on   : UBI 8.5

1. Test cases are passing locally and live test cases are skipping on both power and x86 platforms.
2. Travis check is failing because some of the test cases are trying to make use of ipv6 address, which is not supported on travis. So disabled travis check in the build script.
3. Below is the test result for 3 failing test cases while running travis check:
=== CONT  TestCheckDNSPropagation/success
=== CONT  TestCheckDNSPropagation/no_TXT_record
=== CONT  TestCheckDNSPropagation/success
    precheck_test.go:43: 
        	Error Trace:	/github.com/go-acme/lego/challenge/dns01/precheck_test.go:43
        	Error:      	Received unexpected error:
        	            	read udp [2001:db8::216:3eff:fe85:9f7e]:35246->[2600:9000:5304:4a00::1]:53: i/o timeout
        	Test:       	TestCheckDNSPropagation/success
        	Messages:   	PreCheckDNS failed for postman-echo.com.
    precheck_test.go:44: 
        	Error Trace:	/github.com/go-acme/lego/challenge/dns01/precheck_test.go:44
        	Error:      	Should be true
        	Test:       	TestCheckDNSPropagation/success
        	Messages:   	PreCheckDNS failed for postman-echo.com.
--- FAIL: TestCheckDNSPropagation (0.00s)
    --- PASS: TestCheckDNSPropagation/no_TXT_record (10.04s)
    --- FAIL: TestCheckDNSPropagation/success (10.05s)
=== RUN   TestCheckAuthoritativeNss
=== RUN   TestCheckAuthoritativeNss/TXT_RR_w/_expected_value
=== PAUSE TestCheckAuthoritativeNss/TXT_RR_w/_expected_value
=== RUN   TestCheckAuthoritativeNss/No_TXT_RR
=== PAUSE TestCheckAuthoritativeNss/No_TXT_RR
=== CONT  TestCheckAuthoritativeNss/TXT_RR_w/_expected_value
=== CONT  TestCheckAuthoritativeNss/No_TXT_RR
=== CONT  TestCheckAuthoritativeNss/TXT_RR_w/_expected_value
    precheck_test.go:78: 
        	Error Trace:	/github.com/go-acme/lego/challenge/dns01/precheck_test.go:78
        	Error:      	Not equal: 
        	            	expected: true
        	            	actual  : false
        	Test:       	TestCheckAuthoritativeNss/TXT_RR_w/_expected_value
        	Messages:   	8.8.8.8.asn.routeviews.org.
--- FAIL: TestCheckAuthoritativeNss (0.00s)
    --- PASS: TestCheckAuthoritativeNss/No_TXT_RR (10.12s)
    --- FAIL: TestCheckAuthoritativeNss/TXT_RR_w/_expected_value (10.19s)
=== RUN   TestCheckAuthoritativeNssErr
=== RUN   TestCheckAuthoritativeNssErr/TXT_RR_/w_unexpected_value
=== PAUSE TestCheckAuthoritativeNssErr/TXT_RR_/w_unexpected_value
=== RUN   TestCheckAuthoritativeNssErr/No_TXT_RR
=== PAUSE TestCheckAuthoritativeNssErr/No_TXT_RR
=== CONT  TestCheckAuthoritativeNssErr/TXT_RR_/w_unexpected_value
=== CONT  TestCheckAuthoritativeNssErr/No_TXT_RR
=== CONT  TestCheckAuthoritativeNssErr/TXT_RR_/w_unexpected_value
    precheck_test.go:114: 
        	Error Trace:	/github.com/go-acme/lego/challenge/dns01/precheck_test.go:114
        	Error:      	"read udp [2001:db8::216:3eff:fe85:9f7e]:50756->[2001:468:d01:33::80df:331d]:53: i/o timeout" does not contain "did not return the expected TXT record"
        	Test:       	TestCheckAuthoritativeNssErr/TXT_RR_/w_unexpected_value
=== CONT  TestCheckAuthoritativeNssErr/No_TXT_RR
    precheck_test.go:114: 
        	Error Trace:	/github.com/go-acme/lego/challenge/dns01/precheck_test.go:114
        	Error:      	"read udp [2001:db8::216:3eff:fe85:9f7e]:52474->[2001:4860:4802:34::a]:53: i/o timeout" does not contain "did not return the expected TXT record"
        	Test:       	TestCheckAuthoritativeNssErr/No_TXT_RR
--- FAIL: TestCheckAuthoritativeNssErr (0.00s)
    --- FAIL: TestCheckAuthoritativeNssErr/TXT_RR_/w_unexpected_value (10.00s)
    --- FAIL: TestCheckAuthoritativeNssErr/No_TXT_RR (10.00s)
FAIL
FAIL	github.com/go-acme/lego/v4/challenge/dns01	43.442s