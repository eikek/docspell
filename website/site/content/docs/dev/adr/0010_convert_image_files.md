+++
title = "Convert Image Files"
weight = 110
+++

# Context and Problem Statement

How to convert image files properly to pdf?

Since there are thousands of different image formats, there will never
be support for all. The most common containers should be supported,
though:

- jpeg (jfif, exif)
- png
- tiff (baseline, single page)

The focus is on document images, maybe from digital cameras or
scanners.

# Considered Options

* [pdfbox](https://pdfbox.apache.org/) library
* [imagemagick](https://www.imagemagick.org/) external command
* [img2pdf](https://github.com/josch/img2pdf) external command
* [tesseract](https://github.com/tesseract-ocr/tesseract) external command

There are no screenshots here, because it doesn't make sense since
they all look the same on the screen. Instead we look at the files
properties.

**Input File**

The input files are:

```
$ identify input/*
input/jfif.jpg JPEG 2480x3514 2480x3514+0+0 8-bit sRGB 240229B 0.000u 0:00.000
input/letter-en.jpg JPEG 1695x2378 1695x2378+0+0 8-bit Gray 256c 467341B 0.000u 0:00.000
input/letter-en.png PNG 1695x2378 1695x2378+0+0 8-bit Gray 256c 191571B 0.000u 0:00.000
input/letter-en.tiff TIFF 1695x2378 1695x2378+0+0 8-bit Grayscale Gray 4030880B 0.000u 0:00.000
```

Size:
- jfif.jpg 240k
- letter-en.jpg 467k
- letter-en.png 191k
- letter-en.tiff 4.0M

## pdfbox

Using a java library is preferred, if the quality is good enough.
There is an
[example](https://github.com/apache/pdfbox/blob/2cea31cc63623fd6ece149c60d5f0cc05a696ea7/examples/src/main/java/org/apache/pdfbox/examples/pdmodel/ImageToPDF.java)
for this exact use case.

This is the sample code:

``` scala
def imgtopdf(file: String): ExitCode = {
  val jpg = Paths.get(file).toAbsolutePath
  if (!Files.exists(jpg)) {
    sys.error(s"file doesn't exist: $jpg")
  }
  val pd = new PDDocument()
  val page = new PDPage(PDRectangle.A4)
  pd.addPage(page)
  val bimg = ImageIO.read(jpg.toFile)

  val img = LosslessFactory.createFromImage(pd, bimg)

  val stream = new PDPageContentStream(pd, page)
  stream.drawImage(img, 0, 0, PDRectangle.A4.getWidth, PDRectangle.A4.getHeight)
  stream.close()

  pd.save("test.pdf")
  pd.close()

  ExitCode.Success
}
```

Using pdfbox 2.0.18 and twelvemonkeys 3.5. Running time: `1384ms`

```
$ identify *.pdf
jfif.jpg.pdf PDF 595x842 595x842+0+0 16-bit sRGB 129660B 0.000u 0:00.000
letter-en.jpg.pdf PDF 595x842 595x842+0+0 16-bit sRGB 49118B 0.000u 0:00.000
letter-en.png.pdf PDF 595x842 595x842+0+0 16-bit sRGB 49118B 0.000u 0:00.000
letter-en.tiff.pdf PDF 595x842 595x842+0+0 16-bit sRGB 49118B 0.000u 0:00.000
```

Size:
- jfif.jpg 1.1M
- letter-en.jpg 142k
- letter-en.png 142k
- letter-en.tiff 142k

## img2pdf

This is a python tool that adds the image into the pdf without
reencoding.

Using version 0.3.1. Running time: `323ms`.

```
$ identify *.pdf
jfif.jpg.pdf PDF 595x842 595x842+0+0 16-bit sRGB 129708B 0.000u 0:00.000
letter-en.jpg.pdf PDF 595x842 595x842+0+0 16-bit sRGB 49864B 0.000u 0:00.000
letter-en.png.pdf PDF 595x842 595x842+0+0 16-bit sRGB 49864B 0.000u 0:00.000
letter-en.tiff.pdf PDF 595x842 595x842+0+0 16-bit sRGB 49864B 0.000u 0:00.000
```

Size:
- jfif.jpg 241k
- letter-en.jpg 468k
- letter-en.png 191k
- letter-en.tiff 192k

## ImageMagick

The well known imagemagick tool can convert images to pdfs, too.

Using version 6.9.10-71. Running time: `881ms`.

```
$ identify *.pdf
jfif.jpg.pdf PDF 595x843 595x843+0+0 16-bit sRGB 134873B 0.000u 0:00.000
letter-en.jpg.pdf PDF 1695x2378 1695x2378+0+0 16-bit sRGB 360100B 0.000u 0:00.000
letter-en.png.pdf PDF 1695x2378 1695x2378+0+0 16-bit sRGB 322418B 0.000u 0:00.000
letter-en.tiff.pdf PDF 1695x2378 1695x2378+0+0 16-bit sRGB 322418B 0.000u 0:00.000
```

Size:
- jfif.jpg 300k
- letter-en.jpg 390k
- letter-en.png 180k
- letter-en.tiff 5.1M


## Tesseract

Docspell already relies on tesseract for doing OCR. And in contrast to
all other candidates, it can create PDFs that are searchable. Of
course, this yields in much longer running time, that cannot be
compared to the times of the other options.

```
tesseract doc3.jpg out -l deu pdf
```

It can also create both outputs in one go:

```
tesseract doc3.jpg out -l deu pdf txt
```

Using tesseract 4. Running time: `6661ms`

```
$ identify *.pdf
tesseract/jfif.jpg.pdf PDF 595x843 595x843+0+0 16-bit sRGB 130535B 0.000u 0:00.000
tesseract/letter-en.jpg.pdf PDF 1743x2446 1743x2446+0+0 16-bit sRGB 328716B 0.000u 0:00.000
tesseract/letter-en.png.pdf PDF 1743x2446 1743x2446+0+0 16-bit sRGB 328716B 0.000u 0:00.000
tesseract/letter-en.tiff.pdf PDF 1743x2446 1743x2446+0+0 16-bit sRGB 328716B 0.000u 0:00.000
```

Size:
- jfif.jpg 246k
- letter-en.jpg 473k
- letter-en.png 183k
- letter-en.tiff 183k


# Decision

Tesseract.

To not use more external tools, imagemagick and img2pdf are not
chosen, even though img2pdf shows the best results and is fastest.

Pdfbox library would be the favorite, because results are good and
with the [twelvemonkeys](https://github.com/haraldk/TwelveMonkeys)
library there is support for many images. The priority is to avoid
more external commands if possible.

But since there already is a dependency to tesseract and it can create
searchable pdfs, the decision is to use tesseract for this. Then PDFs
with images can be converted to searchable PDFs with images. And text
extraction is required anyways.
