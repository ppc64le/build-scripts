#!/bin/bash
set -x
# Path to deploy the Tomcat Bundle
BONITA_PATH=${BONITA_PATH:-/opt/bonita}
# Templates directory
BONITA_TPL=${BONITA_TPL:-/opt/templates}
# Files directory
BONITA_FILES=${BONITA_FILES:-/opt/files}
# Flag to allow or not the SQL queries to automatically check and create the databases
ENSURE_DB_CHECK_AND_CREATION=${ENSURE_DB_CHECK_AND_CREATION:-true}
# Java OPTS
JAVA_OPTS=${JAVA_OPTS:--Xms1024m -Xmx1024m -XX:MaxPermSize=256m}
# Flag to enable or not dynamic authorization checking on Bonita REST API
REST_API_DYN_AUTH_CHECKS=${REST_API_DYN_AUTH_CHECKS:-true}
# Flag to enable or not Bonita HTTP API
HTTP_API=${HTTP_API:-false}

# retrieve the db parameters from the container linked
if [ -n "$POSTGRES_PORT_5432_TCP_PORT" ]
then
	DB_VENDOR='postgres'
	DB_HOST=$POSTGRES_PORT_5432_TCP_ADDR
	DB_PORT=$POSTGRES_PORT_5432_TCP_PORT
elif [ -n "$MYSQL_PORT_3306_TCP_PORT" ]
then
	DB_VENDOR='mysql'
	DB_HOST=$MYSQL_PORT_3306_TCP_ADDR
	DB_PORT=$MYSQL_PORT_3306_TCP_PORT
else
	DB_VENDOR=${DB_VENDOR:-h2}
fi

case $DB_VENDOR in
	"h2")
		DB_HOST=${DB_HOST:-localhost}
		DB_PORT=${DB_PORT:-9091}
		;;
	"postgres")
		DB_PORT=${DB_PORT:-5432}
		;;
	"mysql")
		DB_PORT=${DB_PORT:-3306}
		;;
	*)
		;;
esac
# BIZ_DB_VENDOR is currently set to the same value than DB_VENDOR
BIZ_DB_VENDOR=$DB_VENDOR

# if not enforced, set the default values to configure the databases
DB_NAME=${DB_NAME:-bonitadb}
DB_USER=${DB_USER:-bonitauser}
DB_PASS=${DB_PASS:-bonitapass}
BIZ_DB_NAME=${BIZ_DB_NAME:-businessdb}
BIZ_DB_USER=${BIZ_DB_USER:-businessuser}
BIZ_DB_PASS=${BIZ_DB_PASS:-businesspass}

# if not enforced, set the default credentials
PLATFORM_LOGIN=${PLATFORM_LOGIN:-platformAdmin}
PLATFORM_PASSWORD=${PLATFORM_PASSWORD:-platform}
TENANT_LOGIN=${TENANT_LOGIN:-install}
TENANT_PASSWORD=${TENANT_PASSWORD:-install}

if [ ! -d ${BONITA_PATH}/BonitaBPMCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION} ]
then
        unzip -q ${BONITA_FILES}/BonitaBPMCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}.zip -d ${BONITA_PATH}
fi

if [ "${ENSURE_DB_CHECK_AND_CREATION}" = 'true' ]
then
	# load SQL functions
	. ${BONITA_FILES}/functions.sh
	case "${DB_VENDOR}" in
		mysql)
			DB_ADMIN_USER=${DB_ADMIN_USER:-root}
			if [ -z "$DB_ADMIN_PASS" ]
			then
				DB_ADMIN_PASS=$MYSQL_ENV_MYSQL_ROOT_PASSWORD
			fi
			;;
		postgres)
			DB_ADMIN_USER=${DB_ADMIN_USER:-postgres}
			if [ -z "$DB_ADMIN_PASS" ]
			then
				DB_ADMIN_PASS=$POSTGRES_ENV_POSTGRES_PASSWORD
			fi
			;;
	esac
	if [ "${DB_VENDOR}" != 'h2' ]
	then
		# ensure to create bonita db and user
		create_user_if_not_exists $DB_VENDOR $DB_HOST $DB_PORT $DB_ADMIN_USER $DB_ADMIN_PASS $DB_USER $DB_PASS
		create_database_if_not_exists $DB_VENDOR $DB_HOST $DB_PORT $DB_ADMIN_USER $DB_ADMIN_PASS $DB_NAME $DB_USER
		# ensure to create business db and user if needed
		create_user_if_not_exists $DB_VENDOR $DB_HOST $DB_PORT $DB_ADMIN_USER $DB_ADMIN_PASS $BIZ_DB_USER $BIZ_DB_PASS
		create_database_if_not_exists $DB_VENDOR $DB_HOST $DB_PORT $DB_ADMIN_USER $DB_ADMIN_PASS $BIZ_DB_NAME $BIZ_DB_USER
	fi
fi

# apply conf
# copy templates
cp ${BONITA_TPL}/setenv.sh ${BONITA_PATH}/BonitaBPMCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}/setup/tomcat-templates/setenv.sh
cp ${BONITA_TPL}/database.properties ${BONITA_PATH}/BonitaBPMCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}/setup/database.properties

# if required, uncomment dynamic checks on REST API
if [ "$REST_API_DYN_AUTH_CHECKS" = 'true' ]
then
    sed -i -e 's/^#GET|/GET|/' -e 's/^#POST|/POST|/' -e 's/^#PUT|/PUT|/' -e 's/^#DELETE|/DELETE|/' ${BONITA_PATH}/BonitaBPMCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}/setup/platform_conf/initial/tenant_template_portal/dynamic-permissions-checks.properties
fi
# if required, deactivate HTTP API by updating bonita.war with proper web.xml
if [ "$HTTP_API" = 'false' ]
then
    cd ${BONITA_FILES}/
    zip ${BONITA_PATH}/BonitaBPMCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}/server/webapps/bonita.war WEB-INF/web.xml
fi

# replace variables
find ${BONITA_PATH}/BonitaBPMCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}/setup/platform_conf/initial -name "*.properties" | xargs -n10 sed -i \
    -e 's/^#userName\s*=.*/'"userName=${TENANT_LOGIN}"'/' \
    -e 's/^#userPassword\s*=.*/'"userPassword=${TENANT_PASSWORD}"'/' \
    -e 's/^platform.tenant.default.username\s*=.*/'"platform.tenant.default.username=${TENANT_LOGIN}"'/' \
    -e 's/^platform.tenant.default.password\s*=.*/'"platform.tenant.default.password=${TENANT_PASSWORD}"'/' \
    -e 's/^#platformAdminUsername\s*=.*/'"platformAdminUsername=${PLATFORM_LOGIN}"'/' \
    -e 's/^#platformAdminPassword\s*=.*/'"platformAdminPassword=${PLATFORM_PASSWORD}"'/'

sed -i -e 's/{{JAVA_OPTS}}/'"${JAVA_OPTS}"'/' ${BONITA_PATH}/BonitaBPMCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}/setup/tomcat-templates/setenv.sh

if [ -n "$JDBC_DRIVER" ]
then
    # if $JDBC_DRIVER is set and the driver is not present, copy the JDBC driver into the Bundle
    file=$(basename $JDBC_DRIVER)
    if [ ! -e ${BONITA_PATH}/BonitaBPMCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}/setup/lib/$file ]
    then
        cp ${BONITA_FILES}/${JDBC_DRIVER} ${BONITA_PATH}/BonitaBPMCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}/setup/lib/
    fi
fi

sed -e 's/{{DB_VENDOR}}/'"${DB_VENDOR}"'/' \
    -e 's/{{DB_USER}}/'"${DB_USER}"'/' \
    -e 's/{{DB_PASS}}/'"${DB_PASS}"'/' \
    -e 's/{{DB_NAME}}/'"${DB_NAME}"'/' \
    -e 's/{{DB_HOST}}/'"${DB_HOST}"'/' \
    -e 's/{{DB_PORT}}/'"${DB_PORT}"'/' \
    -e 's/{{BIZ_DB_USER}}/'"${BIZ_DB_USER}"'/' \
    -e 's/{{BIZ_DB_PASS}}/'"${BIZ_DB_PASS}"'/' \
    -e 's/{{BIZ_DB_NAME}}/'"${BIZ_DB_NAME}"'/' \
    -i ${BONITA_PATH}/BonitaBPMCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}/setup/database.properties

# use the setup tool to initialize and configure Bonita BPM Tomcat bundle
cd /opt/bonita/BonitaBPMCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}
./setup/setup.sh init
./setup/setup.sh configure
