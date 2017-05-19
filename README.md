# A Simple demo for JBoss Data Virtualization (JDV) on Openshift Container Management Platform (OCP)

#About
Some simple scripts to setup a basic demo of JBoss Data Virtualization (JDV) with the Red Hat Openshift Container Platform (OCP).

Important notes: 
- For Red Hat PS MW SAs, this has been validated against the latest release candidate for CDK3 as well as rhsademo and this is the recommended platform.
- Assumes password authentication
- In general these scripts attempt to do simple validation checks and attempt to prevent unnecessary processes. It _should_ be generally safe to rerun any of these at any time without causing any harm.
- When in doubt, run the **clean.sh** script

#Prerequisites

You'll need a couple of things for this demo to work. Most of these are standard kit for Red Hat PS MW SAs.
- an existing installation of Openshift Container Platform (using the CDK3 with minishift)
- the requisite JBoss xPaaS images installed on this instance
- an account with default privileges on this instance
- sufficient resource quotas (recommend 10 services, 10 pods, 6 CPUs, 6 GB Ram, 6 GB storage) -- CDK3 is given 4 cores and 12288 MB memory
- a local workstation with a (small) amount of storage; Fedora 24+ recommended; CDK3 has 50 GB storage
- command line tools: bash 4.2+ ; openshift [cli tools](https://access.redhat.com/downloads/content/290) (user account at access.redhat.com required)
- eclipse with teiid, openshift, git, maven, and a handful of other plugins; [JBoss Developer Studio 10.0+](http://developers.redhat.com/products/devstudio/download/) (user account at access.redhat.com required) recommended as it already has the necessary plugins
- a web browser; Firefox 48+ recommended

#Workflow

The recommend workflow is
- clone this repository
- set your password via an environment variable; if present OPENSHIFT\_RHSADEMO\_USER\_PASSWORD\_DEFAULT will be used, otherwise it expects OPENSHIFT\_PRIMARY\_USER\_PASSWORD\_DEFAULT
- verify any settings in **config.sh** are correct; primarily this will be to point to the correct Openshift instance and **setting your username**
- on your local workstation in a bash terminal, run **run-demo.sh**
  * this script will launch several other **setup-*.sh** scripts
  * these scripts will output basic information to the terminal describing the steps
  * these scripts will pause and wait for the user to hit _enter_ at various points so the presenter can show items in the web console, discuss the process steps, or other activities 
- run **clean.sh** to remove any script and openshift artifacts; the eclipse project/artifacts are left in place in case you want to keep them


#References

This demo is partly based on
- https://developerblog.redhat.com/2016/12/06/red-hat-jboss-data-virtualization-on-openshift-part-1-getting-started/
- https://developers.redhat.com/blog/2016/12/07/red-hat-jboss-data-virtualization-on-openshift-part-2-service-enable-your-data/
- https://developers.redhat.com/blog/2016/12/14/red-hat-jboss-data-virtualization-on-openshift-part-3-data-federation/


