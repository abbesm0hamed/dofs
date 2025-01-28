# Chose between one of these for a nice start to zsh
# neofetch
# pfetch
# uwufetch
pokemon-colorscripts -r --no-title; sleep .1

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins with lazy loading
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

# Add in snippets with lazy loading
zinit wait lucid for \
    OMZP::git \
    OMZP::sudo \
    OMZP::archlinux

# Load cloud-related plugins only when needed
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

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# History
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
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='ls --color'
alias c='clear'
alias v="nvim"
alias ll="lsd -la"
alias lg="lazygit"
alias tx="tmux"
alias txfr="tmuxifier"
alias dc="sudo docker-compose"
alias dr="sudo docker"
alias ..="cd .."

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# fnm
export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env --use-on-cd)"

# tmuxifier
export PATH="$HOME/.tmuxifier/bin:$PATH"

# docker 
export PATH="$PATH:/usr/bin/docker"

# Lazy load shell integrations
function load_fzf() {
  eval "$(fzf --zsh)"
}
alias fzf='load_fzf && fzf'

function load_zoxide() {
  eval "$(zoxide init --cmd cd zsh)"
}
alias z='load_zoxide && z'

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit wait"3" lucid for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

# encore 
export PATH="$HOME/.encore/bin:$PATH"

# added go path to be able to reach for binaries inside it 
export PATH=$PATH:$HOME/go/bin

# Lazy load Angular CLI autocompletion
function load_ng_completion() {
  source <(ng completion script)
}
alias ng='load_ng_completion && ng'

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# fnm
FNM_PATH="$HOME/.fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "`fnm env`"
fi
