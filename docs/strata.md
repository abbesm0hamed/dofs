# Strata file manager

[Strata](https://github.com/lgse/strata) is installed per-user by the
`strata` Ansible role, alongside Nautilus. It is a Rust/GTK4, keyboard-first
file manager with columns, tabs and previews.

## What the role does

- Installs Strata's Fedora runtime dependencies.
- Downloads the pinned release archive, verifies its SHA-256, and installs:
  - `~/.local/bin/strata`
  - `~/.local/share/applications/io.github.lgse.Strata.desktop`
  - `~/.local/share/icons/hicolor/scalable/apps/io.github.lgse.Strata.svg`
- Verifies the installed binary reports the pinned version.

It deliberately **does not** change the default handler for directories, the
`org.freedesktop.FileManager1` service, or the XDG file-chooser portal. Nautilus
remains the system default. Opt into desktop integration later with:

```bash
strata --install-portal   # use Strata as the file picker
```

## Run it

```bash
ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook ansible/playbook.yml \
  -i ansible/inventory --ask-become-pass --tags strata
```

## Version bumps

Versions live in `ansible/roles/strata/defaults/main.yml`:

1. Update `strata_version`.
2. Update `strata_checksums` from the matching `.sha256` assets on the
   [release page](https://github.com/lgse/strata/releases).
3. Re-run the role.

The role compares the pinned version with `strata --version`, so a build
updated through Strata's in-app updater is brought back to the pinned release
on the next Ansible run. This keeps the install reproducible.

## Launching it

Strata registers a desktop entry, so it appears in the launcher and dock. The
current Niri binding still opens Nautilus; point `Alt+E` in
`home/dot_config/niri/binds.kdl` at `strata` when ready to switch.
