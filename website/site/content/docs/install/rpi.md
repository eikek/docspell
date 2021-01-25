+++
title = "Raspberry-Pi and Similiar"
weight = 40
+++

# Raspberry Pi, and similiar

Both component can run next to each other on a raspberry pi or
similiar device.

There is a [project on
github](https://github.com/docspell/rpi-scripts) that can help with
setting up a raspberry pi with docspell.


## REST Server

The REST server component runs very well on the Raspberry Pi and
similiar devices. It doesn't require much resources, because the heavy
work is done by the joex components.


## Joex

Running the joex component on the Raspberry Pi is possible, but will
result in long processing times for OCR and text analysis. The board
should provide 4G of RAM (like the current RPi4), especially if also a
database and solr are running next to it. The memory required by joex
depends on the config and document language. Please pick a value that
suits your setup from [here](@/docs/configure/_index.md#memory-usage).
For boards like the RPi, it might be necessary to use
`nlp.mode=basic`, rather than `nlp.mode=full`. You should also set the
joex pool size to 1.

An example: on this [UP
board](https://up-board.org/up/specifications/) with an Intel Atom
x5-Z8350 CPU (@1.44Ghz) and 4G RAM, a scanned (300dpi, in German) pdf
file with 6 pages took *3:20 min* to process. This board also runs the
SOLR and a postgresql database.

The same file was processed in 55s on a qemu virtual machine on my i7
notebook, using 1 CPU and 4G RAM (and identical config for joex). The
virtual machine only had to host docspell (joex and restserver, but
the restserver is very lightweight).

The learning task for text classification can also use high amount of
memory, but this depends on the amount of data you have in docspell.
If you encounter problems here, you can set the maximum amount of
items to consider in the collective settings page.
