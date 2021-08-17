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

elmApp.ports.requestUiSettings.subscribe(function(args) {
    console.log("Requesting ui settings");
    var account = args;
    var collective = account ? account.collective : null;
    var user = account ? account.user : null;
    if (collective && user) {
        var key = collective + "/" + user + "/uiSettings";
        var settings = localStorage.getItem(key);
        try {
            var data = settings ? JSON.parse(settings) : null;
            if (data) {
                console.log("Sending browser ui settings");
                elmApp.ports.receiveUiSettings.send(data);
            }
        } catch (error) {
            console.log(error);
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

elmApp.ports.printElement.subscribe(function(id) {
    if (id) {
        var el = document.getElementById(id);
        var head = document.getElementsByTagName('head');
        if (head && head.length > 0) {
            head = head[0];
        }
        if (el) {
            var w = window.open();
            w.document.write('<html>');
            if (head) {
                w.document.write('<head>');
                ['title', 'meta'].forEach(function(el) {
                    var headEls = head.getElementsByTagName(el);
                    for (var i=0; i<headEls.length; i++) {
                        w.document.write(headEls.item(i).outerHTML);
                    }
                });
                w.document.write('</head>');
            }
            w.document.write('<body>');
            w.document.write(el.outerHTML);
            w.document.write('<script type="application/javascript">window.print(); window.close();</script>');
            w.document.write('</body></html>');
        }
    }
});
