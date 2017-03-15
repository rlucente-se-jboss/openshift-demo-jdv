#!/bin/bash	
# Configuration

. ./config.sh || { echo "FAILED: Could not verify configuration" && exit 1; }
. ./config-jdv.sh || { echo "FAILED: Could not configure JDV" && exit 1; }

echo "Cleaning up sample PHP + MySQL demo application"
. ./setup-login.sh -r OPENSHIFT_USER_RHSADEMO_MEPLEY || { echo "ERROR: Could not login" && exit 1; }
echo "	--> delete all local artifacts"
rm -f ${JDV_SERVER_KEYSTORE_DEFAULT}
rm -f ${JDV_SERVER_KEYSTORE_JGROUPS}
echo "	--> delete all openshift resources"
oc delete template datavirt63-extensions-support-s2i || { echo "WARNING: Could not delete old application template" ; }
oc delete is jboss-datagrid65-client-openshift  || { echo "WARNING: Could not delete old image" ; }
oc delete is jboss-datavirt63-openshift || { echo "WARNING: Could not delete old image" ; }
oc delete sa datavirt-service-account || { echo "WARNING: Could not delete old service account" ; }
oc delete secret datavirt-app-secret || { echo "WARNING: Could not delete old secrets" ; }
oc delete secret datavirt-app-config || { echo "WARNING: Could not delete old secrets" ; }
oc delete all -l app=${OPENSHIFT_APPLICATION_NAME}  || { echo "WARNING: Could not delete old application resources" ; }
echo "	--> delete project"
# oc delete project ${OPENSHIFT_PRIMARY_PROJECT_DEFAULT}
oc whoami ||  echo `oc whoami` "still logged in; use 'oc logout' to logout of openshift"
echo "Done"
