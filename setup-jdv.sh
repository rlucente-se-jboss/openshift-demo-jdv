#!/bin/bash

# See https://raw.githubusercontent.com/tariq-islam/jdv-ose-demo/master/jdv-ocp-setup.sh

# Configuration

. ./config.sh || { echo "FAILED: Could not verify configuration" && exit 1; }
. ./config-jdv.sh || { echo "FAILED: Could not configure JDV" && exit 1; }

echo "	--> Make sure we are logged in (to the right instance and as the right user)"
. ./setup-login.sh -r OPENSHIFT_USER_RHSADEMO_MEPLEY || { echo "FAILED: Could not login" && exit 1; }

echo "	--> Creating the authentication objects"
echo "		--> Create a keystore for the data virt server"
[ -f ${JDV_SERVER_KEYSTORE_DEFAULT} ] || keytool -genkeypair -keystore ${JDV_SERVER_KEYSTORE_DEFAULT} -storepass ${JDV_SERVER_KEYSTORE_DEFAULT_PASSWORD} -keyalg RSA -alias ${JDV_SERVER_KEYSTORE_DEFAULT_ALIAS} -dname "CN=${OPENSHIFT_PRIMARY_USER}" -keypass ${JDV_SERVER_KEYSTORE_DEFAULT_PASSWORD} || { echo "FAILED: could not create the server keystore" && exit 1; }
echo "		--> Create a keystore for the data virt server's jgroups cluster"
# [ -f ${JDV_SERVER_KEYSTORE_JGROUPS} ] || keytool -genkeypair -keystore ${JDV_SERVER_KEYSTORE_JGROUPS} -storepass ${JDV_SERVER_KEYSTORE_JGROUPS_PASSWORD} -keyalg RSA -sigalg SHA256withRSA -alias ${JDV_SERVER_KEYSTORE_JGROUPS_ALIAS} -dname "CN=${OPENSHIFT_PRIMARY_USER}" -keypass ${JDV_SERVER_KEYSTORE_JGROUPS_PASSWORD} -storetype JCEKS || { echo "FAILED: could not create the jgroups keystore" && exit 1; }
[ -f ${JDV_SERVER_KEYSTORE_JGROUPS} ] || keytool -genseckey -keystore ${JDV_SERVER_KEYSTORE_JGROUPS} -storepass ${JDV_SERVER_KEYSTORE_JGROUPS_PASSWORD} -alias ${JDV_SERVER_KEYSTORE_JGROUPS_ALIAS} -dname "CN=${OPENSHIFT_PRIMARY_USER}" -keypass ${JDV_SERVER_KEYSTORE_JGROUPS_PASSWORD} -storetype JCEKS || { echo "FAILED: could not create the jgroups keystore" && exit 1; }


echo "	--> Verify the contents of the keystore"
[ "`keytool -list -keystore ${JDV_SERVER_KEYSTORE_DEFAULT} -storepass ${JDV_SERVER_KEYSTORE_DEFAULT_PASSWORD} | grep ${JDV_SERVER_KEYSTORE_DEFAULT_ALIAS} | wc -l`" == 0 ] && echo "FAILED" && exit 1
echo "	--> Verify the contents of the keystore"
[ "`keytool -list -keystore ${JDV_SERVER_KEYSTORE_JGROUPS} -storepass ${JDV_SERVER_KEYSTORE_JGROUPS_PASSWORD} -storetype JCEKS | grep ${JDV_SERVER_KEYSTORE_JGROUPS_ALIAS} | wc -l`" == 0 ] && echo "FAILED: could not verify the jgroups keystore was created successfully" && exit 1


echo 'Creating a new project called jdv-demo'
oc new-project ${OPENSHIFT_PRIMARY_PROJECT}

echo 'Creating the image stream for the OpenShift datavirt image'
# oc create -f https://raw.githubusercontent.com/cvanball/jdv-ose-demo/master/extensions/is.json
oc get is jboss-datavirt63-openshift || oc import-image jboss-datavirt63-openshift --from='registry.access.redhat.com/jboss-datavirt-6/datavirt63-openshift' --all --confirm || { echo "FAILED: Could not create required image stream" && exit 1; }
{ oc get is jboss-datavirt63-openshift && oc tag --source=istag jboss-datavirt63-openshift:latest jboss-datavirt63-openshift:1.1 ; } || { echo "FAILED: Could not tag the image to the correct version" && exit 1; }

echo 'Creating the s2i quickstart template. This will live in the openshift namespace and be available to all projects'
#oc get template datavirt63-extensions-support-s2i || oc create -f https://raw.githubusercontent.com/jboss-openshift/application-templates/master/datavirt/datavirt63-extensions-support-s2i.json || { echo "FAILED: Could not login" && exit 1; }
oc get template datavirt63-extensions-support-s2i 2>&1 > /dev/null || oc create -f datavirt63-extensions-support-s2i.json || { echo "FAILED: Could not create JDV application template" && exit 1; }

echo 'Creating a service account and accompanying secret for use by the data virt application'
oc get serviceaccounts datavirt-service-account 2>&1 > /dev/null || echo '{"kind": "ServiceAccount", "apiVersion": "v1", "metadata": {"name": "datavirt-service-account"}}' | oc create -f - || { echo "FAILED: could not create datavirt service account" && exit 1; }


echo 'Creating secrets for the JDV server'
oc get secret datavirt-app-secret 2>&1 > /dev/null || oc secrets new datavirt-app-secret ${JDV_SERVER_KEYSTORE_DEFAULT} ${JDV_SERVER_KEYSTORE_JGROUPS}

oc get sa/datavirt-service-account -o json | grep datavirt-app-secret 2>&1 > /dev/null || oc secrets link datavirt-service-account datavirt-app-secret || { echo "FAILED: could not link secret to service account" && exit 1; }

echo 'Retrieving datasource properties (market data flat file and country list web service hosted on public internet)'
{ [ -f datasources.properties ] || curl https://raw.githubusercontent.com/cvanball/jdv-ose-demo/master/extensions/datasources.properties -o datasources.properties ; } && { oc secrets new datavirt-app-config datasources.properties  || { echo "FAILED" && exit 1; } ; }

echo 'Deploying JDV quickstart template with default values'
oc get dc/datavirt-app 2>&1 >/dev/null || oc new-app datavirt63-extensions-support-s2i --param=IMAGE_STREAM_NAMESPACE=${OPENSHIFT_PRIMARY_PROJECT} --param=SOURCE_REPOSITORY_URL=https://github.com/cvanball/jdv-ose-demo --param=CONTEXT_DIR=vdb --param=EXTENSIONS_REPOSITORY_URL=https://github.com/cvanball/jdv-ose-demo --param=EXTENSIONS_DIR=extensions --param=TEIID_USERNAME=teiidUser --param=TEIID_PASSWORD=redhat1! -l app=${OPENSHIFT_APPLICATION_NAME}
# oc new-app datavirt63-extensions-support-s2i --param=IMAGE_STREAM_NAMESPACE=${OPENSHIFT_PRIMARY_PROJECT} --param=SOURCE_REPOSITORY_URL=https://github.com/cvanball/jdv-ose-demo --param=CONTEXT_DIR=vdb --param=EXTENSIONS_REPOSITORY_URL=https://github.com/cvanball/jdv-ose-demo --param=EXTENSIONS_DIR=extensions --param=TEIID_USERNAME=teiidUser --param=TEIID_PASSWORD=redhat1! -l app=${OPENSHIFT_APPLICATION_NAME} --as-test=true -o json > test-application.json
# oc new-app datavirt63-extensions-support-s2i --param=IMAGE_STREAM_NAMESPACE=mepley-jdvdemo --param=SOURCE_REPOSITORY_URL=https://github.com/cvanball/jdv-ose-demo --param=CONTEXT_DIR=vdb --param=EXTENSIONS_REPOSITORY_URL=https://github.com/cvanball/jdv-ose-demo --param=EXTENSIONS_DIR=extensions --param=TEIID_USERNAME=teiidUser --param=TEIID_PASSWORD=redhat1! -l app=jdvdemo --as-test=true -o json > test-application.json
[ `oc get dc/datavirt-app --template='{{(index .spec.template.spec.containers 0).resources.limits.memory}}{{printf "\n"}}'` == "1Gi" ] || oc patch dc/datavirt-app -p '{"spec" : { "template" : { "spec" : { "containers" : [ { "name" : "datavirt-app", "resources" : { "limits" : { "cpu" : "1000m" , "memory" : "1024Mi" }, "requests" : { "cpu" : "500m"  , "memory" : "1024Mi" } } } ] } } } }' || { echo "FAILED: Could not set application resource limits" && exit 1; }

echo "	--> verify the service is active"
curl -sS -k -u 'teiidUser:redhat1!'" http://datavirt-app-${OPENSHIFT_PRIMARY_PROJECT}.${OPENSHIFT_PRIMARY_APPS}"'/odata4/country-ws/country/Countries?$format=json' | jq -c -e -M --tab '.' | grep Zimbabwe || { echo "WARNING: failed to validate the service is available" ; }
echo "==============================================="
echo '--> Example data service access'
echo '	--> The following urls will allow you to access the vdbs (of which there are two) via OData2 and OData4:'
echo '	--> by default, JDV secures odata sources with the standard teiid-security security domain.'
echo '	--> if prompted for username/password: username = teiidUser password = redhat1!'
# reminder: for curl, use curl -u teiidUser:redhat1!
echo "==============================================="
echo "	--> Metadata for Country web service"
echo "		--> (odata 2) http://datavirt-app-${OPENSHIFT_PRIMARY_PROJECT}.${OPENSHIFT_PRIMARY_APPS}"'/odata/country-ws/$metadata'
echo "		--> (odata 4) http://datavirt-app-${OPENSHIFT_PRIMARY_PROJECT}.${OPENSHIFT_PRIMARY_APPS}"'/odata4/country-ws/country/$metadata'
echo "	--> Querying data from Country web service"
echo "		--> (odata 2) http://datavirt-app-${OPENSHIFT_PRIMARY_PROJECT}.${OPENSHIFT_PRIMARY_APPS}"'/odata/country-ws/country.Countries?$format=json'
echo "		--> (odata 4) http://datavirt-app-${OPENSHIFT_PRIMARY_PROJECT}.${OPENSHIFT_PRIMARY_APPS}"'/odata4/country-ws/country/Countries?$format=json'
echo "	--> Querying data from Country web service via primary key"
echo "		--> (odata 2) http://datavirt-app-${OPENSHIFT_PRIMARY_PROJECT}.${OPENSHIFT_PRIMARY_APPS}"'/odata/country-ws/country.Countries('\''Zimbabwe'\'')?$format=json '
echo "		--> (odata 4) http://datavirt-app-${OPENSHIFT_PRIMARY_PROJECT}.${OPENSHIFT_PRIMARY_APPS}"'/odata4/country-ws/country/Countries('\''Zimbabwe'\'')?$format=json'
echo "	--> Querying data from Country web service and returning specific fields"
echo "		--> (odata 2) http://datavirt-app-${OPENSHIFT_PRIMARY_PROJECT}.${OPENSHIFT_PRIMARY_APPS}"'/odata/country-ws/country.Countries?$select=name&$format=json'
echo "		--> (odata 4) http://datavirt-app-${OPENSHIFT_PRIMARY_PROJECT}.${OPENSHIFT_PRIMARY_APPS}"'/odata4/country-ws/country/Countries?$select=name&$format=json'
echo "	--> Querying data from Country web service and showing top 5 results"
echo "		--> (odata 2) http://datavirt-app-${OPENSHIFT_PRIMARY_PROJECT}.${OPENSHIFT_PRIMARY_APPS}"'/odata/country-ws/country.Countries?$top=5&$format=json'
echo "		--> (odata 4) http://datavirt-app-${OPENSHIFT_PRIMARY_PROJECT}.${OPENSHIFT_PRIMARY_APPS}"'/odata4/country-ws/country/Countries?$top=5&$format=json'
echo "==============================================="

echo "Done."