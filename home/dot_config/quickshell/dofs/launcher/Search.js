// Pure helpers.
function normalize(text) {
    return String(text || "").toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
}

function score(text, query) {
    text = normalize(text);
    query = normalize(query);
    if (!query) return 0;
    if (text === query) return 1000;
    if (text.startsWith(query)) return 800 - text.length / 100;
    var at = text.indexOf(query);
    if (at >= 0) return 600 - at;
    var position = -1;
    var points = 0;
    for (var i = 0; i < query.length; ++i) {
        var next = text.indexOf(query[i], position + 1);
        if (next < 0) return -1;
        points += next === position + 1 ? 8 : 1;
        if (next === 0 || /[\s._-]/.test(text[next - 1])) points += 12;
        position = next;
    }
    return 100 + points - text.length / 100;
}

function search(entries, query) {
    var terms = normalize(query).trim().split(/\s+/).filter(Boolean);
    return entries.map(function(entry) {
        var total = 0;
        for (var i = 0; i < terms.length; ++i) {
            var nameScore = score(entry.name, terms[i]);
            var extraScore = score(entry.searchText || entry.description, terms[i]);
            var best = Math.max(nameScore, extraScore < 0 ? -1 : extraScore * 0.45);
            if (best < 0) return {entry: entry, score: -1};
            total += best;
        }
        return {entry: entry, score: total};
    }).filter(function(item) { return item.score >= 0; })
      .sort(function(a, b) { return b.score - a.score || a.entry.name.localeCompare(b.entry.name); })
      .map(function(item) { return item.entry; });
}

function withRecents(entries, ids) {
    var recent = [];
    ids.slice(0, 5).forEach(function(id) {
        var entry = entries.find(function(item) { return item.kind === "app" && item.app.id === id; });
        if (entry && !recent.some(function(item) { return item.app.id === id; }))
            recent.push(Object.assign({}, entry, {recent: true}));
    });
    return recent.concat(entries.filter(function(entry) {
        return !recent.some(function(item) { return entry.kind === "app" && entry.app.id === item.app.id; });
    }));
}

function parseEntries(text) {
    // Strip comments only outside strings (URLs and escaped quotes stay intact).
    var clean = text.replace(/"(?:\\.|[^"\\])*"|\/\/[^\n]*|\/\*[\s\S]*?\*\//g,
        function(token) { return token[0] === '"' ? token : " "; });
    // JSONC commonly permits trailing commas. Do not modify commas in strings.
    clean = clean.replace(/"(?:\\.|[^"\\])*"|,(?=\s*[\]}])/g,
        function(token) { return token[0] === '"' ? token : ""; });
    var entries = JSON.parse(clean);
    if (!Array.isArray(entries)) throw new Error("entries.jsonc must contain an array");
    var ids = Object.create(null);
    entries.forEach(function(entry) {
        if (!entry || typeof entry.id !== "string" || !entry.id || ids[entry.id]
            || typeof entry.name !== "string" || !entry.name.trim()
            || ["description", "keywords", "icon"].some(function(key) {
                return entry[key] !== undefined && typeof entry[key] !== "string";
            })
            || (["command", "menu"].every(function(key) {
                return !Array.isArray(entry[key]) || !entry[key].length || !entry[key][0]
                    || !entry[key].every(function(arg) { return typeof arg === "string"; });
            }))) throw new Error("Invalid or duplicate action: " + entry.id);
        ids[entry.id] = true;
    });
    return entries;
}

// Dynamic menu providers print one JSON object per line with the same fields
// as entries.jsonc actions; an item's "menu" opens another provider (nesting).
function parseMenuLines(text) {
    var items = [];
    String(text || "").split("\n").forEach(function(line, number) {
        line = line.trim();
        if (!line) return;
        var item;
        try { item = JSON.parse(line); }
        catch (error) { throw new Error("Menu line " + (number + 1) + " is not JSON: " + error.message); }
        if (!item || typeof item.name !== "string" || !item.name.trim()) throw new Error("Menu line " + (number + 1) + " has no name");
        var hasCommand = Array.isArray(item.command) && item.command.length && item.command[0]
            && item.command.every(function(arg) { return typeof arg === "string"; });
        var hasMenu = Array.isArray(item.menu) && item.menu.length && item.menu[0]
            && item.menu.every(function(arg) { return typeof arg === "string"; });
        // A copy-only item is display info; Enter copies its value.
        if (!hasCommand && !hasMenu && typeof item.copy !== "string") {
            throw new Error("Menu item \"" + item.name + "\" needs command, menu or copy");
        }
        items.push({
            name: item.name,
            description: typeof item.description === "string" ? item.description : "",
            searchText: [item.description, item.keywords].filter(Boolean).join(" "),
            icon: typeof item.icon === "string" ? item.icon : "",
            kind: hasMenu ? "menu" : hasCommand ? "action" : "info",
            command: hasCommand ? item.command : undefined,
            menu: hasMenu ? item.menu : undefined,
            copy: typeof item.copy === "string" ? item.copy : undefined
        });
    });
    if (!items.length) throw new Error("Menu provider returned no items");
    return items;
}

function appCommand(command) {
    // Like Omarchy's terminalCommand: no file/URL was supplied to fill these.
    return command.filter(function(word) { return !/^%[a-zA-Z]$/.test(word); })
        .map(function(word) { return word.replace(/%%/g, "%"); });
}

function calculate(input) {
    // Deliberately small arithmetic grammar. Never eval user input.
    var text = input.trim().replace(/^=\s*/, "");
    if (!/^[\d\s.+\-*/()%]+$/.test(text) || !/[\d]/.test(text)
        || (!/^[=]/.test(input.trim()) && !/[+*/()%]|\d\s*-/.test(text))) return null;
    var tokens = text.match(/(?:\d+(?:\.\d*)?|\.\d+)|[^\s]/g) || [];
    var cursor = 0;
    function atom() {
        var token = tokens[cursor++];
        if (token === "+") return atom();
        if (token === "-") return -atom();
        if (token === "(") {
            var value = expression();
            if (tokens[cursor++] !== ")") throw new Error("Missing parenthesis");
            return value;
        }
        if (!token || !/^(?:\d+(?:\.\d*)?|\.\d+)$/.test(token)) throw new Error("Expected number");
        return Number(token);
    }
    function product() {
        var value = atom();
        while (["*", "/", "%"].indexOf(tokens[cursor]) >= 0) {
            var op = tokens[cursor++];
            var right = atom();
            value = op === "*" ? value * right : op === "/" ? value / right : value % right;
        }
        return value;
    }
    function expression() {
        var value = product();
        while (tokens[cursor] === "+" || tokens[cursor] === "-") {
            var op = tokens[cursor++];
            var right = product();
            value = op === "+" ? value + right : value - right;
        }
        return value;
    }
    try {
        if (tokens.length > 128) return null;
        var result = expression();
        return cursor === tokens.length && isFinite(result) ? String(Number(result.toPrecision(12))) : null;
    } catch (error) { return null; }
}

// QML ignores this guard; Node gets a plain CommonJS module for testing.
if (typeof module !== "undefined") {
    module.exports = { normalize, score, search, withRecents, parseEntries, parseMenuLines, appCommand, calculate };
}
