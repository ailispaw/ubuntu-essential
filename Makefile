TARGETS := bionic xenial trusty

all: $(TARGETS) nodoc

$(TARGETS): % : %.sh Vagrantfile | vagrant
	vagrant provision --provision-with $@
	$(RM) $@.pkg $@.manifest
	docker run -t --rm $$(docker images -q | head -1) dpkg --get-selections > $@.pkg
	docker run -t --rm $$(docker images -q | head -1) dpkg-query -W > $@.manifest

nodoc: nodoc.sh Vagrantfile | vagrant
	vagrant provision --provision-with $@

release:
	docker push ailispaw/ubuntu-essential

vagrant:
	vagrant up --no-provision

clean:
	vagrant destroy -f
	$(RM) -r .vagrant

.PHONY: $(TARGETS) nodoc release vagrant clean
