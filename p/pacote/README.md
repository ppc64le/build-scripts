   Test cases failure details for version v9.5.12
  -----
 ` ` `get manifest from package.json in git clone
  not ok Command failed: /usr/bin/git commit -m initial commit --no-gpg-sign  *** Please tell me who you are.  Run    git config --global user.email "you@example.com"   git config --global user.name "Your Name"  to set your account's default identity. Omit --global to set the identity only in this repository.  fatal: unable to auto-detect email address (got 'root@8aee2c3e8f10.(none)')
    cause:
      name: Error
      stack: |-
        Error: Command failed: /usr/bin/git commit -m initial commit --no-gpg-sign

        *** Please tell me who you are.

        Run

          git config --global user.email "you@example.com"
          git config --global user.name "Your Name"

        to set your account's default identity.
        Omit --global to set the identity only in this repository.

        fatal: unable to auto-detect email address (got 'root@8aee2c3e8f10.(none)')

            at ChildProcess.exithandler (child_process.js:308:12)
            at ChildProcess.emit (events.js:314:20)
            at ChildProcess.EventEmitter.emit (domain.js:506:15)
            at maybeClose (internal/child_process.js:1022:16)
            at Socket.<anonymous> (internal/child_process.js:444:11)
            at Socket.emit (events.js:314:20)
            at Socket.EventEmitter.emit (domain.js:506:15)
            at Pipe.<anonymous> (net.js:675:12)
            at Pipe.callbackTrampoline (internal/async_hooks.js:126:14)
      message: |
        Command failed: /usr/bin/git commit -m initial commit --no-gpg-sign

        *** Please tell me who you are.

        Run

          git config --global user.email "you@example.com"
          git config --global user.name "Your Name"

        to set your account's default identity.
        Omit --global to set the identity only in this repository.

        fatal: unable to auto-detect email address (got 'root@8aee2c3e8f10.(none)')
      killed: false
      code: 128
      signal: null
      cmd: /usr/bin/git commit -m initial commit --no-gpg-sign
    isOperational: true
    killed: false
    code: 128
    signal: null
    cmd: /usr/bin/git commit -m initial commit --no-gpg-sign
    tapCaught: returnedPromiseRejection
    test: get manifest from package.json in git clone

test/git.mkopts.uid.js ................................ 2/2 2s
test/git.tarball.js ................................... 0/1 2s
  ~ idk

test/manifest.js ...................................... 0/4 2s
  ~ parses string specs into specifiers
  ~ accepts realized package specifiers
  ~ dispatches a different handler based on spec type
  ~ returns a finalized manifest object

test/pack-dir.js ...................................... 1/1 3s
(node:880) [DEP0066] DeprecationWarning: OutgoingMessage.prototype._headers is deprecated
test/prefetch.js .................................... 11/11 7s
test/read-json.js ..................................... 1/1 4s
test/registry.extract.js .............................. 0/1 2s
  ~ basic registry package extraction

(node:912) [DEP0066] DeprecationWarning: OutgoingMessage.prototype._headers is deprecated
(node:901) [DEP0066] DeprecationWarning: OutgoingMessage.prototype._headers is deprecated
test/registry.manifest.cache.js ....................... 6/6 6s
test/registry.manifest.js ........................... 29/29
(node:923) [DEP0066] DeprecationWarning: OutgoingMessage.prototype._headers is deprecated
test/registry.manifest.shrinkwrap.js .................. 3/7 6s
  ~ caches package data on shrinkwrap-related fetch
  ~ fails if shrinkwrap fetch failed + no caching
  ~ fails if shrinkwrap data fails to parse
  ~ fetches shrinkwrap data from existing local content

(node:934) [DEP0066] DeprecationWarning: OutgoingMessage.prototype._headers is deprecated
test/registry.packument.js .......................... 13/13 5s
(node:945) [DEP0066] DeprecationWarning: OutgoingMessage.prototype._headers is deprecated
test/registry.tarball.js ............................ 12/12 5s
(node:952) [DEP0066] DeprecationWarning: OutgoingMessage.prototype._headers is deprecated
test/remote.tarball.js ................................ 1/1 8s
test/strict.js ...................................... 62/62
(node:981) [DEP0097] DeprecationWarning: Using a domain property in MakeCallback is deprecated. Use the async_context variant of MakeCallback or the AsyncResource class instead.
(node:970) [DEP0097] DeprecationWarning: Using a domain property in MakeCallback is deprecated. Use the async_context variant of MakeCallback or the AsyncResource class instead.
(node:970) [DEP0066] DeprecationWarning: OutgoingMessage.prototype._headers is deprecated
test/tarball.js ..................................... 29/29
test/util.git.js ...................................... 0/2 3s
  executes git binary
  not ok Cannot read property 'cwd' of undefined
    stack: |
      cwdOwner (lib/util/git.js:7:336)
      Object.execGit [as _exec] (lib/util/git.js:7:839)
      Test.<anonymous> (test/util.git.js:14:14)
    at:
      line: 7
      column: 336
      file: lib/util/git.js
      function: cwdOwner
    type: TypeError
    tapCaught: testFunctionThrow
    test: executes git binary
    source: |
      multiArgs: true

  acknowledges git option
  not ok Cannot read property 'cwd' of null
    stack: |
      cwdOwner (lib/util/git.js:7:336)
      Object.execGit [as _exec] (lib/util/git.js:7:839)
      Test.<anonymous> (test/util.git.js:22:14)
    at:
      line: 7
      column: 336
      file: lib/util/git.js
      function: cwdOwner
    type: TypeError
    tapCaught: testFunctionThrow
    test: acknowledges git option
    source: |
      multiArgs: true

total ............................................. 234/255


  234 passing (38s)
  18 pending
  3 failing

------------------------------|----------|----------|----------|----------|-------------------|
File                          |  % Stmts | % Branch |  % Funcs |  % Lines | Uncovered Line #s |
------------------------------|----------|----------|----------|----------|-------------------|
All files                     |    77.97 |    68.09 |    72.13 |    79.18 |                   |
 pacote                       |    91.12 |    74.58 |    90.48 |    92.02 |                   |
  extract.js                  |    95.65 |       75 |      100 |    95.65 |             81,94 |
  index.js                    |      100 |      100 |      100 |      100 |                   |
  manifest.js                 |      100 |      100 |      100 |      100 |                   |
  packument.js                |      100 |    83.33 |      100 |      100 |                26 |
  prefetch.js                 |    80.56 |    66.67 |     87.5 |    81.82 | 21,22,23,24,25,32 |
  tarball.js                  |    88.24 |       50 |    78.57 |    89.58 |    31,33,43,44,48 |
 pacote/lib                   |    87.75 |    87.73 |    87.72 |    88.31 |                   |
  extract-stream.js           |    91.89 |    76.92 |      100 |    91.89 |          65,66,68 |
  fetch.js                    |    92.31 |    83.33 |      100 |    92.31 |          63,64,78 |
  finalize-manifest.js        |    96.43 |    97.24 |       95 |    96.36 |    78,211,214,238 |
  with-tarball-stream.js      |    67.69 |    59.46 |    68.42 |    69.35 |... 89,112,117,127 |
 pacote/lib/fetchers          |    62.11 |    33.33 |    48.33 |    64.29 |                   |
  alias.js                    |       75 |      100 |       50 |       75 |             10,22 |
  directory.js                |    87.23 |    81.82 |    68.75 |    86.96 | 20,21,40,41,77,85 |
  file.js                     |    62.16 |     37.5 |    41.67 |    67.65 |... 66,67,68,71,76 |
  git.js                      |    44.05 |       16 |     37.5 |    46.25 |... 72,173,174,176 |
  hosted.js                   |        0 |      100 |      100 |        0 |                 3 |
  range.js                    |      100 |      100 |      100 |      100 |                   |
  remote.js                   |       80 |      100 |       50 |       80 |             12,20 |
  tag.js                      |      100 |      100 |      100 |      100 |                   |
  version.js                  |      100 |      100 |      100 |      100 |                   |
 pacote/lib/fetchers/registry |     84.4 |    66.67 |     87.1 |     85.4 |                   |
  index.js                    |      100 |      100 |      100 |      100 |                   |
  manifest.js                 |    80.56 |    59.09 |    83.33 |       80 |... 35,39,43,49,61 |
  packument.js                |    80.95 |    65.22 |       80 |    80.95 |... 85,86,87,88,90 |
  tarball.js                  |       86 |    77.78 |       90 |    89.36 |    93,95,96,97,99 |
 pacote/lib/util              |    65.37 |    48.35 |    59.26 |    66.15 |                   |
  cache-key.js                |      100 |      100 |      100 |      100 |                   |
  finished.js                 |      100 |      100 |      100 |      100 |                   |
  git.js                      |    57.69 |    43.42 |    51.28 |     58.5 |... 73,274,275,285 |
  opt-check.js                |    83.33 |        0 |        0 |    83.33 |                46 |
  pack-dir.js                 |    78.95 |       50 |    66.67 |    82.35 |          23,26,28 |
  proclog.js                  |      100 |      100 |      100 |      100 |                   |
  read-json.js                |      100 |      100 |      100 |      100 |                   |
------------------------------|----------|----------|----------|----------|-------------------|
npm ERR! Test failed.  See above for more details.` ` `
------------------pacote:install_success_but_test_fails---------------------
