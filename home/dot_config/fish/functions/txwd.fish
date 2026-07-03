function txwd
    set -l root (pwd)
    set -l name (basename $root)
    set -l session "dev-$name"

    if not type -q tmux
        echo "tmux not found"
        return 127
    end

    tmux has-session -t "$session" 2>/dev/null
    if test $status -ne 0
        tmux new-session -d -s "$session" -c "$root" -n editor
        tmux send-keys -t "$session:editor.0" "nvim" C-m

        tmux new-window -t "$session" -n work -c "$root"
        tmux split-window -t "$session:work.0" -h -p 50 -c "$root"
        tmux split-window -t "$session:work.0" -v -p 20 -c "$root"

        tmux new-window -t "$session" -n herdr -c "$root"
        tmux send-keys -t "$session:herdr.0" "herdr" C-m
        tmux split-window -t "$session:herdr.0" -h -p 35 -c "$root"
        tmux send-keys -t "$session:herdr.1" "hunk diff --watch" C-m

        tmux select-window -t "$session:editor"
        tmux select-pane -t "$session:editor.0"
    end

    if set -q TMUX
        tmux switch-client -t "$session"
    else
        tmux attach-session -t "$session"
    end
end
