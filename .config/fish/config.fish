function fish_prompt -d "Write out the prompt"
    # This shows up as USER@HOST /home/user/ >, with the directory colored
    # $USER and $hostname are set by fish, so you can just use them
    # instead of using `whoami` and `hostname`
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
end

if status is-interactive
    # Commands to run in interactive sessions can go here
    set fish_greeting
    # if type -q pokemon-colorscripts
    #     pokemon-colorscripts --no-title -r
    # end
end

# Starship prompt (conditional)
if type -q starship
    starship init fish | source
end
if test -f ~/.cache/ags/user/generated/terminal/sequences.txt
    cat ~/.cache/ags/user/generated/terminal/sequences.txt
end

# general aliases
alias pamcan=pacman
alias lns="ln -s" # target file location -> desitnation file location
alias ll="ls -la"
alias v="nvim"
alias c="clear"
alias ll="lsd -la"
alias lg="lazygit"
alias ff="fastfetch"
alias ..="cd .."

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

set -gx PATH $PATH $HOME/go/bin

# function fish_prompt
#   set_color cyan; echo (pwd)
#   set_color green; echo '> '
# end
