// Plain, serializable history: never retain DBus objects or executable actions.
function plain(value) {
    return String(value || "").slice(0, 12000)
        .replace(/<br\s*\/?\s*>/gi, "\n")
        .replace(/<\/?(?:b|i|u|a|img|span)(?:\s[^>]*)?\s*\/?>/gi, "")
        .replace(/&(?:amp|lt|gt|quot|apos);/g, s => ({"&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": '"', "&apos;": "'"})[s]);
}
function matches(apps, entry) {
    return apps.some(app => [entry.appId, entry.appName].some(value => String(value || "").toLowerCase() === app.toLowerCase()));
}
function prune(entries, options, now) {
    var seen = {};
    return entries.filter(e => e && typeof e.id === "string" && typeof e.timestamp === "number"
        && e.timestamp >= now - options.retentionDays * 86400000 && e.timestamp <= now + 60000)
        .sort((a, b) => b.timestamp - a.timestamp)
        .filter(e => { if (seen[e.id]) return false; seen[e.id] = true; return true; })
        .slice(0, options.historyLimit);
}
function filtered(entries, query, unreadOnly) {
    var terms = String(query || "").toLowerCase().trim().split(/\s+/).filter(Boolean);
    return entries.filter(e => (!unreadOnly || !e.read) && terms.every(term =>
        [e.appName, e.summary, e.body].join(" ").toLowerCase().indexOf(term) >= 0));
}
function day(timestamp) {
    var date = new Date(timestamp), today = new Date();
    var start = new Date(today.getFullYear(), today.getMonth(), today.getDate()).getTime();
    if (timestamp >= start) return "Today";
    var yesterday = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 1).getTime();
    if (timestamp >= yesterday) return "Yesterday";
    return Qt.formatDateTime(date, "ddd, d MMM");
}
