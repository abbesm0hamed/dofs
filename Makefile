.PHONY: dotfiles-init dotfiles-apply dotfiles-diff waybar-reload waybar-apply setup install-packages update

DOTFILES_SOURCE := $(CURDIR)/home

dotinit:
	chezmoi init --source $(DOTFILES_SOURCE) --force

dotapply:
	chezmoi apply --source $(DOTFILES_SOURCE) --force

dotdiff:
	chezmoi diff --source $(DOTFILES_SOURCE)

waybar-reload:
	pkill waybar || true
	sleep 0.2
	waybar &

waybar-apply: dotapplly waybar-reload

setup:
	ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook ansible/playbook.yml -i ansible/inventory --ask-become-pass

install-packages:
	ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook ansible/playbook.yml -i ansible/inventory --ask-become-pass --tags repos,packages

update:
	./scripts/maintenance/update-all.sh
