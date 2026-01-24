Package     : sap/go-hdb
Version     : v0.14.1
Source repo : https://github.com/sap/go-hdb
Tested on   : UBI 8.5


1. For requested version test cases(both integration and unit test cases) has dependency on HANA database.


2. For requested version(v0.14.1) below test case is failing on power, which is in parity with Intel.  
    main_test.go:55: parse "hdb://user:password@ip_address:port": invalid port ":port" after host
    FAIL    github.com/SAP/go-hdb/driver    0.004s


3. For latest version(v0.108.1) and top of the tree unit test cases are passing as unit test cases do not have dependency on HANA database.
   go test --tags unit ./...
