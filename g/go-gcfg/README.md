Pakckage    : go-gcfg/gcfg
Version     : v1.2.3, v1.2.0
Source repo : https://github.com/go-gcfg/gcfg
Tested on   : UBI 8.5

1. Below is the test result for 2 failing test cases for both versions:

=== RUN   TestParseInt
    int_test.go:63: ParseInt(int, "0", IntMode(Dec)): pass; got 0, error <nil>
    int_test.go:63: ParseInt(int, "10", IntMode(Dec)): pass; got 10, error <nil>
    int_test.go:63: ParseInt(int, "-10", IntMode(Dec)): pass; got -10, error <nil>
    int_test.go:63: ParseInt(int, "x", IntMode(Dec)): pass; got 0, error failed to parse "x" as int: expected integer
    int_test.go:63: ParseInt(int, "0xa", IntMode(Hex)): pass; got 10, error <nil>
    int_test.go:63: ParseInt(int, "a", IntMode(Hex)): pass; got 10, error <nil>
    int_test.go:63: ParseInt(int, "10", IntMode(Hex)): pass; got 16, error <nil>
    int_test.go:63: ParseInt(int, "-0xa", IntMode(Hex)): pass; got -10, error <nil>
    int_test.go:54: ParseInt(int, "0x", IntMode(Hex)): fail; got error failed to parse "0x" as int: strconv.ParseInt: parsing "0x": invalid syntax, want ok
    int_test.go:54: ParseInt(int, "-0x", IntMode(Hex)): fail; got error failed to parse "-0x" as int: strconv.ParseInt: parsing "-0x": invalid syntax, want ok
    int_test.go:63: ParseInt(int, "-a", IntMode(Hex)): pass; got -10, error <nil>
    int_test.go:63: ParseInt(int, "-10", IntMode(Hex)): pass; got -16, error <nil>
    int_test.go:63: ParseInt(int, "x", IntMode(Hex)): pass; got 0, error failed to parse "x" as int: expected integer
    int_test.go:63: ParseInt(int, "10", IntMode(Oct)): pass; got 8, error <nil>
    int_test.go:63: ParseInt(int, "010", IntMode(Oct)): pass; got 8, error <nil>
    int_test.go:63: ParseInt(int, "-10", IntMode(Oct)): pass; got -8, error <nil>
    int_test.go:63: ParseInt(int, "-010", IntMode(Oct)): pass; got -8, error <nil>
    int_test.go:63: ParseInt(int, "10", IntMode(Dec|Hex)): pass; got 10, error <nil>
    int_test.go:63: ParseInt(int, "010", IntMode(Dec|Hex)): pass; got 10, error <nil>
    int_test.go:63: ParseInt(int, "0x10", IntMode(Dec|Hex)): pass; got 16, error <nil>
    int_test.go:63: ParseInt(int, "10", IntMode(Dec|Oct)): pass; got 10, error <nil>
    int_test.go:63: ParseInt(int, "010", IntMode(Dec|Oct)): pass; got 8, error <nil>
    int_test.go:63: ParseInt(int, "0x10", IntMode(Dec|Oct)): pass; got 0, error failed to parse "0x10" as int: extra characters "x10"
    int_test.go:63: ParseInt(int, "10", IntMode(Hex|Oct)): pass; got 0, error ambiguous integer value; must include '0' prefix
    int_test.go:63: ParseInt(int, "010", IntMode(Hex|Oct)): pass; got 8, error <nil>
    int_test.go:63: ParseInt(int, "0x10", IntMode(Hex|Oct)): pass; got 16, error <nil>
    int_test.go:63: ParseInt(int, "10", IntMode(Dec|Hex|Oct)): pass; got 10, error <nil>
    int_test.go:63: ParseInt(int, "010", IntMode(Dec|Hex|Oct)): pass; got 8, error <nil>
    int_test.go:63: ParseInt(int, "0x10", IntMode(Dec|Hex|Oct)): pass; got 16, error <nil>
--- FAIL: TestParseInt (0.00s)
=== RUN   TestScanFully
    scan_test.go:32: ScanFully(*int, "a", 'v') = failed to parse "a" as int: expected integer; *ptr==0
    scan_test.go:23: ScanFully(*int, "0x", 'v'): want ok, got error failed to parse "0x" as int: strconv.ParseInt: parsing "0x": invalid syntax
    scan_test.go:32: ScanFully(*int, "0x", 'd') = failed to parse "0x" as int: extra characters "x"; *ptr==0
--- FAIL: TestScanFully (0.00s)

2. Observed that same test cases are failing on Intel as well. 
3. Above test failures are fixed for top of the tree i.e.v1.
4. Test failures fix link: https://github.com/go-gcfg/gcfg/pull/20/commits/1185e641ea2aa19d732dd9d7cd0d36599d6fe22d.