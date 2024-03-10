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
    cd $wdir/modules/webapp && tailwindcss --input "$srcs" -o "$target" --config ./tailwind.config.js --postcss ./postcss.config.js  --env development && cd -
    cat "$target" | gzip > "$targetbase/css/styles.css.gz"
    cp "$targetbase/css/styles.css" "$resourcebase/css/"
    cp "$targetbase/css/styles.css.gz" "$resourcebase/css/"
}

watch_js() {
    echo "Watching for elm sources. C-c to quit."
    inotifywait -r --format '%w%f' \
                -e close_write -m \
                "$wdir/modules/webapp/src/main/elm" |
        while read pathfile; do
            compile_js
            echo "Done."
        done
}

watch_css() {
    echo "Watching css …"
    rm -f "$targetbase/css"/*.css
    rm -f "$resourcebase/css"/*.css
    local srcs="$wdir/modules/webapp/src/main/styles/index.css"
    local target="$targetbase/css/styles.css"
    cd $wdir/modules/webapp && \
        tailwindcss --input "$srcs" \
            -o "$target" -m \
            --config ./tailwind.config.js \
            --postcss ./postcss.config.js --watch
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
                compile_css
                echo "Done."
            elif [[ "$pathfile" == *".css" ]]; then
                compile_css
                echo "Done."
            fi
        done

}

cd "$wdir/modules/webapp"
arg=${1:-_}
case "$arg" in
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

    watch-js)
        set +e
        compile_js
        watch_js
        ;;

    watch-css)
        set +e
        watch_css
        ;;

    *)
        echo "Need one of: all, js, css, watch, watch-js, watch-css"
        exit 1
esac
