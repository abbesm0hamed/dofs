.PHONY: dotinit dotapply dotdiff bar-reload bar-apply setup install-packages cleanup-packages update

DOTFILES_SOURCE := $(CURDIR)/home

dotinit:
	chezmoi init --source $(DOTFILES_SOURCE) --force

dotapply:
	chezmoi apply --source $(DOTFILES_SOURCE) --force

dotdiff:
	chezmoi diff --source $(DOTFILES_SOURCE)

bar-reload:
	qs -c dofs kill || true
	qs -c dofs --daemonize --no-duplicate

bar-apply: dotapply bar-reload

setup:
	ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook ansible/playbook.yml -i ansible/inventory --ask-become-pass

install-packages:
	ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook ansible/playbook.yml -i ansible/inventory --ask-become-pass --tags repos,packages

cleanup-packages:
	ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook ansible/playbook.yml -i ansible/inventory --ask-become-pass --tags cleanup-packages

update:
	./scripts/maintenance/update-all.sh
