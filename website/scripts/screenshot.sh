#!/usr/bin/env bash
#
# Little tool to help with doing screenshots.
#
# Run: ./screenshot.sh output.png
#
# Then select a window. It will create a screenshot from that window,
# cut (optionally) some pixels (removes the browser bar) and then
# resizes it to some maximum width.

set -e

# input file
file=/tmp/screenshot.png

# final output file
out=/tmp/screenshot-out.png

# image dimension ratio w:h
ratio=${RATIO:-"16:9"}
# cut that much from the top to remove browser bar (my firefox settings)
top_cut=${TOP_CUT:-85}
# maximum width of final image
maxw=${MAXW:-1200}
# time to wait in secs
waitsec=${WAIT_SEC:-3}


#### Main ############
work=/tmp/screenshot-work.png

debug() {
    (1>&2 echo "$@")
}

scrot -s -c -d $waitsec "$file" 1>&2
cp "$file" "$work"


read -r w h < <(identify -verbose $file |\
                    grep "Geometry:" | \
                    cut -d':' -f2 | \
                    cut -d'+' -f1 | \
                    tr 'x' ' ' | xargs)
debug "Original size: ${w}x${h}"

read nw nh < <(echo $ratio | tr ':' ' ')

# remove browser bar from top
((h=$h - $top_cut))

# create height to match ratio
((newH=($w * $nh) / $nw))

if [ $newH -gt $h ]; then
    debug "Cropping to $w x $h"
    debug "Cannot crop to ratio without reducing width"
    convert -crop ${w}x${h}+0+${top_cut} "$work" "$out"
else
    debug "Cropping to $w x $h"
    convert -crop ${w}x${newH}+0+${top_cut} "$work" "$out"
fi
cp "$out" "$work"

debug "Resize to max width $maxw"
convert -resize $maxw "$work" "$out"
rm -f "$work" "$file"

if [ -z "$1" ]; then
    echo "$out"
else
    mv "$out" "$1"
    echo "$1"
fi
