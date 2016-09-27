# Murano Etherpad Example.

This is a Murano package that deploys Etherpad designed for the Nectar cloud. It is intended to be a useful application for general purposes and also provide a reference implementation from The University of Melbourne's Nectar community.

Links
* [https://wiki.openstack.org/wiki/Murano]
* [http://nectar.org.au]
* [http://etherpad.org/]

## Building the Murano package

Murano packages are shipped as zip files. I've used [Make](https://www.gnu.org/software/make/) here to construct it. Use make on any GNU system to generate DemoEtherpad.zip
```
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

## Contents of the package

..
