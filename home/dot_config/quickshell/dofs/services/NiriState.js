// Pure event reducer. Unknown events and temporary cross-event inconsistencies
// are normal in Niri; never query/poll a second snapshot to repair them.
function initial() { return {workspaces: [], windows: []}; }
function update(items, predicate, changes) {
    return items.map(item => predicate(item) ? Object.assign({}, item, changes) : item);
}
function reduce(state, event) {
    var ws = state.workspaces, windows = state.windows, e;
    if ((e = event.WorkspacesChanged)) ws = e.workspaces;
    else if ((e = event.WorkspaceActivated)) {
        var active = ws.find(w => w.id === e.id);
        ws = ws.map(w => Object.assign({}, w, {
            is_active: active && w.output === active.output ? w.id === e.id : w.is_active,
            is_focused: e.focused ? w.id === e.id : w.is_focused
        }));
    } else if ((e = event.WorkspaceUrgencyChanged)) ws = update(ws, w => w.id === e.id, {is_urgent: e.urgent});
    else if ((e = event.WorkspaceActiveWindowChanged)) ws = update(ws, w => w.id === e.workspace_id, {active_window_id: e.active_window_id});
    else if ((e = event.WindowsChanged)) windows = e.windows;
    else if ((e = event.WindowOpenedOrChanged)) {
        windows = windows.filter(w => w.id !== e.window.id);
        if (e.window.is_focused) windows = update(windows, () => true, {is_focused: false});
        windows = windows.concat([e.window]);
    } else if ((e = event.WindowClosed)) windows = windows.filter(w => w.id !== e.id);
    else if ((e = event.WindowFocusChanged)) windows = windows.map(w => Object.assign({}, w, {is_focused: w.id === e.id}));
    else if ((e = event.WindowUrgencyChanged)) windows = update(windows, w => w.id === e.id, {is_urgent: e.urgent});
    else return state;
    return {workspaces: ws, windows: windows};
}
function onOutput(state, output) {
    return state.workspaces.filter(w => w.output === output).sort((a, b) => a.idx - b.idx);
}
function titleOnOutput(state, output) {
    var workspace = state.workspaces.find(w => w.output === output && w.is_active);
    var window = workspace && state.windows.find(w => w.id === workspace.active_window_id);
    return window ? window.title || window.app_id || "" : "";
}
