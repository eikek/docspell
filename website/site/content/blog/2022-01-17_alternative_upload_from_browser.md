+++
title = "Upload directly from the browser or email client"
[extra]
author = "gandy92"
+++

# Uploading from browser or email client

An alternative approach came to mind to directly upload from a browser
or email client that at least works on a Linux system. In case this is
interesting for others, I'd like to share it here.

<!-- more -->
1. Create and activate a source in your collective (in this example
   MYCOLL); note that path to the file upload (the one with
   `/api/v1/open/upload/item/`)
2. Create a file `docspell-upload-MYCOLL` with the following content (replace `UPLOAD_PATH` with the actual path):
   ```
   #!/bin/bash
   logger -t docspell_upload -- Docspell upload to MYCOLL: "$*" $(
   curl -s -XPOST -F file=@"$1" UPLOAD_PATH
   )
   ```
3. Make it executable: `chmod 755 docspell-upload-MYCOLL`
4. Create a file named `docspell-MYCOLL.desktop` with the following
   content (note that you need the full path to
   `docspell-upload-MYCOLL`):

   ```
   [Desktop Entry]
   Exec=PATH_TO_docspell-upload-MYCOLL %F
   MimeType=application/pdf;application/x-zip;application/x-zip-compressed;application/zip
   Name=Docspell Upload (MYCOLL)
   NoDisplay=true
   Type=Application
   ```
5. Place the file `docspell-MYCOLL.desktop` in
   `$HOME/.local/share/applications/`
6. Configure your browser or mail-reader actions for pdf and zip: They
   should always ask what to do rather than opening a link or
   attachment with the standard application or save it to disk by
   default. Actually, always opening a pdf in the browser is fine, if
   this allows to later save the viewed file.

Now, when clicking on a file link or attachment, the browser or email
client should ask what to do. You then should be able to choose
"Docspell Upload (MYCOLL)" from the list, which will upload the file
to your collection.

If anything goes wrong, you can monitor the server response with the
command `journalctl -f -t docspell_upload`
