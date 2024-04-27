# My DOtFileS

This directory contains my dotfiles 

## Requirements

Ensure you have the following installed on your system

### Git

```
pacman -S git
```

### Stow

```
pacman -S stow
```

## Installation

First, check out the dotfiles repo in your $HOME directory using git

```
$ git clone git@github.com:abbesm0hamed/dofs.git
$ cd dofs
```

then use GNU stow to create symlinks

```
$ stow .
```
Clone widgets under awesome config folder
```
$ cd dofs/.config/awesome
$ git clone git@github.com:streetturtle/awesome-wm-widgets.git
```
