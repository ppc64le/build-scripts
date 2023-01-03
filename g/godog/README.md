Pakckage    : godog
Version     : v0.7.4
Source repo : https://github.com/cucumber/godog
Tested on   : UBI 8.5

1. Below is the test result for 1 failing test case:
Randomized with seed: 1662458468419065342
=== RUN   TestShouldGetSingleContextFromSource
--- PASS: TestShouldGetSingleContextFromSource (0.00s)
=== RUN   TestShouldGetTwoContextsFromSource
--- PASS: TestShouldGetTwoContextsFromSource (0.00s)
=== RUN   TestShouldNotFindAnyContextsInEmptyFile
--- PASS: TestShouldNotFindAnyContextsInEmptyFile (0.00s)
=== RUN   TestVendorPaths
--- PASS: TestVendorPaths (0.00s)
=== RUN   TestBuildTestRunner
    builder_test.go:43: failed to build godog test binary: open /tmp/go-build812443552/github.com/DATA-DOG/godog/_test/_testmain.go: no such file or directory
--- FAIL: TestBuildTestRunner (0.76s)
=== RUN   TestBuildTestRunnerWithoutGoFiles
--- PASS: TestBuildTestRunnerWithoutGoFiles (0.50s)
=== RUN   TestFlagsShouldRandomizeAndGenerateSeed
--- PASS: TestFlagsShouldRandomizeAndGenerateSeed (0.00s)
=== RUN   TestFlagsShouldRandomizeByGivenSeed
--- PASS: TestFlagsShouldRandomizeByGivenSeed (0.00s)
=== RUN   TestFlagsShouldParseFormat
--- PASS: TestFlagsShouldParseFormat (0.00s)
=== RUN   TestFlagsUsageShouldIncludeFormatDescriptons
--- PASS: TestFlagsUsageShouldIncludeFormatDescriptons (0.00s)
=== RUN   TestJUnitFormatterOutput
--- PASS: TestJUnitFormatterOutput (0.00s)
=== RUN   TestProgressFormatterOutput
--- PASS: TestProgressFormatterOutput (0.00s)
=== RUN   TestProgressFormatterWhenStepPanics
--- PASS: TestProgressFormatterWhenStepPanics (0.00s)
=== RUN   TestProgressFormatterWithPassingMultisteps
--- PASS: TestProgressFormatterWithPassingMultisteps (0.00s)
=== RUN   TestProgressFormatterWithFailingMultisteps
--- PASS: TestProgressFormatterWithFailingMultisteps (0.00s)
=== RUN   TestProgressFormatterWithPanicInMultistep
--- PASS: TestProgressFormatterWithPanicInMultistep (0.00s)
=== RUN   TestProgressFormatterMultistepTemplates
--- PASS: TestProgressFormatterMultistepTemplates (0.00s)
=== RUN   TestProgressFormatterWhenMultiStepHasArgument
--- PASS: TestProgressFormatterWhenMultiStepHasArgument (0.00s)
=== RUN   TestProgressFormatterWhenMultiStepHasStepWithArgument
--- PASS: TestProgressFormatterWhenMultiStepHasStepWithArgument (0.00s)
=== RUN   TestShouldFindFormatter
--- PASS: TestShouldFindFormatter (0.00s)
=== RUN   TestPrintsStepDefinitions
--- PASS: TestPrintsStepDefinitions (0.00s)
=== RUN   TestPrintsNoStepDefinitionsIfNoneFound
--- PASS: TestPrintsNoStepDefinitionsIfNoneFound (0.00s)
=== RUN   TestFailsOrPassesBasedOnStrictModeWhenHasPendingSteps
--- PASS: TestFailsOrPassesBasedOnStrictModeWhenHasPendingSteps (0.00s)
=== RUN   TestFailsOrPassesBasedOnStrictModeWhenHasUndefinedSteps
--- PASS: TestFailsOrPassesBasedOnStrictModeWhenHasUndefinedSteps (0.00s)
=== RUN   TestShouldFailOnError
--- PASS: TestShouldFailOnError (0.00s)
=== RUN   TestFailsWithConcurrencyOptionError
--- PASS: TestFailsWithConcurrencyOptionError (0.00s)
=== RUN   TestFailsWithUnknownFormatterOptionError
--- PASS: TestFailsWithUnknownFormatterOptionError (0.00s)
=== RUN   TestFailsWithOptionErrorWhenLookingForFeaturesInUnavailablePath
--- PASS: TestFailsWithOptionErrorWhenLookingForFeaturesInUnavailablePath (0.00s)
=== RUN   TestByDefaultRunsFeaturesPath
--- PASS: TestByDefaultRunsFeaturesPath (0.02s)
=== RUN   TestStacktrace
--- PASS: TestStacktrace (0.00s)
=== RUN   TestShouldSupportIntTypes
--- PASS: TestShouldSupportIntTypes (0.00s)
=== RUN   TestShouldSupportFloatTypes
--- PASS: TestShouldSupportFloatTypes (0.00s)
=== RUN   TestShouldNotSupportOtherPointerTypesThanGherkin
--- PASS: TestShouldNotSupportOtherPointerTypesThanGherkin (0.00s)
=== RUN   TestShouldSupportOnlyByteSlice
--- PASS: TestShouldSupportOnlyByteSlice (0.00s)
=== RUN   TestUnexpectedArguments
--- PASS: TestUnexpectedArguments (0.00s)
=== RUN   TestTagFilter
--- PASS: TestTagFilter (0.00s)
=== RUN   TestTimeNowFunc
--- PASS: TestTimeNowFunc (0.00s)
FAIL

2. Observed that same test case is failing on Intel as well.
3. While building godog test binary it's looking for the path /tmp/go-build624939915/github.com/DATA-DOG/godog/_test/_testmain.go and currently this package is not available in the path https://github.com/data-dog/godogas as it's redirected to path https://github.com/cucumber/godog, so one test case is failing.