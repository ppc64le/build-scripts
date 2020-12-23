# Prerequisites before raising PR

1. Naming convention for file: **\<package-name\>.travis.yml**

2. Add below header to the file

```yaml
# ----------------------------------------------------------------------------
#
# Package             : <package name>
# Source Repo         : <orginal repo link>
# Travis Job Link     : <travis job link>
# Created travis.yml  : <Yes, if travis.yml is created. No, if existing travis.yml is modified.>
# Maintainer          : <your name and email id>
#
# Script License      : Apache License, Version 2 or later
#
# ----------------------------------------------------------------------------
```

3. Add `travis.yml` content after the header

# Your file should look somewhat like this before raising PR

sample-travis-job.travis.yml

```yaml
# ----------------------------------------------------------------------------
#
# Package             : sample-travis-job 
# Source Repo         : https://github.com/Siddhesh-Ghadi/sample-travis-job.git
# Travis Job Link     : https://travis-ci.com/github/Siddhesh-Ghadi/sample-travis-job/builds/210384845
# Created travis.yml  : Yes
# Maintainer          : Siddhesh Ghadi <Siddhesh.Ghadi@ibm.com>
#
# Script License      : Apache License, Version 2 or later
#
# ----------------------------------------------------------------------------

arch:
  - amd64
  - ppc64le
  
dist: bionic

script:
  - echo "SAMPLE TRAVIS JOB"
```
