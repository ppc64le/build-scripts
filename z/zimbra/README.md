# Zimbra
To generate ZCS package, exuecute zimbra_rhel7.sh script.
`
$./zimbra_rhel7.sh
`
##### Note:
- Please keep patch files in parallel with the zimbra script file.
- Currently, Replacing `ppc64` config as `ppc64le` in the config.guess file to add the ppc64le support for thridparty packages. Instead, need to add `ppc64le` as a new architecture.