+++
title = "Feed Data into Docspell"
weight = 5
description = "Shows several ways for getting data into Docspell."
insert_anchor_links = "right"
[extra]
mktoc = true
+++

One of the main goals is to stow documents away quickly.

Docspell makes no assumptions about where your documents are. It
offers just one HTTP endpoint that accepts files. (Well, technically
you create them in the webapp, and you can create many of them.) This
endpoint is designed to work conveniently with tools like
[curl](https://curl.haxx.se/) and it should be easy to use from other
languages, too.

So the idea is to have most flexibility – that is, it is up to you how
documents arrive. Of course, there is something prepared:


# Upload in Webapp

This is the simplest way, but also the least flexible. You can just
login and go to the upload page to submit files.


{{ figure(file="web-upload.png") }}

This requires to login at the webapp. Since this is complicated from
other applications, you can create custom hard-to-guess endpoints to
use with the following options.

# Scanners / Watch Directories

If you have a (document) scanner (or think about getting one), it can
usually be configured to place scanned documents as image or PDF files
on your NAS. On your NAS, run `dsc watch` as a service (there is a
docker container to get started) that watches this directory and
uploads all incoming files to Docspell. The [dsc
tool](@/docs/tools/cli.md) can watch directories recursively and can
skip files already uploaded, so you can organize the files as you want
in there (rename, move etc).

This can be used multiple times on different machines, if desired.

The scanner should support 300dpi for better results. Docspell
converts the files into PDF adding a text layer of image-only files.

Check out
[scanadf2docspell](https://github.com/eresturo/scanadf2docspell) if
your scanner is connected to your computer. This can create nice pdf
files from scanners with ADF, applying corrections and sending them to
docspell.

{{ buttonright(classes="is-primary ", href="/docs/tools/cli#watch-a-directory", text="More") }}


# Android

There is an [android
client](https://github.com/docspell/android-client) provided that lets
you upload files from your android devices. The idea is to use a
separate app, like
[OpenNoteScanner](https://github.com/ctodobom/OpenNoteScanner), to
"scan" documents using your phone/tablet and then upload it to
Docspell. For the upload part, you can use the provided app. It hooks
into the Share-With menu and uploads the file to Docspell.

This is especially useful to quickly upload small things like shopping
receipts.

<div class="columns is-centered">
  <div class="column is-one-third">
    <img src="/docs/tools/screenshot-share.jpg">
  </div>
  <div class="column is-one-third">
    <img src="/docs/tools/screenshot-uploading.jpg">
  </div>
</div>
<div class="columns is-vcentered is-centered">
    <div class="column is-one-third">
        <a href="https://f-droid.org/packages/org.docspell.docspellshare">
            <img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png"
                 alt="Get it on F-Droid"/>
        </a>
    </div>
    <div class="column is-one-third">
    Download the APK from <a href="https://github.com/docspell/android-client/releases/latest">here</a>
    </div>
</div>

{{ buttonright(classes="is-primary ", href="/docs/tools/android", text="More") }}


# Poll E-Mails

Your mailbox can be polled periodically to import mails. For example,
create a dedicated folder in your e-mail client and move mails in
there that you want to push to Docspell. You can then define a
recurring job, that looks into this folders and imports the mails.

{{ figure(file="scanmailbox.png") }}

{{ buttonright(classes="is-primary ", href="/docs/webapp/scanmailbox", text="More") }}


# E-Mail Server

This is a little more involved, but can be quite nice. A SMTP server
can be setup that simply uploads incoming mails to Docspell (using
curl), instead of storing the mails on disk. This requires some
knowledge to setup such a server and it makes sense to own a domain.
Or it can be used internally to connect devices like scanners that
offer a scan-to-mail option. The SMTP server would accept mails to
*[your-username]@[your-domain]* and resolves the *[your-username]*
part in Docspell to upload the files to the correct account.

There is a docker container prepared to get started. Click below to
read more.

{{ buttonright(classes="is-primary ", href="/docs/tools/smtpgateway", text="More") }}


# Command-Line

I like to use the command line, and so there is a cli that can be used
for some tasks, for example uploading files. Below is a quick demo, it
supports many more options, see the link below for details.

<div class="columns is-centered is-full-width">
  <div class="column">
    <script id="asciicast-427679" src="https://asciinema.org/a/427679.js" async></script>
  </div>
</div>


{{ buttonright(classes="is-primary ", href="/docs/tools/cli", text="More") }}


# Browser Extension

For Firefox, there is a browser extension that creates a context-menu
entry if you right-click on a link. It then downloads the file to your
disk and uploads it to Docspell.

{{ buttonright(classes="is-primary ", href="/docs/tools/browserext", text="More") }}
