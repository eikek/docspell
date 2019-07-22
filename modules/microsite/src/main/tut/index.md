---
layout: home
position: 1
section: home
title: Home
technologies:
 - first: ["Scala + Elm", "Backend is in Scala with Cats/Fs2, Webapp in Elm"]
 - second: ["Unpaper + Tesseract", "Text is extracted using OCR provided by tesseract"]
 - third: ["Stanford NLP", "Documents are analyzed using Stanford NLP classifiers"]
---

# A Document Organizer

Docspell is a simple tool to cope with your piles of (digitized) paper
documents. You'll need a scanner to convert your papers into PDF
files. Docspell can then assist in organizing the resulting PDF files
easily. Its main goal is to efficiently support two major use cases:

1. **Stowing documents away**: Most of the time documents are received
   or created. It should be *fast* to stow them away, knowing that
   they can be found if necessary.

   Upload the PDF files to docspell. Docspell finds meta data and will
   link them to your document, automatically. There may be false
   positives, so a short review is recommended. Though even if not,
   the results are not that bad.
2. **Finding them**: If there is a document needed, you can search for
   it. Usually, restricting to a date range and a correspondent will
   result in only a few documents to sift through. Alternatively, you
   can add your own tags, names etc to better match your workflow.

The meta data that docspell uses is provided by you. You need to
maintain a list of correspondents and maybe other things you want
docspell to draw suggestions from. So if a new document arrives (from
an unknown correspondent) then you would add a new entry to your meta
data and link it manually to the document. But the next time, docspell
will do it for you.

Docspell is *not* a document management system. There exists a lot of
these systems that have much more features. Docspell's focus is around
the two use cases described above, which already is quite useful.

Checkout the quick [demo](demo.html) to get a first impression and the
[quickstart](getit.html) page if you want to try it out.

## License

This project is distributed under the
[GPLv3](http://www.gnu.org/licenses/gpl-3.0.html)
