fish_add_path -g $HOME/.local/share/fnm $HOME/.local/bin $HOME/go/bin $HOME/.cargo/bin $HOME/.atuin/bin

if status is-interactive
    # Commands to run in interactive sessions can go here
    set fish_greeting
    # if type -q pokemon-colorscripts
    #     pokemon-colorscripts --no-title -r
    # end
    
    # Hydro prompt configuration
    set -g hydro_symbol_prompt "❯"
    set -g hydro_color_pwd cyan
    set -g hydro_color_git purple
    set -g hydro_symbol_git_dirty " "
    set -g hydro_symbol_git_ahead " 󰶣"
    set -g hydro_symbol_git_behind " 󰶡"
    set -g hydro_multiline true

    if test -f ~/.cache/ags/user/generated/terminal/sequences.txt
        cat ~/.cache/ags/user/generated/terminal/sequences.txt
    end

    # general aliases
    alias ..="cd .."
    alias lns="ln -s" # target file location -> destination file location
    alias v="nvim"
    alias l="ls"
    alias c="clear"
    alias ff="fastfetch"
    alias cat="bat --style=plain --paging=never"
    alias ls="eza --icons --group-directories-first"
    alias ll="eza -la --icons --group-directories-first --git"
    alias tree="eza --tree --icons"
    alias oc="opencode"
    alias lg="lazygit"
    alias ai-start="sudo systemctl start ollama"
    alias ai-stop="sudo systemctl stop ollama"
    alias ai-status="systemctl status ollama"

    # Fedora package helpers
    alias dupi="sudo dnf upgrade --refresh"   # full upgrade
    alias dchk="sudo dnf check-update"        # check available updates
    alias di="sudo dnf install"               # install packages
    alias dr="sudo dnf remove"                # remove packages
    alias ds="dnf search"                     # search packages
    alias dl="dnf list --installed"           # list installed packages
    alias dclean="sudo dnf clean all; sudo dnf autoremove -y" # clean cache + orphaned deps
    alias drep="dnf repolist"                 # show enabled repos

    # Git delta for better diffs
    if type -q delta
        set -gx GIT_PAGER "delta"
    end

    # docker aliases
    alias dc="sudo docker-compose"
    alias dr="sudo docker"

    # Enhanced tmux aliases 
    alias txfr="tmuxifier"
    alias tm="tmux"
    alias ta="tmux attach-session -t"
    alias tn="tmux new-session -s"
    alias tl="tmux list-sessions"
    alias tk="tmux kill-session -t"
    alias tka="tmux kill-server"  # Kill all sessions
    alias txsrc="tmux source-file ~/.tmux.conf"
    alias diskusg="df -h | grep /dev/nvme0n1p2"

    function killport
        if test -z $argv[1]
            echo "Usage: killport <port>"
            return 1
        end
        set -l pid (lsof -ti :$argv[1])
        if test -n "$pid"
            echo "Killing process on port $argv[1] (PID: $pid)"
            kill -9 $pid
        else
            echo "No process found on port $argv[1]"
        end
    end

    zoxide init fish --cmd cd | source

    # FZF configuration for better fuzzy finding
    if type -q fzf
        set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border --inline-info"
        # Use fd for file/directory search if available
        if type -q fd
            set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --follow --exclude .git"
            set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
            set -gx FZF_ALT_C_COMMAND "fd --type d --hidden --follow --exclude .git"
        end
    end

    if type -q atuin
        atuin init fish | source
    end

    if type -q carapace
        carapace _carapace fish | source
    end

    # FNM (Fast Node Manager) - conditional
    if type -q fnm
        if test -d ~/.local/share/fnm
            set -gx PATH ~/.local/share/fnm $PATH
        end
        function __auto_fnm --on-variable PWD --description "Load fnm when entering a Node project"
            if test -f .node-version -o -f .nvmrc
                fnm env --use-on-cd | source
                functions -e __auto_fnm
            end
        end
        __auto_fnm
    end

    if command -v fnm >/dev/null 2>&1
        fnm env --shell fish | source
    end

    if type -q direnv
        direnv hook fish | source
    end
end

# opencode
if test -d $HOME/.opencode/bin
    fish_add_path $HOME/.opencode/bin
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
