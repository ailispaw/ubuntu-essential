TARGETS := xenial trusty

all: $(TARGETS)

$(TARGETS): % : %.sh Vagrantfile | vagrant
	vagrant provision --provision-with $@
	$(RM) $@.pkg
	docker run -t --rm $$(docker images -q | head -1) dpkg --get-selections > $@.pkg
	docker run -t --rm $$(docker images -q | head -1) dpkg-query -W > $@.manifest

release:
	docker push ailispaw/ubuntu-essential

vagrant:
	vagrant up --no-provision

clean:
	vagrant destroy -f
	$(RM) -r .vagrant

.PHONY: $(TARGETS) release vagrant clean
