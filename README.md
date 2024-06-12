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
### AwesomeWM setup
Clone widgets under awesome config folder
```
$ cd dofs/.config/awesome
$ git clone https://github.com/horst3180/arc-icon-theme --depth 1 && cd arc-icon-theme 
$ ./autogen.sh --prefix=/usr
$ sudo make install
$ sudo pacman -S acpi lxpolkit pacman-contrib
$ git clone git@github.com:streetturtle/awesome-wm-widgets.git
```

### Credits
https://gitlab.com/thelinuxcast/my-dots.git
https://github.com/Brannigan123/polybar-config.git


