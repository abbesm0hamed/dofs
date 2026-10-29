const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const api = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(__dirname, '../../home/dot_config/quickshell/dofs/services/NiriState.js'), 'utf8'), api);
const clean = value => JSON.parse(JSON.stringify(value));
let state = api.initial();
const reduce = event => state = api.reduce(state, event);
reduce({WorkspacesChanged: {workspaces: [
    {id: 10, idx: 2, output: 'A', is_active: false, is_focused: false},
    {id: 11, idx: 1, output: 'A', is_active: true, is_focused: true, active_window_id: 5},
    {id: 12, idx: 1, output: 'B', is_active: true, is_focused: false, active_window_id: 6}
]}});
reduce({WindowsChanged: {windows: [
    {id: 5, title: '<b>literal title</b>', is_focused: true},
    {id: 6, title: 'Second monitor', is_focused: false}
]}});
assert.deepEqual(clean(api.onOutput(state, 'A')).map(w => w.id), [11, 10]);
assert.equal(api.titleOnOutput(state, 'A'), '<b>literal title</b>');
assert.equal(api.titleOnOutput(state, 'B'), 'Second monitor');
const old = state;
reduce({WorkspaceActivated: {id: 10, focused: true}});
assert.equal(old.workspaces[0].is_active, false, 'must not mutate old state');
assert.equal(state.workspaces.find(w => w.id === 12).is_active, true);
assert.deepEqual(clean(state.workspaces.filter(w => w.is_focused)).map(w => w.id), [10]);
reduce({WorkspaceActiveWindowChanged: {workspace_id: 10, active_window_id: 99}});
assert.equal(api.titleOnOutput(state, 'A'), '', 'tolerate window event arriving later');
reduce({WindowOpenedOrChanged: {window: {id: 99, title: 'New', is_focused: true}}});
assert.equal(api.titleOnOutput(state, 'A'), 'New');
assert.deepEqual(clean(state.windows.filter(w => w.is_focused)).map(w => w.id), [99]);
reduce({WindowFocusChanged: {id: null}});
assert.equal(state.windows.some(w => w.is_focused), false);
reduce({WindowUrgencyChanged: {id: 99, urgent: true}});
reduce({WorkspaceUrgencyChanged: {id: 10, urgent: true}});
assert.equal(state.windows.find(w => w.id === 99).is_urgent, true);
assert.equal(state.workspaces.find(w => w.id === 10).is_urgent, true);
reduce({WindowClosed: {id: 99}});
assert.equal(api.titleOnOutput(state, 'A'), '');
reduce({WorkspacesChanged: {workspaces: []}});
assert.deepEqual(clean(api.onOutput(state, 'A')), []);
assert.equal(api.titleOnOutput(state, 'A'), '');
const same = state;
reduce({FutureEvent: {newField: true}});
assert.equal(state, same);
console.log('Niri reducer: all assertions passed');
