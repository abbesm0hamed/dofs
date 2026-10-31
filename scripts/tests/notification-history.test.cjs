const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const history = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(__dirname, '../../home/dot_config/quickshell/dofs/notifications/History.js'), 'utf8'), history);

assert.equal(history.plain('<b>Hello</b><br/>A &amp; B <3 &lt;script&gt;'), 'Hello\nA & B <3 <script>');
assert.equal(history.plain('a'.repeat(20000)).length, 12000);
assert.equal(history.matches(['CHAT'], {appName: 'Chat', appId: 'org.example.Chat'}), true);
assert.equal(history.matches(['org.example.Chat'], {appName: 'Chat', appId: 'org.example.Chat'}), true);
assert.equal(history.matches(['chat'], {appName: 'Other', appId: 'org.example.Chat'}), false);
const now = Date.now();
const options = {historyLimit: 2, retentionDays: 7};
const entries = [
    {id: 'old', timestamp: now - 8 * 86400000},
    {id: 'one', timestamp: now - 1000},
    {id: 'two', timestamp: now},
    {id: 'two', timestamp: now},
    {id: 'future', timestamp: now + 120000},
    {id: 'three', timestamp: now - 2000},
];
assert.equal(JSON.stringify(history.prune(entries, options, now).map(e => e.id)), '["two","one"]');
const searchable = [{appName: 'Chat', summary: 'Lunch', body: 'Tomorrow at noon', read: false},
    {appName: 'Mail', summary: 'Report', body: 'Ready', read: true}];
assert.equal(history.filtered(searchable, 'chat tomorrow', false).length, 1);
assert.equal(history.filtered(searchable, 'chat report', false).length, 0);
assert.equal(history.filtered(searchable, '', true).length, 1);
console.log('Notification history helpers: all tests passed');
