   Test cases failure details for version v6.0.0
  -----
 ` ` `(node:38682) UnhandledPromiseRejectionWarning: Error: write EPIPE
    at afterWriteDispatched (internal/stream_base_commons.js:156:25)
    at writeGeneric (internal/stream_base_commons.js:147:3)
    at Socket._writeGeneric (net.js:787:11)
    at Socket._write (net.js:799:8)
    at doWrite (_stream_writable.js:403:12)
    at clearBuffer (_stream_writable.js:542:7)
    at Socket.Writable.uncork (_stream_writable.js:338:7)
    at uncork (/root/execa/node_modules/ava/lib/reporters/default.js:108:10)
    at Reporter.consumeStateChange (/root/execa/node_modules/ava/lib/reporters/default.js:134:6)
    at /root/execa/node_modules/ava/lib/reporters/default.js:230:9
(node:38682) UnhandledPromiseRejectionWarning: Unhandled promise rejection. This error originated either by throwing inside of an async function without a catch block, or by rejecting a promise which was not handled with .catch(). To terminate the node process on unhandled promise rejection, use the CLI flag `--unhandled-rejections=strict` (see https://nodejs.org/api/cli.html#cli_unhandled_rejections_mode). (rejection id: 3)
(node:38682) [DEP0018] DeprecationWarning: Unhandled promise rejections are deprecated. In the future, promise rejections that are not handled will terminate the Node.js process with a non-zero exit code.
Error: write EPIPE
    at afterWriteDispatched (internal/stream_base_commons.js:156:25)
    at writeGeneric (internal/stream_base_commons.js:147:3)
    at Socket._writeGeneric (net.js:787:11)
    at Socket._write (net.js:799:8)
    at doWrite (_stream_writable.js:403:12)
    at writeOrBuffer (_stream_writable.js:387:5)
    at Socket.Writable.write (_stream_writable.js:318:11)
    at ConsoleWriter.write (/root/execa/node_modules/istanbul-lib-report/lib/file-writer.js:80:28)
    at ConsoleWriter.println (/root/execa/node_modules/istanbul-lib-report/lib/file-writer.js:35:14)
    at TextReport.onStart (/root/execa/node_modules/istanbul-reports/lib/text/index.js:266:17)```
