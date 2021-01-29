#!/usr/bin/env bash

set -euo pipefail

wdir=$(readlink -e "$(dirname "$0")/..")

version=$(cat "$wdir/version.sbt" | cut -d'=' -f2 | sed 's,[" ],,g')
targetbase="$wdir/modules/webapp/target/scala-2.13/classes/META-INF/resources/webjars/docspell-webapp/$version"
resourcebase="$wdir/modules/webapp/target/scala-2.13/resource_managed/main/META-INF/resources/webjars/docspell-webapp/$version"



compile_js() {
    echo "Compile elm to js …"
    local srcs="$wdir/modules/webapp/src/main/elm/Main.elm"
    elm make --debug --output "$targetbase/docspell-app.js" "$srcs"
    cat "$targetbase/docspell-app.js" | gzip > "$targetbase/docspell-app.js.gz"
    cp "$targetbase/docspell-app.js" "$resourcebase/"
    cp "$targetbase/docspell-app.js.gz" "$resourcebase/"
}

compile_css() {
    echo "Building css …"
    local srcs="$wdir/modules/webapp/src/main/styles/index.css"
    local target="$targetbase/css/styles.css"
    cd $wdir && npx postcss "$srcs" -o "$target" --env development && cd -
    cat "$target" | gzip > "$targetbase/css/styles.css.gz"
    cp "$targetbase/css/styles.css" "$resourcebase/css/"
    cp "$targetbase/css/styles.css.gz" "$resourcebase/css/"
}


watch_both() {
    echo "Watching css and elm sources. C-c to quit."
    inotifywait -r --format '%w%f' \
                -e close_write -m \
                "$wdir/modules/webapp/src/main/elm" \
                "$wdir/modules/webapp/src/main/styles/" |
        while read pathfile; do
            if [[ "$pathfile" == *".elm" ]]; then
                compile_js
                echo "Done."
            elif [[ "$pathfile" == *".css" ]]; then
                compile_css
                echo "Done."
            fi
        done

}

case "$1" in
    all)
        compile_js
        compile_css
        echo "Done."
        ;;

    js)
        compile_js
        echo "Done."
        ;;

    css)
        compile_css
        echo "Done."
        ;;

    watch)
        set +e
        compile_js
        compile_css
        watch_both
        ;;

    *)
        echo "Need one of: all, js, css, watch"
        exit 1
esac
