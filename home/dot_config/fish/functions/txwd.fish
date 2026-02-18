function txwd
    set -l root (pwd)
    set -l name (basename $root)
    set -l session "dev-$name"

    if type -q tmuxifier
        set -lx TMUXIFIER_SESSION_ROOT "$root"
        set -lx TMUXIFIER_SESSION_NAME "$session"
        tmuxifier load-session dofs-dev
        return $status
    end

    if not type -q tmux
        echo "tmux not found"
        return 127
    end

    tmux has-session -t "$session" 2>/dev/null
    if test $status -ne 0
        tmux new-session -d -s "$session" -c "$root" -n editor
        tmux send-keys -t "$session:editor.0" "nvim" C-m

        tmux split-window -t "$session:editor.0" -h -p 30 -c "$root"
        tmux send-keys -t "$session:editor.1" "opencode" C-m

        tmux new-window -t "$session" -n work -c "$root"
        tmux split-window -t "$session:work.0" -h -p 50 -c "$root"
        tmux split-window -t "$session:work.0" -v -p 20 -c "$root"
        tmux select-window -t "$session:editor"
        tmux select-pane -t "$session:editor.0"
    end

    if set -q TMUX
        tmux switch-client -t "$session"
    else
        tmux attach-session -t "$session"
    end
end
