all: zip upload

zip:
	rm ca.cybera.Etherpad.zip || true
	zip -r ca.cybera.Etherpad.zip *

upload:
	murano package-import --is-public --exists-action u ca.cybera.Etherpad.zip
