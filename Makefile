build: Vagrantfile build.sh
	vagrant up --no-provision
	vagrant provision

release:
	docker push ailispaw/ubuntu-essential

clean:
	vagrant destroy -f
	$(RM) -r .vagrant

.PHONY: build release clean
