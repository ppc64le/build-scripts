# Security Policy

## Supported Versions

We currently provide build scripts for many (thousands) of open source projects and within those projects many different versions.

Any failures within the packages that we create build scripts for should be assessed and filed with the corresponding open source project - 
we do not have the bandwidth to carry additional issues back to those communities or maintain the context behind those failures.

We also are working on a portal which will help identify per-version SBOM, Licenses and CVEs which may be available some time this year.

If you see a security issue introduced by the way we build a product, please directly file an issue with that vulunerability (if it is publicly
disclosed) against the specific build script directory that contains the issue.  If the issue is sensitive, you can email to:

ich at us dot ibm dot com

## | Version | Supported          |
## | ------- | ------------------ |
## | 5.1.x   | :white_check_mark: |
## | 5.0.x   | :x:                |
## | 4.0.x   | :white_check_mark: |
## | < 4.0   | :x:                |

## Reporting a Vulnerability

If the vulnerability is reported via a github issue, we will try to get it assigned and looked at as quickly as possible.  Given
our agile process model, we look at issues like this typically at the beginning of any two week sprint so you should have some sort of
response within 4 weeks.  Anything needed more urgently should be reported via the email link address identified above.
