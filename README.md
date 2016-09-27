# Murano Etherpad Example.

This Murano package designed for the Nectar cloud deploys Etherpad. Etherpad is a collaborative notepad editor that works on any modern web browser. It is intended to be a useful application for general purposes and also provides a reference implementation as a contribution from The University of Melbourne's Nectar community.

**This setup is not designed to be a long-standing Etherpad server**. Start a new instance of Etherpad using Murano and use it for your workshop/conference/etc for the next few days. Once you are done you should shutdown the instance from Nectar dashboard.

Links
* https://wiki.openstack.org/wiki/Murano
* http://nectar.org.au
* http://etherpad.org/

## Building the Murano package

Murano packages are shipped as zip files. I've used [Make](https://www.gnu.org/software/make/) here to construct it. Use make on any GNU system to generate DemoEtherpad.zip
```
$> git clone https://github.com/AlanCLo/MuranoEtherPadExample.git
$> cd MuranoEtherPadExample
$> make

 *** Building murano zip package
zip -r DemoEtherpad.zip manifest.yaml logo.png Classes/Etherpad.yaml Resources/Deploy.template Resources/scripts/deploy.sh UI/ui.yaml
  adding: manifest.yaml (deflated 37%)
  adding: logo.png (deflated 1%)
  adding: Classes/Etherpad.yaml (deflated 62%)
  adding: Resources/Deploy.template (deflated 37%)
  adding: Resources/scripts/deploy.sh (deflated 45%)
  adding: UI/ui.yaml (deflated 65%)

 *** Build complete
```

## Using the Murano package

Dependencies
* NeCTAR Ubuntu 16.04 LTS (Xenial) amd64 (pre-install murano-agent)
* Minimum Root Disk size: 5GB

Check the Murano's quickstart guide here: http://docs.openstack.org/developer/murano/enduser-guide/quickstart.html

Once the deployment is complete, point your web browser to the IP address of the new server displayed on the Nectar Dashboard.

## Setup

This package performs a simple deployment of Etherpad 1.6.0 specifically on a single Ubuntu server with the following configuration:
* Etherpad runs directly on port 80 (http)
* Etherpad is process controlled by supervisord to automatically restart
* Data is stored locally on "dirtydb" mode

This is not designed to be a long-standing deployment.

## Main contents of the package

1. Resources/scripts/deploy.sh
 * Installs and configures the application after VM is instantiated
2. UI/ui.yaml
 * Defines all the variables & labels in the Dashboard wizard to setup the application
3. Classes/Etherpad.yaml
 * Backend Murano script that orchestrates the deployment process based on parameters provided

