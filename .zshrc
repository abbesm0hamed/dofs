#===============================================================================
# ZSH Core Configuration
#===============================================================================

# Startup Options
#-------------------------------------------------------------------------------
# Choose one of these for a nice start to zsh
# neofetch
# pfetch
# uwufetch
# pokemon-colorscripts -r --no-title

#===============================================================================
# Terminal Cursor Configuration
#===============================================================================
# Make cursor bold and block style
# echo -ne '\e[2 q' # This sets block cursor
# Change cursor shape for different vi modes
# 0  ➜  blinking block
# 1  ➜  blinking block (default)
# 2  ➜  steady block ("█")
# 3  ➜  blinking underline
# 4  ➜  steady underline
# 5  ➜  blinking bar
# 6  ➜  steady bar
# cursor_mode() {
#     # Terminal cursor commands
#     echo -ne '\e[2 q'
#     echo -ne "\033]12;white\007" # Set cursor color to white for visibility
# }
# precmd_functions+=(cursor_mode)

# Powerlevel10k Instant Prompt
#-------------------------------------------------------------------------------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#===============================================================================
# Plugin Manager Setup (Zinit)
#===============================================================================
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Auto-install Zinit
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

#===============================================================================
# Shell Integrations
#===============================================================================
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

#===============================================================================
# Plugin Configuration
#===============================================================================

# Theme
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Core Plugins (with lazy loading)
zinit wait lucid for \
    atinit"zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting \
    atload"_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions \
    blockf atpull'zinit creinstall -q .' \
    zsh-users/zsh-completions \
    kutsan/zsh-system-clipboard

# FZF Tab Completion
zinit wait lucid for \
    Aloxaf/fzf-tab

# Utility Plugins
zinit wait lucid for \
    OMZP::git \
    OMZP::sudo \
    OMZP::archlinux

# Cloud Tools Plugins
zinit ice wait"2" lucid as"completion" has"aws"
zinit snippet OMZP::aws

zinit ice wait"2" lucid as"completion" has"kubectl"
zinit snippet OMZP::kubectl

zinit ice wait"2" lucid as"completion" has"kubectx"
zinit snippet OMZP::kubectx

zinit wait"2" lucid for \
    OMZP::command-not-found

#===============================================================================
# Keybindings
#===============================================================================

# Emacs Mode
bindkey -e

# Navigation
bindkey '^[[1;5D' backward-word     # Ctrl+Left
bindkey '^[[1;5C' forward-word      # Ctrl+Right
bindkey '^[b' backward-word         # Alt+B
bindkey '^[f' forward-word          # Alt+F

# History Navigation
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# Text Manipulation
bindkey '^W' backward-kill-word     # Standard Ctrl+W
bindkey '^[d' kill-word            # Alt+D for forward kill
bindkey '^[w' copy-region-as-kill  # Alt+W for copy region
bindkey '^[W' copy-prev-word       # Alt+Shift+W for copy word

# System Clipboard Operations
bindkey '^k' kill-line             # Cut to end of line
bindkey '^u' backward-kill-line    # Cut to start of line
bindkey '^y' yank                  # Paste

#===============================================================================
# Completion System
#===============================================================================

# Initialize Completion System
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
    compinit;
else
    compinit -C;
fi

# Completion Styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':completion:*' rehash true
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:*:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

#===============================================================================
# History Configuration
#===============================================================================
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

#===============================================================================
# Aliases
#===============================================================================
alias ls='ls --color'
alias c='clear'
alias v="nvim"
alias ll="lsd -la"
alias lg="lazygit"
alias tx="tmux"
alias txfr="tmuxifier"
alias ff="fastfetch"
alias dc="sudo docker-compose"
alias dr="sudo docker"
alias yup="yay -Syu"
alias ..="cd .."

#===============================================================================
# Environment Configuration
#===============================================================================

# Editor Setup
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# FZF Configuration
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

#===============================================================================
# Path Configuration
#===============================================================================
export PATH="$HOME/.local/share/fnm:$PATH"
export PATH="$HOME/.tmuxifier/bin:$PATH"
export PATH="$PATH:/usr/bin/docker"
export PATH="$PATH:$HOME/go/bin"
export PATH="$HOME/.encore/bin:$PATH"

#===============================================================================
# Tool-specific Configuration
#===============================================================================

# FNM (Fast Node Manager)
eval "$(fnm env --use-on-cd)"
FNM_HOME="$HOME/.fnm"
if [ -d "$FNM_HOME" ]; then
  export PATH="$FNM_HOME:$PATH"
  eval "$(fnm env)"
fi

# Angular CLI
source <(ng completion script 2>/dev/null)

# PNPM
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Source Powerlevel10k Configuration
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
