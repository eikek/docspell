/* Docspell JS */
function forEachIn(obj, fn) {
    var index = 0;
    for (var key in obj) {
        if (obj.hasOwnProperty(key)) {
            fn(obj[key], key, index++);
        }
    }
}

function extend() {
    var result = {};
    for (var i = 0; i < arguments.length; i++) {
        forEachIn(arguments[i],
            function(obj, key) {
                result[key] = obj;
            });
    }
    return result;
}


var elmApp = Elm.Main.init({
    node: document.getElementById("docspell-app"),
    flags: elmFlags
});


elmApp.ports.setAccount.subscribe(function(authResult) {
    console.log("Add account from local storage");
    localStorage.setItem("account", JSON.stringify(authResult));
});

elmApp.ports.removeAccount.subscribe(function() {
    console.log("Remove account from local storage");
    localStorage.removeItem("account");
});


elmApp.ports.saveUiSettings.subscribe(function(args) {
    if (Array.isArray(args) && args.length == 2) {
        var authResult = args[0];
        var settings = args[1];
        if (authResult && settings) {
            var key = authResult.collective + "/" + authResult.user + "/uiSettings";
            console.log("Save ui settings to local storage");
            localStorage.setItem(key, JSON.stringify(settings));
            elmApp.ports.receiveUiSettings.send(settings);
            elmApp.ports.uiSettingsSaved.send(null);
        }
    }
});

elmApp.ports.requestUiSettings.subscribe(function(args) {
    console.log("Requesting ui settings");
    if (Array.isArray(args) && args.length == 2) {
        var account = args[0];
        var defaults = args[1];
        var collective = account ? account.collective : null;
        var user = account ? account.user : null;
        if (collective && user) {
            var key = collective + "/" + user + "/uiSettings";
            var settings = localStorage.getItem(key);
            var data = settings ? JSON.parse(settings) : null;
            if (data && defaults) {
                var defaults = extend(defaults, data);
                elmApp.ports.receiveUiSettings.send(defaults);
            } else if (defaults) {
                elmApp.ports.receiveUiSettings.send(defaults);
            }
        } else if (defaults) {
            elmApp.ports.receiveUiSettings.send(defaults);
        }
    }
});

var docspell_clipboards = {};

elmApp.ports.initClipboard.subscribe(function(args) {
    var page = args[0];
    if (!docspell_clipboards[page]) {
        var sel = args[1];
        docspell_clipboards[page] = new ClipboardJS(sel);
    }
});
