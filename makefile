
my_ether.zip: logo.png manifest.yaml Classes/MyEther.yaml Resources/DeployEther.template Resources/scripts/deployEther.sh UI/ui.yaml
	zip -r $@ $?

clean:
	rm my_ether.zip

.PHONY: clean

