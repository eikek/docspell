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

elmApp.ports.internalSetUiTheme.subscribe(function(themeName) {
    var body = document.getElementsByTagName("body");
    if (body && body.length > 0) {
        var bodyClasses = body[0].classList;
        // seems that body attributes cannot be set from inside Elm.
        if (themeName && themeName.toLowerCase() === 'dark') {
            bodyClasses.add("bg-bluegray-800");
            bodyClasses.add("dark");
        } else {
            bodyClasses.remove("bg-bluegray-800");
            bodyClasses.remove("dark");
        }
    }
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

elmApp.ports.checkSearchQueryString.subscribe(function(args) {
    var qStr = args;
    if (qStr && DsItemQueryParser && DsItemQueryParser['parseToFailure']) {
        var result = DsItemQueryParser.parseToFailure(qStr);
        var answer;
        if (result) {
            answer =
                { success: false,
                  input: result.input,
                  index: result.failedAt,
                  messages: result.messages
                };

        } else {
            answer =
                { success: true,
                  input: qStr,
                  index: 0,
                  messages: []
                };
        }
        console.log("Sending: " + answer.success);
        elmApp.ports.receiveCheckQueryResult.send(answer);
    }
});
