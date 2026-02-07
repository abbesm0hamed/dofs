.PHONY: dotfiles-init dotfiles-apply dotfiles-diff waybar-reload waybar-apply update

DOTFILES_SOURCE := $(CURDIR)/home

dotit:
	chezmoi init --source $(DOTFILES_SOURCE) --force

dotapp:
	chezmoi apply --source $(DOTFILES_SOURCE) --force

dotdiff:
	chezmoi diff --source $(DOTFILES_SOURCE)

waybar-reload:
	pkill waybar || true
	sleep 0.2
	waybar &

waybar-apply: dotapp waybar-reload

update:
	./scripts/maintenance/update-all.sh

