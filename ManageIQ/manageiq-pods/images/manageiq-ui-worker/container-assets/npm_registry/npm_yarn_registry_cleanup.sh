#!/bin/bash
npm config delete registry
npm config delete strict-ssl
yarn config delete registry
yarn config delete strict-ssl

# Replace registry in yarn.lock
default_yarn_registry=`yarn config get registry`
ui_plugin_repos=`rake update:print_engines | grep path: | cut -d: -f2`
for repo in ${ui_plugin_repos} ${SUI_ROOT}
do
  sed -i "s#${NPM_REGISTRY_OVERRIDE}#${default_yarn_registry}#g" ${repo}/yarn.lock
done
