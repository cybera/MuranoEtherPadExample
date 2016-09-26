# For building the murano package as a zip file

source_files = \
	manifest.yaml \
	logo.png \
	Classes/Etherpad.yaml \
	Resources/Deploy.template \
	Resources/scripts/deploy.sh \
	UI/ui.yaml

compile=zip -r
RM=rm -f
CAT=cat
SED=sed
ECHO=echo "\n"

targets = DemoEtherpad.zip 

all: $(targets)
	-@$(ECHO) "*** Build complete"

DemoEtherpad.zip: $(source_files) 
	-@$(ECHO) "*** Building murano zip package"
	$(compile) $@ $^

.PHONY: clean
clean:
	-@$(ECHO) "*** Removing $(targets)"
	-@ $(RM) $(targets)


