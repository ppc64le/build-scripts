## Test failures observed on Intel and POWER:

### Failing testsuites:
- `FAIL packages/jest-circus/src/__tests__/baseTest.test.ts`
- `FAIL packages/jest-circus/src/__tests__/hooks.test.ts `
- `FAIL packages/jest-circus/src/__tests__/afterAll.test.ts`

### Full log:
``` 
PASS packages/jest-circus/src/__tests__/circusItTestError.test.ts (5.103 s)
PASS packages/jest-circus/src/__tests__/circusItTodoTestError.test.ts (5.214 s)
PASS packages/jest-circus/src/__tests__/hooksError.test.ts (5.237 s)
FAIL packages/jest-circus/src/__tests__/baseTest.test.ts (7.087 s)
  ● simple test


          Unexpected stderr:
          Browserslist: caniuse-lite is outdated. Please run:
    npx browserslist@latest --update-db

    Why you should do it regularly:
    https://github.com/browserslist/browserslist#browsers-data-updating

          
      at runTest (packages/jest-circus/src/__mocks__/testUtils.ts:82:11)

  ● failures


          Unexpected stderr:
          Browserslist: caniuse-lite is outdated. Please run:
    npx browserslist@latest --update-db

    Why you should do it regularly:
    https://github.com/browserslist/browserslist#browsers-data-updating

          
      at runTest (packages/jest-circus/src/__mocks__/testUtils.ts:82:11)

FAIL packages/jest-circus/src/__tests__/hooks.test.ts (8.251 s)
  ● beforeEach is executed before each test in current/child describe blocks


          Unexpected stderr:
          Browserslist: caniuse-lite is outdated. Please run:
    npx browserslist@latest --update-db

    Why you should do it regularly:
    https://github.com/browserslist/browserslist#browsers-data-updating

          
      at runTest (packages/jest-circus/src/__mocks__/testUtils.ts:82:11)

  ● multiple before each hooks in one describe are executed in the right order


          Unexpected stderr:
          Browserslist: caniuse-lite is outdated. Please run:
    npx browserslist@latest --update-db

    Why you should do it regularly:
    https://github.com/browserslist/browserslist#browsers-data-updating

          
      at runTest (packages/jest-circus/src/__mocks__/testUtils.ts:82:11)

  ● beforeAll is exectued correctly


          Unexpected stderr:
          Browserslist: caniuse-lite is outdated. Please run:
    npx browserslist@latest --update-db

    Why you should do it regularly:
    https://github.com/browserslist/browserslist#browsers-data-updating

          
      at runTest (packages/jest-circus/src/__mocks__/testUtils.ts:82:11)

FAIL packages/jest-circus/src/__tests__/afterAll.test.ts (11.723 s)
  ● tests are not marked done until their parent afterAll runs


          Unexpected stderr:
          Browserslist: caniuse-lite is outdated. Please run:
    npx browserslist@latest --update-db

    Why you should do it regularly:
    https://github.com/browserslist/browserslist#browsers-data-updating

          
      at runTest (packages/jest-circus/src/__mocks__/testUtils.ts:82:11)

  ● describe block cannot have hooks and no tests


          Unexpected stderr:
          Browserslist: caniuse-lite is outdated. Please run:
    npx browserslist@latest --update-db

    Why you should do it regularly:
    https://github.com/browserslist/browserslist#browsers-data-updating

          
      at runTest (packages/jest-circus/src/__mocks__/testUtils.ts:82:11)

  ● describe block _can_ have hooks if a child describe block has tests


          Unexpected stderr:
          Browserslist: caniuse-lite is outdated. Please run:
    npx browserslist@latest --update-db

    Why you should do it regularly:
    https://github.com/browserslist/browserslist#browsers-data-updating

          
      at runTest (packages/jest-circus/src/__mocks__/testUtils.ts:82:11)

  ● describe block hooks must not run if describe block is skipped


          Unexpected stderr:
          Browserslist: caniuse-lite is outdated. Please run:
    npx browserslist@latest --update-db

    Why you should do it regularly:
    https://github.com/browserslist/browserslist#browsers-data-updating

          
      at runTest (packages/jest-circus/src/__mocks__/testUtils.ts:82:11)

  ● child tests marked with todo should not run if describe block is skipped


          Unexpected stderr:
          Browserslist: caniuse-lite is outdated. Please run:
    npx browserslist@latest --update-db

    Why you should do it regularly:
    https://github.com/browserslist/browserslist#browsers-data-updating

          
      at runTest (packages/jest-circus/src/__mocks__/testUtils.ts:82:11)

  ● child tests marked with only should not run if describe block is skipped


          Unexpected stderr:
          Browserslist: caniuse-lite is outdated. Please run:
    npx browserslist@latest --update-db

    Why you should do it regularly:
    https://github.com/browserslist/browserslist#browsers-data-updating

          
      at runTest (packages/jest-circus/src/__mocks__/testUtils.ts:82:11)

Test Suites: 3 failed, 3 passed, 6 total
Tests:       11 failed, 43 passed, 54 total
Snapshots:   0 total
Time:        13.699 s
Ran all test suites matching /.\/packages\/jest-circus\//i.
```