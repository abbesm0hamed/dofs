// Pure helpers: also exercised by scripts/tests/quickshell-launcher.test.cjs.
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
            || !Array.isArray(entry.command) || !entry.command.length
            || !entry.command.every(function(arg) { return typeof arg === "string"; })
            || !entry.command[0]) throw new Error("Invalid or duplicate action: " + entry.id);
        ids[entry.id] = true;
    });
    return entries;
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
