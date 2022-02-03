/// Handles lights-switch link

var loadTheme = function() {
    var syntaxCss = document.getElementById('syntax-css');
    if (localStorage.theme === 'dark' ||
        (!('theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
        document.documentElement.classList.add('dark');
        if (syntaxCss) {
            syntaxCss.href = "/syntax-dark.css";
        }
    } else {
        document.documentElement.classList.remove('dark');
        if (syntaxCss) {
            syntaxCss.href = "/syntax-light.css";
        }
    }
}

var updateIcon = function(btn) {
    var icon = document.createElement('i');
    icon.classList.add('fa');
    if (localStorage.theme === 'dark') {
        icon.classList.add('fa-moon');
    }
    else if (localStorage.theme === 'light') {
        icon.classList.add('fa-sun');
        icon.classList.add('font-thin');
    }
    else {
        if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
            icon.classList.add('fa-moon');
        } else {
            icon.classList.add('fa-sun');
        }
        icon.classList.add('opacity-40');
    }
    btn.replaceChild(icon, btn.firstElementChild);            
};

var initTheme = function() {
    loadTheme();    
    const switches = document.getElementsByClassName('lights-container');
    if (switches) {
        for (var i=0; i<switches.length; i++) {
            var el = switches.item(i);
            var menuBtn = el.getElementsByClassName('lights-switch')[0];

            updateIcon(menuBtn);

            const menu = el.getElementsByClassName('lights-menu')[0];
            if (menuBtn) {
                menuBtn.onclick = function() {
                    if (menu && menu.classList.contains('hidden')) {
                        menu.classList.remove('hidden');
                    } else {
                        menu.classList.add('hidden');
                    }
                };
            }

            const toDark = el.getElementsByClassName('lights-to-dark')[0];
            if (toDark) {
                toDark.onclick = function() {
                    localStorage.theme = 'dark';
                    loadTheme();
                    menu.classList.add('hidden');
                    updateIcon(menuBtn);
                };
            }
            const toLight = el.getElementsByClassName('lights-to-light')[0];
            if (toLight) {
                toLight.onclick = function() {
                    localStorage.theme = 'light';
                    loadTheme();
                    menu.classList.add('hidden');
                    updateIcon(menuBtn);
                };
            }
            const toSystem = el.getElementsByClassName('lights-to-system')[0];
            if (toSystem) {
                toSystem.onclick = function() {
                    localStorage.removeItem('theme');
                    loadTheme();
                    menu.classList.add('hidden');
                    updateIcon(menuBtn);
                };
            }
        }
    }
}
if (document.readyState === "complete" ||
    (document.readyState !== "loading" && !document.documentElement.doScroll)
   ) {
    initTheme();
} else {
    document.addEventListener("DOMContentLoaded", initTheme);
}
