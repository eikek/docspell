+++
title = "Android Client"
description = "A simple Android App to upload files from your devices."
weight = 20
+++

# Android Client

There is a simple Android App available to conveniently upload files
from your android devices. Combined with a scanner app, this allows to
very quickly scan single page documents like receipts.

<div class="grid grid-cols-2 gap-8 divide-x ">
    <div class="flex items-center justify-center">
        <a href="https://f-droid.org/packages/org.docspell.docspellshare">
            <img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png"
                 alt="Get it on F-Droid"
                 class="w-56"
                 />
        </a>
    </div>
    <div class="flex items-center justify-center text-xl">
        <i class="fa fa-download mr-2"></i>
        <span>
           <a href="https://github.com/docspell/android-client/releases/latest">Download the APK</a>
        </span>
    </div>

</div>


The project lives at this [repository on
github](https://github.com/docspell/android-client).


# Usage

The app is very simple:

- You maintain a list of upload URLs. These can be inserted
  conveniently by scanning the QR code. You need to create these
  upload urls at docspell as described
  [here](@/docs/webapp/uploading.md#anonymous-upload).
- Start this app on your device and add a new URL
- Then start some other app, and try to share a file. The *Share with*
  or *Open with* dialog should contain now the docspell app. Choose
  it.
- You can now either select an URL from the app, or the upload begins
  immediatly if you set a default URL.

<div class="grid grid-cols-3 gap-4 mx-6 my-4">
  <div class="shadow dark:shadow-stone-600">
  {{ imgnormal(file="screenshot-create.jpg", width="") }}
  <p class="text-center font-mono"> (A) </p>
  </div>
  <div class="box-shadow">
  {{ imgnormal(file="screenshot-choose.jpg", width="") }}
  <p class="text-center font-mono"> (B) </p>
  </div>
  <div class="box-shadow">
  {{ imgnormal(file="screenshot-options.jpg", width="") }}
  <p class="text-center font-mono"> (C) </p>
  </div>
  <div class="box-shadow">
  {{ imgnormal(file="screenshot-default.jpg", width="") }}
  <p class="text-center font-mono"> (D) </p>
  </div>
  <div class="box-shadow">
  {{ imgnormal(file="screenshot-share.jpg", width="") }}
  <p class="text-center font-mono"> (E) </p>
  </div>
  <div class="box-shadow">
  {{ imgnormal(file="screenshot-uploading.jpg", width="") }}
  <p class="text-center font-mono"> (F) </p>
  </div>
</div>

## Create an URL

Add a new one With the *Plus* button. The name (A-1) is to distinguish
it in the list. The url (A-2) is used to upload files. You can add
multiple URLs. You can give permissions to access the camera and use
(A-3) to scan a QR code from the screen.

## Edit and Default

Tapping an item in the list switches the view that shows some options.
You can set one URL as the default (C-1). When uploading a file, the
screen to choose an URL is skipped then and the file is uploaded
immediately.

Other actions are editing the url (C-2), going back (C-3) or deleting the
item (4).

The screen (D) shows a default URL with a green background.

## Upload

Use some other app, for example OpenNoteScanner, and share the
resulting files using the *Share With* menu (E). Then this app opens
and uploads the file to your server (F).
