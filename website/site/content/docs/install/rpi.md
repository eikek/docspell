+++
title = "Raspberry-Pi and Similiar"
weight = 40
+++

# Raspberry Pi, and similiar

Both component can run next to each other on a raspberry pi or
similiar device.


## REST Server

The REST server component runs very well on the Raspberry Pi and
similiar devices. It doesn't require much resources, because the heavy
work is done by the joex components.


## Joex

Running the joex component on the Raspberry Pi is possible, but will
result in long processing times for OCR. Files that don't require OCR
are no problem.

Tested on a RPi model 3 (4 cores, 1G RAM) processing a PDF (scanned
with 300dpi) with two pages took 9:52. You can speed it up
considerably by uninstalling the `unpaper` command, because this step
takes quite long. This, of course, reduces the quality of OCR. But
without `unpaper` the same sample pdf was then processed in 1:24, a
speedup of 8 minutes.

You should limit the joex pool size to 1 and, depending on your model
and the amount of RAM, set a heap size of at least 500M
(`-J-Xmx500M`).

For personal setups, when you don't need the processing results asap,
this can work well enough.
