+++
title = "Custom Mappings & CJK"
insert_anchor_links = "right"
description = "Describes Custom Configuration Options in Joex and Followup for CJK and Vertical Languages"
weight = 12
template = "docs.html"
+++

## Vertical Languages

Many of the underlying tools that Docspell uses to recognize, read, and extract text from documents have mixed support for vertical languages and other specific situations, making a default implementation difficult for language specific use cases. 

As a result, Docspell has implemented custom argument mappings for individual languages so Tessearct, OCRmyPDF, or any program can process documents with specific arguments for a given language. One of the biggests use cases for these custom mappings are vertical and CJK (Chinese, Japanese, Korean) languages.

### Custom Mappings Example (Default)

For example, lets say you need to read a PDF in Japanese but you're unsure of what a specific kanji may be. If you insert this pdf into Docspell on Tesseract and OCRmyPDF defaults, or try to use these programs on their own, you may be greeted by encoding error outputs, resulting in something like the following: 

```bash
ス¿ンÀーùßÝ�Ï項~t®ÿÝ�Ï®þĀ
イン¿ーネッø募Ö}
```

Even if you don't speak Japanese, you have probably realized that this is not very helpful for you! 

To solve this problem, we need to make use of custom argument mappings. In the default docspell Joex file, there are two existing custom mappings for Japanese (`jpn`) and Vertical Japanese (`jpn_vert`). Let's take a look at the default OCRmyPDF mapping below:

```bash
    ocrmypdf = {
      enabled = true
      command = {
        program = "ocrmypdf"
        # Custom argument mappings for this program.
        arg-mappings = {
          "ocr_lang" = {
            value = "{{lang}}"
            # Custom Language Mappings Below
            # Japanese Vertical Mapping
            mappings = [
              {
                matches = "jpn_vert"
                args = [ "-l", "jpn_vert", "--pdf-renderer", "sandwich", "--tesseract-pagesegmode", "5", "--output-type", "pdf" ]
              },
            # Japanese Mapping for OCR Optimization
              {
                matches = "jpn"
                args = [ "-l", "jpn", "--output-type", "pdf" ]
              },
            # Start Other Custom Language Mappings Here
            # Default Mapping Below
              {
                matches = ".*"
                args = [ "-l", "{{lang}}" ]
              }
            ]
          }
        }

```

OCRmyPDF is used anytime you upload a PDF document. Here we see (2) custom mappings. The mapping for `jpn_vert` includes options such as `--tesseract-pageesgmode=5`. Page segmentation mode 5 helps with reading vertical text and sets the expected page layout. The mapping for `jpn` and `jpn_vert` both have `--output-type` set to accept PDF rather than the default PDF/A. This is to help read files that may have special encoding schemes and reduce them to PDF so that they can be read with more compatibility.

The result winds up that our above document winds up outputting the following:

```bash
契約概要のご説明・注意喚起情報のご説明 
```

And now you can easily look up these words or use 3rd party translation tools to get the meaning. 

This is only one such example of the power of custom mappings, and advanced users of Tesseract, OCRmyPDF, or other tools will enjoy customizing Docspell with the defaults best for their use case.

### Converting Vertical Text to Horizontal

Currently, Vertical Japanese (JpnVert) supports converting vertical text from images directly to horizontal metadata. However, if you use a PDF or other format, OCRmyPDF will read the text as newlines, so you may wind up with an output from a vertical scan that has metadata like the following: 

```bash
や
さ
し
い
```

Obviously we want that written out nicely `やさしい`, but the file could be much longer. There are multiple ways to accomplish this, but the easiest way on small scale is to run the extracted metadata through a script. 

Here's a simple bash script to very roughly convert vertical text to horizontal text, and adds in a new line if the line is empty to get you most of the way there. Take the text extracted from docspell, copy and paste it into something like `vertical.txt` and then run the following;

```bash
#!/bin/bash

while IFS= read -r line; do
    if [ -z "$line" ]; then
        echo
    else
        echo -n "$line"
    fi
done < "$1" >> horizontal_output.txt
```

Run chmod +x `text_converter.sh` on this script to make it executable.

Then put both files in the same directory and run `./text_converter.sh vertical.txt` and it will output `horizontal_output.txt` for you so you can work with horizontal text.

### Converting Vertical Text to Horizontal (Using OCRmyPDF)

If you want to try and force `ocrmypdf` to do this directly, just run (you can replace `jpn_vert` with any vertical language in theory):

`ocrmypdf --force-ocr -l jpn_vert --sidecar horizontal_ocr_output.txt input.pdf output.converted.pdf --tesseract-pagesegmode 5 --tesseract-config cfg.file --pdf-renderer sandwich`

With the `cfg.file` content in the directory you run `ocrmypdf` being:
```
preserve_interword_spaces 1
```

Your horizontal data will then be in `horizontal_ocr_output.txt` or whatever you named it above. 

That should help anyone where ocrmypdf skips text in the docspell defaults if they desperately need the metadata out of a vertical file. Docspell may be able to directly support this `--sidecar` output in the future with additional open source contributions.
