#!/bin/bash

# ---------------------------------------------------------------------
#
# Package       : 3scale/porta
# Version       : main
# Source repo   : https://github.com/3scale/porta.git
# Tested on     : UBI:9.3
# Language      : Ruby
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shubham Bhagwat <Shubham.Bhagwat@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------


PACKAGE_NAME=porta
PACKAGE_VERSION=master
PACKAGE_BRANCH=master
PACKAGE_URL=https://github.com/3scale/porta.git

# clone branch/release passed as argument, if none, use last stable release

#install git and wget
yum install -y git wget


#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"
fi

if ! git clone $PACKAGE_URL -b $PACKAGE_BRANCH ; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Clone Failure"
    exit 1
fi

echo "BRANCH_NAME = $PACKAGE_BRANCH"

cd $PACKAGE_NAME


#Install required prerequisites
yum install -y gcc gcc-c++ make automake autoconf curl-devel openssl-devel zlib-devel httpd-devel apr-devel apr-util-devel sqlite-devel bzip2 perl


#To enable yum-config-manager
yum install -y yum-utils

#Adding repo to install flex, bison and readline
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream//ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os
curl -o /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

yum install -y flex flex-devel bison readline-devel

#Install Ruby Using Rbenv
#Download and run the shell script used to install Rbenv:
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash

#need to add $HOME/.rbenv/bin to our PATH environment variable to start using Rbenv for bash shell.
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc
export PATH="$HOME/.rbenv/bin:$PATH"

#ruby install using rbenv
rbenv install 2.7.6

#Set the newly installed version of Ruby as the global version:
rbenv global 2.7.6

export PATH="$HOME/.rbenv/shims:$PATH"


# Install nokogiri
yum install -y libxml2
yum install -y zlib-devel xz patch
gem install nokogiri -v 1.15.6

# Install nodeJs
wget https://nodejs.org/dist/v16.14.0/node-v16.14.0-linux-ppc64le.tar.gz && \
    tar -xzf node-v16.14.0-linux-ppc64le.tar.gz
mv /node-v16.14.0-linux-ppc64le /opt/nodejs
export PATH="/opt/nodejs/bin:${PATH}"

# Install dependencies
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum install -y sphinx postgresql-devel gd-devel mysql-devel openssl-devel zlib-devel sqlite-devel readline-devel libyaml-devel liberation-fonts libpq-devel shared-mime-info gd-devel libtool libffi-devel bison automake autoconf patch

# Setup Postgres db
docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=root -e POSTGRES_HOST_AUTH_METHOD=trust --name postgres80 ppc64le/postgres
# Setup environment variable so that postgres is preferred over mysql 
export DATABASE_URL="postgresql://postgres:@localhost:5432/systemdb"

# setup redis
docker run -d -p 6379:6379 redis

# setup memcached, which is used for caching the data
docker run -d -p 11211:11211 memcached

# Install bundler
gem install bundler -v 2.4.22
# Install gems
bundle install

# Install yarn
npm install --global yarn
# Install all required packages
yarn install

# Copy config files
cp config/examples/* config/

# Digital envolope error uncomment if occurs
# export NODE_OPTIONS=--openssl-legacy-provider

# Assets precompile
bundle exec rake assets:precompile:test

# Prepare database for tests
bundle exec rake db:setup

# Start Sphinx server
bundle exec rake ts:configure ts:start

# Rspec tests
if ! bundle exec rspec --format progress; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Rspec test Failure"
    exit 1
fi


# Run unit tests
if ! bundle exec rake test TEST='
        test/unit/cinstance_test.rb \
        test/unit/liquid/drops/account_drop_test.rb \
        test/unit/logic/plan_changes_test.rb \
        test/unit/messengers/cinstance_messenger_test.rb \
        test/unit/signup/account_manager_test.rb \
        test/unit/apicast/curl_command_builder_test.rb \
        test/unit/services/support_entitlements_service_test.rb \
        test/unit/authentication/strategy/oauth2_test.rb \
        test/unit/topic_test.rb \
        test/unit/cinstance/trial_test.rb \
        test/unit/liquid/drops/provider_drop_test.rb \
        test/unit/db/seeds_test.rb \
        test/unit/policy_test.rb \
        test/unit/presenters/api/applications_new_presenter_test.rb \
        test/unit/cms/file_test.rb \
        test/unit/events/importers/first_traffic_importer_test.rb \
        test/unit/user/states_test.rb \
        test/workers/report_traffic_worker_test.rb \
        test/unit/abilities/multiple_applications_test.rb \
        test/unit/services/apicast_v2_deployment_service_test.rb \
        test/unit/presenters/provider/admin/applications_new_presenter_test.rb \
        test/unit/queries/monthly_revenue_query_test.rb \
        test/unit/three_scale/email_configuration_interceptor_test.rb \
        test/unit/presenters/dashboard/top_traffic_presenter_test.rb \
        test/unit/backend/model_extensions/service_test.rb \
        test/unit/domain_constraints_test.rb \
        test/unit/finance/variable_cost_test.rb \
        test/unit/services/cms_reset_service_test.rb \
        test/unit/three_scale/semantic_form_builder_test.rb \
        test/workers/invoice_friendly_id_worker_test.rb \
        test/unit/stats/backend_api_test.rb \
        test/unit/cms/builtin_test.rb \
        test/unit/api/by_provider_key_test.rb \
        test/unit/backend/model_extensions/backend_api_config_test.rb \
        test/unit/liquid/drops/service_contract_drop_test.rb \
        test/workers/delete_payment_setting_hierarchy_worker_test.rb \
        test/unit/profile_test.rb \
        test/unit/post_test.rb \
        test/decorators/contract_decorator_test.rb \
        test/workers/message_worker_test.rb \
        test/unit/service_token_test.rb \
        test/unit/stats/aggregation/rule_test.rb \
        test/unit/csv/invoices_exporter_test.rb \
        test/unit/finance/line_item_test.rb \
        test/workers/activation_reminder_worker_test.rb \
        test/unit/sudo_test.rb \
        test/workers/service_discovery/create_service_worker_test.rb \
        test/events/applications/application_deleted_event_test.rb \
        test/unit/system_database_test.rb \
        test/workers/stale_account_worker_test.rb \
        test/decorators/message_decorator_test.rb \
        test/unit/payment_gateway_setting_test.rb \
        test/unit/fields/fields_test.rb \
        test/unit/three_scale/oauth2/client_test.rb \
        test/workers/audited_worker_test.rb \
        test/subscribers/application_deleted_subscriber_test.rb \
        test/unit/lib/cms/aws_credentials_test.rb \
        test/events/alerts/limit_alert_reached_provider_event_test.rb \
        test/unit/user_session_test.rb \
        test/events/report_related_event_test.rb \
        test/unit/three_scale/oauth2/auth0_client_test.rb \
        test/unit/liquid/drops/url_test.rb \
        test/unit/service_discovery/oauth_configuration_test.rb \
        test/unit/liquid/drops/plan_change_test.rb \
        test/unit/string_hacks_test.rb \
        test/unit/lib/authentication/by_cookie_token_test.rb \
        test/workers/sphinx_indexation_worker_test.rb \
        test/unit/three_scale/email_do_not_send_interceptor_test.rb \
        test/unit/plan_rule_loader_test.rb \
        test/unit/helpers/provider/signups_helper_test.rb \
        test/unit/cms/handler_test.rb \
        test/unit/liquid/drops/i18n_test.rb \
        test/unit/three_scale/swagger/autocomplete_test.rb \
        test/events/invoices/unsuccessfully_charged_invoice_final_provider_event_test.rb \
        test/unit/active_merchant/stripe_fix_test.rb \
        test/unit/helpers/metric_helpers_test.rb \
        test/unit/payment_buyer_references_test.rb \
        test/unit/three_scale/api/responder_test.rb \
        test/unit/date_parsing_test.rb \
        test/unit/services/audit_log_service_test.rb \
        test/unit/cms/handler/markdown_test.rb \
' TESTOPTS=--verbose --verbose --trace; then
    echo "------------------$PACKAGE_NAME:install_success_but_unit_test_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Unit test Failure"
    exit 2
fi

# Run integration tests
if ! bundle exec rake test TEST='
	  test/integration/user-management-api/base_controller_test.rb \
	  test/integration/api/services_controller_test.rb \
	  test/integration/api_support/forbid_params_test.rb \ 
	  test/integration/utilization_test.rb \
	  test/integration/provider/admin/backend_apis/metrics_controller_test.rb \
        test/integration/master/api/finance/accounts/billing_jobs_controller_test.rb \
	  test/integration/admin/api_docs/service_api_docs_controller_test.rb \ 
	  test/integration/admin/api/api_docs_services_controller_test.rb \
	  test/integration/provider/admin/account/payment_gateways/braintree_blue_controller_test.rb \
	  test/integration/audited_hacks_async_test.rb \
	  test/integration/api/proxy_rules_controller_test.rb \
	  test/integration/provider/invitee_signups_controller_integration_test.rb \
        test/integration/admin/api/backend_apis/metrics_controller_test.rb \
        test/integration/admin/api/objects_controller_test.rb \
        test/integration/provider/activations_controller_test.rb \
	  test/integration/signup_express_test.rb \
        test/integration/api/alerts_controller_test.rb \
	  test/integration/developer_portal/api_docs/account_data_controller_test.rb \
 	  test/integration/user-management-api/messages_test.rb \
 	  test/integration/dns_controller_test.rb \
	  test/integration/provider/admin/backend_apis/stats/usage_controller_test.rb \
	  test/integration/sso_enforce_flow_test.rb \ 	
	  test/integration/developer_portal/passwords_controller_test.rb \
	  test/integration/master/api/services_controller_integration_test.rb \
	  test/integration/provider/domains_controller_integration_test.rb \
 	  test/integration/provider/admin/dashboard/service/hits_controller_test.rb \
 	  test/integration/provider/passwords_integration_test.rb \
        test/integration/by_provider_key_integration_test.rb \
' TESTOPTS=--verbose --verbose --trace; then
    echo "------------------$PACKAGE_NAME:install_success_but_integration_test_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Integration test Failure"
    exit 2
fi

else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
# Skipping functional tests since it has dependency on chromedriver which is not supported for power
