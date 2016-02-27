TARGETS := trusty xenial

all: $(TARGETS)

$(TARGETS): % : %.sh Vagrantfile
	vagrant up --no-provision
	vagrant provision --provision-with $@

release:
	docker push ailispaw/ubuntu-essential

clean:
	vagrant destroy -f
	$(RM) -r .vagrant

.PHONY: $(TARGETS) release clean
