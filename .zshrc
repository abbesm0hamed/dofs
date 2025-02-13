# Chose between one of these for a nice start to zsh
# neofetch
# pfetch
# uwufetch
pokemon-colorscripts -r --no-title

# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Set up zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit if not present
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

# Shell integrations
eval "$(fzf --zsh)"
# Initialize zoxide properly
eval "$(zoxide init --cmd cd zsh)"

# Add Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Word jumping and other key bindings
bindkey '^[[1;5D' backward-word    # Ctrl+Left
bindkey '^[[1;5C' forward-word     # Ctrl+Right
bindkey '^W' backward-kill-word    # Ctrl+W to delete word
bindkey '^[b' backward-word        # Alt+B
bindkey '^[f' forward-word         # Alt+F
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region
bindkey -e  # Emacs key bindings

# Add zsh plugins with lazy loading
zinit wait lucid for \
    atinit"zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting \
    atload"_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions \
    blockf atpull'zinit creinstall -q .' \
    zsh-users/zsh-completions

# Load fzf-tab after compinit
zinit wait lucid for \
    Aloxaf/fzf-tab

# Add snippets with lazy loading
zinit wait lucid for \
    OMZP::git \
    OMZP::sudo \
    OMZP::archlinux

# Cloud-related plugins
zinit ice wait"2" lucid as"completion" has"aws"
zinit snippet OMZP::aws

zinit ice wait"2" lucid as"completion" has"kubectl"
zinit snippet OMZP::kubectl

zinit ice wait"2" lucid as"completion" has"kubectx"
zinit snippet OMZP::kubectx

zinit wait"2" lucid for \
    OMZP::command-not-found

# Load completions
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
    compinit;
else
    compinit -C;
fi

# Source p10k configuration
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# History configuration
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

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':completion:*' rehash true
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:*:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
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
alias ..="cd .."

# Editor configuration
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# FZF initialization
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Path updates
export PATH="$HOME/.local/share/fnm:$PATH"
export PATH="$HOME/.tmuxifier/bin:$PATH"
export PATH="$PATH:/usr/bin/docker"
export PATH="$PATH:$HOME/go/bin"
export PATH="$HOME/.encore/bin:$PATH"

# fnm
eval "$(fnm env --use-on-cd)"

# Angular CLI completion
source <(ng completion script 2>/dev/null)

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# fnm path (consolidated with earlier fnm setup)
FNM_HOME="$HOME/.fnm"
if [ -d "$FNM_HOME" ]; then
  export PATH="$FNM_HOME:$PATH"
  eval "$(fnm env)"
fi
