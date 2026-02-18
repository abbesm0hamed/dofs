# Set a custom session root path. Default is `$HOME`.
# Must be called before `initialize_session`.
session_root "${TMUXIFIER_SESSION_ROOT:-$HOME}"

if initialize_session "${TMUXIFIER_SESSION_NAME:-dofs-dev}"; then

  tmux rename-window -t "$session:$window" "editor"

  tmux send-keys -t "$session:$window.0" "cd \"${TMUXIFIER_SESSION_ROOT:-$HOME}\"" C-m
  tmux send-keys -t "$session:$window.0" "nvim" C-m

  tmux split-window -t "$session:$window.0" -h -p 40
  tmux send-keys -t "$session:$window.1" "cd \"${TMUXIFIER_SESSION_ROOT:-$HOME}\"" C-m
  tmux send-keys -t "$session:$window.1" "opencode" C-m

  new_window "work"
  tmux send-keys -t "$session:$window.0" "cd \"${TMUXIFIER_SESSION_ROOT:-$HOME}\"" C-m

  tmux split-window -t "$session:$window.0" -h -p 50
  tmux send-keys -t "$session:$window.1" "cd \"${TMUXIFIER_SESSION_ROOT:-$HOME}\"" C-m

  tmux split-window -t "$session:$window.0" -v -p 20
  tmux send-keys -t "$session:$window.2" "cd \"${TMUXIFIER_SESSION_ROOT:-$HOME}\"" C-m

  select_window 0

fi

finalize_and_go_to_session
