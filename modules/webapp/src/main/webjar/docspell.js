/* Docspell JS */

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

elmApp.ports.setProgress.subscribe(function(input) {
    var id = input[0];
    var percent = input[1];
    setTimeout(function () {
        $("#"+id).progress({percent: percent});
    }, 100);
});

elmApp.ports.setAllProgress.subscribe(function(input) {
    var id = input[0];
    var percent = input[1];
    setTimeout(function () {
        $("."+id).progress({percent: percent});
    }, 100);
});

elmApp.ports.scrollToElem.subscribe(function(id) {
    if (id && id != "") {
        window.setTimeout(function() {
            var el = document.getElementById(id);
            if (el) {
                if (el["scrollIntoViewIfNeeded"]) {
                    el.scrollIntoViewIfNeeded();
                } else {
                    el.scrollIntoView();
                }
            }
        }, 20);
    }
});
