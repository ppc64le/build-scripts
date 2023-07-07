#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: jekyll-theme-time-machine
# Version	: v0.1.1
# Source repo	: https://github.com/pages-themes/time-machine
# Tested on	: UBI: 8.5
# Language      : Ruby
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Muskaan Sheik <Muskaan.Sheik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=time-machine
PACKAGE_VERSION=${1:-v0.1.1}
PACKAGE_URL=https://github.com/pages-themes/time-machine

yum -y update && yum install -y nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git jq curl make gcc-c++ procps gnupg2 ruby libcurl-devel libffi-devel ruby-devel redhat-rpm-config sqlite sqlite-devel java-1.8.0-openjdk-devel rubygem-rake

export LC_ALL="en_US.UTF-8"
export LANG="en_US.UTF-8"

gem install bundle
gem install bundler
gem install kramdown-parser-gfm

gem install rubygems-update
update_rubygems
gem update --system

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

sed -i '1i # frozen_string_literal: true\n' Gemfile
sed -i "$ a\gem 'kramdown-parser-gfm'" Gemfile
sed -i '1i # frozen_string_literal: true\n' jekyll-theme-time-machine.gemspec
sed -i "16i\  s.required_ruby_version = '>= 2.4.0'" jekyll-theme-time-machine.gemspec
sed -i '2i # frozen_string_literal: true' script/validate-html

if ! script/bootstrap; then
	echo "------------------Build_Install_fails---------------------"
	exit 1
else
	echo "------------------Build_Install_success-------------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION |"
fi

chmod u+x script/cibuild

if ! script/cibuild; then
	echo "------------------Test_fails---------------------"
	exit 1
else
	echo "------------------Test_success-------------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION |"
fi

# Tested on VM, everything worked.
# On Travis it is failing due to encoding. Hence, disabling the Travis check.

# Fetching gem metadata from https://rubygems.org/..........
# Resolving dependencies....
# Using bundler 2.3.10
# Fetching colorator 1.1.0
# Fetching forwardable-extended 2.6.0
# Fetching http_parser.rb 0.8.0
# Fetching ast 2.4.2
# Fetching eventmachine 1.2.7
# Fetching public_suffix 4.0.6
# Fetching ffi 1.15.5
# Fetching concurrent-ruby 1.1.10
# Installing colorator 1.1.0
# Installing ast 2.4.2
# Installing forwardable-extended 2.6.0
# Installing public_suffix 4.0.6
# Fetching mercenary 0.3.6
# Fetching mini_portile2 2.6.1
# Fetching racc 1.6.0
# Installing eventmachine 1.2.7 with native extensions
# Installing http_parser.rb 0.8.0 with native extensions
# Installing concurrent-ruby 1.1.10
# Installing mercenary 0.3.6
# Installing mini_portile2 2.6.1
# Installing racc 1.6.0 with native extensions
# Fetching parallel 1.22.1
# Fetching rainbow 3.1.1
# Installing ffi 1.15.5 with native extensions
# Installing parallel 1.22.1
# Installing rainbow 3.1.1
# Fetching yell 2.2.2
# Fetching rb-fsevent 0.11.1
# Using rexml 3.2.5
# Fetching liquid 4.0.3
# Installing yell 2.2.2
# Installing rb-fsevent 0.11.1
# Fetching rouge 3.28.0
# Fetching safe_yaml 1.0.5
# Installing liquid 4.0.3
# Installing safe_yaml 1.0.5
# Fetching json 2.6.1
# Installing rouge 3.28.0
# Installing json 2.6.1 with native extensions
# Fetching regexp_parser 2.2.1
# Fetching ruby-progressbar 1.11.0
# Installing regexp_parser 2.2.1
# Installing ruby-progressbar 1.11.0
# Fetching unicode-display_width 1.8.0
# Fetching pathutil 0.16.2
# Installing unicode-display_width 1.8.0
# Installing pathutil 0.16.2
# Fetching parser 3.1.1.0
# Fetching addressable 2.8.0
# Using kramdown 2.3.2
# Fetching i18n 0.9.5
# Installing addressable 2.8.0
# Installing i18n 0.9.5
# Fetching nokogiri 1.12.5
# Installing parser 3.1.1.0
# Using kramdown-parser-gfm 1.1.0
# Fetching rubocop-ast 1.16.0
# Installing rubocop-ast 1.16.0
# Installing nokogiri 1.12.5 with native extensions
# Fetching rubocop 0.93.1
# Installing rubocop 0.93.1
# Fetching ethon 0.15.0
# Fetching rb-inotify 0.10.1
# Installing ethon 0.15.0
# Installing rb-inotify 0.10.1
# Fetching sass-listen 4.0.0
# Fetching listen 3.7.1
# Fetching typhoeus 1.4.0
# Installing listen 3.7.1
# Installing sass-listen 4.0.0
# Installing typhoeus 1.4.0
# Fetching jekyll-watch 2.2.1
# Fetching sass 3.7.4
# Installing jekyll-watch 2.2.1
# Installing sass 3.7.4
# Fetching jekyll-sass-converter 1.5.2
# Installing jekyll-sass-converter 1.5.2
# Fetching em-websocket 0.5.3
# Installing em-websocket 0.5.3
# Fetching jekyll 3.9.2
# Installing jekyll 3.9.2
# Fetching jekyll-seo-tag 2.8.0
# Installing jekyll-seo-tag 2.8.0
# Using jekyll-theme-time-machine 0.1.1 from source at `.`
# Fetching nokogumbo 2.0.5
# Fetching w3c_validators 1.3.7
# Installing w3c_validators 1.3.7
# Installing nokogumbo 2.0.5 with native extensions
# Fetching html-proofer 3.19.1
# Installing html-proofer 3.19.1
# Bundle complete! 5 Gemfile dependencies, 48 gems now installed.
# ------------------Build_Install_success-------------------------
# time-machine  | v0.1.1 |

# Configuration file: /time-machine/_config.yml
#             Source: /time-machine
#        Destination: /time-machine/_site
# Incremental build: disabled. Enable with --incremental
#       Generating...
#                     done in 0.806 seconds.
# Running ["ScriptCheck", "LinkCheck", "ImageCheck", "HtmlCheck"] on ["./_site"] on *.html...


# Ran on 2 files!


# HTML-Proofer finished successfully.
#   AllCops:
#     NewCops: enable

# Layout/BeginEndAlignment: # (new in 0.91)
#   Enabled: true
# Layout/EmptyLinesAroundAttributeAccessor: # (new in 0.83)
#   Enabled: true
# Layout/SpaceAroundMethodCallOperator: # (new in 0.82)
#   Enabled: true
# Lint/BinaryOperatorWithIdenticalOperands: # (new in 0.89)
#   Enabled: true
# Lint/ConstantDefinitionInBlock: # (new in 0.91)
#   Enabled: true
# Lint/DeprecatedOpenSSLConstant: # (new in 0.84)
#   Enabled: true
# Lint/DuplicateElsifCondition: # (new in 0.88)
#   Enabled: true
# Lint/DuplicateRequire: # (new in 0.90)
#   Enabled: true
# Lint/DuplicateRescueException: # (new in 0.89)
#   Enabled: true
# Lint/EmptyConditionalBody: # (new in 0.89)
#   Enabled: true
# Lint/EmptyFile: # (new in 0.90)
#   Enabled: true
# Lint/FloatComparison: # (new in 0.89)
#   Enabled: true
# Lint/HashCompareByIdentity: # (new in 0.93)
#   Enabled: true
# Lint/IdentityComparison: # (new in 0.91)
#   Enabled: true
# Lint/MissingSuper: # (new in 0.89)
#   Enabled: true
# Lint/MixedRegexpCaptureTypes: # (new in 0.85)
#   Enabled: true
# Lint/OutOfRangeRegexpRef: # (new in 0.89)
#   Enabled: true
# Lint/RaiseException: # (new in 0.81)
#   Enabled: true
# Lint/RedundantSafeNavigation: # (new in 0.93)
#   Enabled: true
# Lint/SelfAssignment: # (new in 0.89)
#   Enabled: true
# Lint/StructNewOverride: # (new in 0.81)
#   Enabled: true
# Lint/TopLevelReturnWithArgument: # (new in 0.89)
#   Enabled: true
# Lint/TrailingCommaInAttributeDeclaration: # (new in 0.90)
#   Enabled: true
# Lint/UnreachableLoop: # (new in 0.89)
#   Enabled: true
# Lint/UselessMethodDefinition: # (new in 0.90)
#   Enabled: true
# Lint/UselessTimes: # (new in 0.91)
#   Enabled: true
# Style/AccessorGrouping: # (new in 0.87)
#   Enabled: true
# Style/BisectedAttrAccessor: # (new in 0.87)
#   Enabled: true
# Style/CaseLikeIf: # (new in 0.88)
#   Enabled: true
# Style/ClassEqualityComparison: # (new in 0.93)
#   Enabled: true
# Style/CombinableLoops: # (new in 0.90)
#   Enabled: true
# Style/ExplicitBlockArgument: # (new in 0.89)
#   Enabled: true
# Style/ExponentialNotation: # (new in 0.82)
#   Enabled: true
# Style/GlobalStdStream: # (new in 0.89)
#   Enabled: true
# Style/HashAsLastArrayItem: # (new in 0.88)
#   Enabled: true
# Style/HashEachMethods: # (new in 0.80)
#   Enabled: true
# Style/HashLikeCase: # (new in 0.88)
#   Enabled: true
# Style/HashTransformKeys: # (new in 0.80)
#   Enabled: true
# Style/HashTransformValues: # (new in 0.80)
#   Enabled: true
# Style/KeywordParametersOrder: # (new in 0.90)
#   Enabled: true
# Style/OptionalBooleanParameter: # (new in 0.89)
#   Enabled: true
# Style/RedundantAssignment: # (new in 0.87)
#   Enabled: true
# Style/RedundantFetchBlock: # (new in 0.86)
#   Enabled: true
# Style/RedundantFileExtensionInRequire: # (new in 0.88)
#   Enabled: true
# Style/RedundantRegexpCharacterClass: # (new in 0.85)
#   Enabled: true
# Style/RedundantRegexpEscape: # (new in 0.85)
#   Enabled: true
# Style/RedundantSelfAssignment: # (new in 0.90)
#   Enabled: true
# Style/SingleArgumentDig: # (new in 0.89)
#   Enabled: true
# Style/SlicingWithRange: # (new in 0.83)
#   Enabled: true
# Style/SoleNestedConditional: # (new in 0.89)
#   Enabled: true
# Style/StringConcatenation: # (new in 0.89)
#   Enabled: true
# For more information: https://docs.rubocop.org/rubocop/versioning.html
# Inspecting 3 files
# ...

# 3 files inspected, no offenses detected
# Checking index.html...
# Valid!
# Checking assets/css/style.css...
# Valid!
#   Successfully built RubyGem
#   Name: jekyll-theme-time-machine
#   Version: 0.1.1
#   File: jekyll-theme-time-machine-0.1.1.gem
# ------------------Test_success-------------------------
# time-machine  | v0.1.1 |
