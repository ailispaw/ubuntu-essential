TARGETS := trusty xenial

all: $(TARGETS)

$(TARGETS): % : %.sh Vagrantfile
	vagrant up --no-provision
	vagrant provision --provision-with $@
	docker run -t --rm $$(docker images -q | head -1) dpkg --get-selections > $@.pkg

release:
	docker push ailispaw/ubuntu-essential

clean:
	vagrant destroy -f
	$(RM) -r .vagrant
	$(RM) *.pkg

.PHONY: $(TARGETS) release clean
