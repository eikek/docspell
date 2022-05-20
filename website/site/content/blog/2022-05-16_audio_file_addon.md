+++
title = "Addon for audio file support"
[extra]
author = "eikek"
+++

# 1st Addon: Audio file support

Since version 0.36.0 Docspell can be extended by
[addons](@/docs/addons/basics.md) - external programs that are
executed at some defined point in Docspell. This is a walk through the
first addon that was created, mainly as an example: providing support
for audio files.

<!-- more -->

I think it is interesting to provide support for audio files for a
DMS, although admittedly I don't have much of a use :). But this is
the kind of use-case that addons are for.

# The idea

The idea is very simple: the real work is done by external programs,
most notably [coqui's stt](https://github.com/coqui-ai/STT) a deep
learning toolkit originally created at Mozilla. It provides a command
line tool that accepts a WAV file and spits out text. Perfect!

With this text, a PDF file can be created and a preview image which is
already enough for basic support. You can see the pdf in the web-ui
and search for the text via SOLR or PostgreSQL.

Because a WAV file is not the most popular format today, `ffmpeg` can
be used to transform any other audio to WAV.

The only thing now is to create a program that checks the uploaded
files, filters out all audio files and runs them through the mentioned
programs. So let's do this.

# Preparation

Addons are external programs and can be written in whatever language….
For me this is a good opportunity to refresh my rusty scheme know-how
a bit. So this addon is written in Scheme, in particular
[guile](https://www.gnu.org/software/guile/). Programming in scheme is
fun and guile provides good integration into the (posix) OS and also
has a nice JSON module. I had the [reference
docs](https://www.gnu.org/software/guile/docs/docs-2.2/guile-ref/index.html)
open all the time - look at them for further details on the used
functions.

It's usually good to play around with the tools at first. For stt, we
first need to download a *model*. This will be used to "detect" the
text in the audio data. They have a [page](https://coqui.ai/models)
where we can download model files for any supported language. For the
addon, we will implement English and German.

When creating a PDF with wkhtmltopdf, we prettify it a little by
embedding the plain text into some html template. This will also take
care to specifiy UTF-8 as default encoding directly in the HTML
template.

FFMpeg just works as usual. It figures out the input format
automatically and knows from the extension of the output file what to
do.

You can find the full code
[here](https://github.com/docspell/audio-files-addon/blob/master/src/addon.scm).
The following shows excerpts from it with some explanation.

# The script

## Helpers

After the preamble, there are two helper functions.

```lisp
(define* (errln formatstr . args)
  (apply format (current-error-port) formatstr args)
  (newline))

;; Macro for executing system commands and making this program exit in
;; case of failure.
(define-syntax sysexec
  (syntax-rules ()
    ((sysexec exp ...)
     (let ((rc (apply system* (list exp ...))))
       (unless (eqv? rc EXIT_SUCCESS)
         (format (current-error-port) "> '~a …' failed with: ~#*~:*~d~%" exp ... rc)
         (exit 1))
       #t))))
```

As this addon wants to pass data back to Docspell via stdout, we use
the stderr for logging and printing general information. The function
`errln` (short for "error line" :)) allows to conveniently print to
stderr and the second wraps the `system*` procedure such that the
script fails whenever the external program fails. It is somewhat
similar to `set -e` in bash.

## Dependencies

Next is the declaration of external dependencies. At first all
external programs are listed. This is important for later, when the
script is packaged via nix. Nix will substitute these commands with
absolute paths. Then it's good to not have them scattered around.

It also reads in the expected environment variables (only those we
need) that are provided by Docspell. Since this addon only makes sense
to work on an item, it quits early should some env vars are missing.

```lisp
(define *curl* "curl")
(define *ffmpeg* "ffmpeg")
(define *stt* "stt")
(define *wkhtmltopdf* "wkhtmltopdf")

;; Getting some environment variables
(define *output-dir* (getenv "OUTPUT_DIR"))
(define *tmp-dir* (getenv "TMP_DIR"))
(define *cache-dir* (getenv "CACHE_DIR"))

(define *item-data-json* (getenv "ITEM_DATA_JSON"))
(define *original-files-json* (getenv "ITEM_ORIGINAL_JSON"))
(define *original-files-dir* (getenv "ITEM_ORIGINAL_DIR"))

;; fail early if not in the right context
(when (not *item-data-json*)
  (errln "No item data json file found.")
  (exit 1))
```

## Input/Output

The input and output schemas can be defined now. This uses the
[guile-json](https://github.com/aconchillo/guile-json) module. It
provides very convenient features for reading and writing json.

It is possible to define a record via `define-json-type` that
generates readers and writers to/from JSON. For example, the record
`<itemdata>` is defined to be an object with only one field `id`. The
function `json->scm` reads in json into scheme datastructures and then
the generated function `scm->itemdata` creates the record from it. For
every record, accessor functions exists. For example: `(itemdata-id
data)` would lookup the field `id` in the given itemdata record
`data`.

Here we need it to get the item-id and the list of file properties
belonging to the original uploaded files.

Another interesting definition is the `<output>` record. This captures
(a subset of) the schema of what Docspell receives from this addon as
a result. A full example of this data is
[here](@/docs/addons/writing.md#output). We don't need `commands` or
`newItems`, so this schema only cares about the `files` attribute.


```lisp
(define-json-type <itemdata>
  (id))

;; The array of original files
(define-json-type <original-file>
  (id)
  (name)
  (position)
  (language)
  (mimetype)
  (length)
  (checksum))

;; The output record, what is returned to docspell
(define-json-type <itemfiles>
  (itemId)
  (textFiles)
  (pdfFiles))
(define-json-type <output>
  (files "files" #(<itemfiles>)))

;; Parses the JSON containing the item information
(define *itemdata-json*
  (scm->itemdata (call-with-input-file *item-data-json* json->scm)))

;; The JSON file containing meta data for all source files as vector.
(define *original-meta-json*
  (let ((props (vector->list (call-with-input-file *original-files-json* json->scm))))
    (map scm->original-file props)))
```


## Finding the audio file

The previously parsed json array `*original-meta-json*` can now be
used to find any audio files within the original uploaded files, as
done in `find-audio-files`. It simply goes through the list and keeps
those files whose mimetype starts with `audio/`. The mimetype is
provided by Docspell in the file properties in `ITEM_ORIGINAL_JSON`.

Before converting to wav with ffmpeg, it is quickly checked if it's
not a wav already.


```lisp
(define (is-wav? mime)
  "Test whether the mimetype MIME is denoting a wav file."
  (or (string-suffix? "/wav" mime)
      (string-suffix? "/x-wav" mime)
      (string-suffix? "/vnd.wav" mime)))

(define (find-audio-files)
  "Find all source files that are audio files."
  (filter! (lambda (el)
             (string-prefix?
              "audio/"
              (original-file-mimetype el)))
           *original-meta-json*))

(define (convert-wav id mime)
  "Run ffmpeg to convert to wav."
  (let ((src-file (format #f "~a/~a" *original-files-dir* id))
        (out-file (format #f "~a/in.wav" *tmp-dir*)))
    (if (is-wav? mime)
        src-file
        (begin
          (errln "Running ffmpeg to convert wav file...")
          (sysexec *ffmpeg* "-loglevel" "error" "-y" "-i" src-file out-file)
          out-file))))
```

## Speech to text

Once we have a wav file, we can run speech-to-text recognition on it.
As said above, we need to download a model first, which is depending
on a language. Luckily, Docspell provides the language of the file.
This is the lanugage either given directly by the user when uploading
or it's the collective's default language.

In the following snippet, we get the language as arguments. We will
get it later from the file properties.

As seen below, the model file is stored to the `CACHE_DIR`. This is
provided by Docspell and will survive the execution of this script.
All other directories involved will be deleted eventually. The
`CACHE_DIR` is the place to store intermediate results you don't want
to loose between addon runs. But as any cache, it may not exist the
next time the addon is run. Docspell doesn't clear it automatically,
though.

The last function simply executes the `stt` external command and puts
stdout into a file.

```lisp
(define (get-model language)
  (let* ((lang (or language "eng"))
         (file (format #f "~a/model_~a.pbmm" *cache-dir* lang)))
    (unless (file-exists? file)
      (download-model lang file))
    file))

(define (download-model lang file)
  "Download model files per language. Nix has currently stt 0.9.3 packaged."
  (let ((url (cond
              ((string= lang "eng") "https://coqui.gateway.scarf.sh/english/coqui/v0.9.3/model.pbmm")
              ((string= lang "deu") "https://coqui.gateway.scarf.sh/german/AASHISHAG/v0.9.0/model.pbmm")
              (else (error "Unsupported language: " lang)))))
    (errln "Downloading model file for language: ~a" lang)
    (sysexec *curl* "-SsL" "-o" file url)
    file))

(define (extract-text model input out)
  "Runs stt for speech-to-text and writes the text into the file OUT."
  (errln "Extracting text from audio…")
  (with-output-to-file out
    (lambda ()
      (sysexec  *stt* "--model" model "--audio" input))))
```


## Create PDF

Creating the PDF is straight forward. The extracted text is embedded
into a HTML file which is then passed to `wkhtmltopdf`. Since we don't
need this file for anything else, it is stored to the `TMP_DIR`.

```lisp
(define (create-pdf txt-file out)
  (define (line str)
    (format #t "~a\n" str))
  (errln "Creating pdf file…")
  (let ((tmphtml (format #f "~a/text.html" *tmp-dir*)))
    (with-output-to-file tmphtml
      (lambda ()
        (line "<!DOCTYPE html>")
        (line "<html>")
        (line "  <head><meta charset=\"UTF-8\"></head>")
        (line "  <body style=\"padding: 2em; font-size: large;\">")
        (line " <div style=\"padding: 0.5em; font-size:normal; font-weight: bold; border: 1px solid black;\">")
        (line "  Extracted from audio using stt on ")
        (display (strftime "%c" (localtime (current-time))))
        (line " </div>")
        (line " <p>")
        (display (call-with-input-file txt-file read-string))
        (line " </p>")
        (line "</body></html>")))
    (sysexec *wkhtmltopdf* tmphtml out)))
```


## Putting it together

The main function now puts everything together. The `process-file`
function is called for every file that is returned from
`(find-audio-files)`. It will extract the necessary information (like
the language) from the json document via record accessors (e.g.
`original-file-lanugage file)`) and then calls the functions defined
above. At last it creates a `<itemfile>` record with `make-itemfiles`.

An `<itemfile>` record contains now the important information for
Docspell. It requires the item-id and a mapping from attachment-ids to
files in `OUTPUT_DIR`. For each attachment identified by its ID,
Docspell replaces the extracted text with the contents of the given
file and replaces the converted PDF file, respectively. In the code
below, two lists of such mappings are defined - the first for the text
files, the second for the converted pdf. The files must be specified
relative to `OUTPUT_DIR`.

That means `process-all` returns a list of `<itemfile>` records which
is then used to create the `<output>` record. And finally, a
`output->json` function will turn the record into proper JSON which is
send to stdout.

```lisp
(define (process-file itemid file)
  "Processing a single audio file."
  (let* ((id (original-file-id file))
         (mime (original-file-mimetype file))
         (lang (original-file-language file))
         (txt-file (format #f "~a/~a.txt" *output-dir* id))
         (pdf-file (format #f "~a/~a.pdf" *output-dir* id))
         (wav (convert-wav id mime))
         (model (get-model lang)))
    (extract-text model wav txt-file)
    (create-pdf txt-file pdf-file)
    (make-itemfiles itemid
                    `((,id . ,(format #f "~a.txt" id)))
                    `((,id . ,(format #f "~a.pdf" id))))))

(define (process-all)
  (let ((item-id (itemdata-id *itemdata-json*)))
    (map (lambda (file)
           (process-file item-id file))
         (find-audio-files))))

(define (main args)
  (let ((out (make-output (process-all))))
    (format #t "~a" (output->json out))))
```

Example output:

```json
{
  "files": [
    {
      "itemId":"qZDnyGIAJsXr",
      "textFiles": { "HPFvIDib6eA": "HPFvIDib6eA.txt" },
      "pdfFiles":  { "HPFvIDib6eA": "HPFvIDib6eA.pdf"}
    }
  ]
}
```

# Packaging

Now with that script some additional plumbing is needed to make it an
"Addon" for Docspell.

The external tools - stt, ffmpeg, curl and wkhtmltopdf are required as
well as guile to compile and interpret the script. Also the guile-json
module must be installed.

This can turn into a quite tedious task. Luckily, there is
[nix](https://nixos.org) that has an answer to this. A user who wants
to use this script only needs to install nix. This package manager
then takes care of providing the exact dependencies we need (down to
the correct version and including guile as the language and runtime).

## A flake

Everything is defined in the `flake.nix` in the source root. It looks
like this:

```nix
{
  description = "A docspell addon for basic audio file support";

  inputs = {
    utils.url = "github:numtide/flake-utils";

    # Nixpkgs / NixOS version to use.
    nixpkgs.url = "nixpkgs/nixos-21.11";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachSystem ["x86_64-linux"] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [

          ];
        };
        name = "audio-files-addon";
      in rec {
        packages.${name} = pkgs.callPackage ./nix/addon.nix {
          inherit name;
        };

        defaultPackage = packages.${name};

        apps.${name} = utils.lib.mkApp {
          inherit name;
          drv = packages.${name};
        };
        defaultApp = apps.${name};

        ## … omitted for brevity
      }
    );
}
```

First sad thing is, that only `x86_64` systems are supported. This is
due to `stt` not being available on other platforms currently (as
provided by nixpkgs).

The rest is a bit magic: A package and "defaultPackage" is defined
with a reference to `nix/addon.nix`. The important part is the line

```nix
  inputs = {
    # Nixpkgs / NixOS version to use.
    nixpkgs.url = "nixpkgs/nixos-21.11";
  };
```

It says that as input for "building" the script, we take all of
[nixpkgs](https://github.com/NixOS/nixpkgs) which is a package
collection defined for (and in) nix - including thousands of software
packages. We can pick and choose from these. No surprise, all external
tools we need are included!

A flake defines the inputs and outputs of a package. With all of
nixpkgs as inputs, we can create a definition to elevate this script
into a *package*.

## Package definition

The definition for "building" the script is in `nix/addon.nix`:

```nix
{ stdenv, bash, cacert, curl, stt, wkhtmltopdf, ffmpeg, guile, guile-json, lib, name }:

stdenv.mkDerivation {
  inherit name;
  src = lib.sources.cleanSource ../.;

  buildInputs = [ guile guile-json ];

  patchPhase = ''
    TARGET=src/addon.scm
    sed -i 's,\*curl\* "curl",\*curl\* "${curl}/bin/curl",g' $TARGET
    sed -i 's,\*ffmpeg\* "ffmpeg",\*ffmpeg\* "${ffmpeg}/bin/ffmpeg",g' $TARGET
    sed -i 's,\*stt\* "stt",\*stt\* "${stt}/bin/stt",g' $TARGET
    sed -i 's,\*wkhtmltopdf\* "wkhtmltopdf",\*wkhtmltopdf\* "${wkhtmltopdf}/bin/wkhtmltopdf",g' $TARGET
  '';

  buildPhase = ''
    guild compile -o ${name}.go src/addon.scm
  '';

  # module name must be same as <filename>.go
  installPhase = ''
    mkdir -p $out/{bin,lib}
    cp ${name}.go $out/lib/

    cat > $out/bin/${name} <<-EOF
    #!${bash}/bin/bash
    export SSL_CERT_FILE="${cacert}/etc/ssl/certs/ca-bundle.crt"
    exec -a "${name}" ${guile}/bin/guile -C ${guile-json}/share/guile/ccache -C $out/lib -e '(${name}) main' -c "" \$@
    EOF
    chmod +x $out/bin/${name}
  '';
}
```

With a bit of handwaving - this is a bash script that modifies
slightly the scheme script and runs a compile on it. We simply declare
all packages we need in the first line of `{ … }` - these are
arguments that are automatically filled by nix by searching the
corresponding package in nixpkgs.

First the `patchPhase` is executed. It will replace the variables
containing the external tools with an absolute path to the version
that we currently get from nixpkgs. With this step nix takes care that
all these packages are available *at runtime* when executing the
script. All versions are finally fixed in `flake.lock` and can be
upgraded manually.

The `buildPhase` runs the guile compiler that produces some
intermediate code that will be loaded instead of compiling the script
on-the-fly.

At last, `installPhase` creates a wrapper script that runs guile with
the correct load-path pointing to `guile-json` and to our pre-compiled
script. Additionally, trusted root certificates are exported to make
the curl commands work. This script will be created in `$out`
directory that is provided by nix.

If you now run `nix build` in the source root, it will execute all
these phases and produce a symlink pointing to the result. You can
then `cat` the resulting file if you are curious.

This way the script is completely isolated from the system it runs
on - as long as the nix package manager is available. It includes all
the external tools, as well as the underlying runtime (guile)! The
result is a tiny wrapper bash script that can be run "everywhere"
(modulo all the restrictions, like non-x86_64 platforms, of course
:)).


## Addon Descriptor

At last, a small yaml file is needed to tell Docspell a little about
the addon.

```yaml
meta:
  name: "audio-files-addon"
  version: "0.1.0"
  description: |
    This addon adds support for audio files. Audio files are processed
    by a speech-to-text engine and a pdf is generated.

    It doesn't expect any user arguments at the moment. It requires
    internet access to download model files.

triggers:
  - final-process-item
  - final-reprocess-item
  - existing-item

runner:
  nix:
    enable: true

  docker:
    enable: false

  trivial:
    enable: true
    exec: src/addon.scm

options:
  networking: true
  collectOutput: true
```

This tells Docspell via `triggers` when this addon may be run. This
one only makes sense for an item. Thus it can be hooked up to run with
every file-processing job or a user can manually trigger it on an
item.

It also tells via `runner:` that it can be build and run via nix, but
not via docker (I gave up after an hour to create a Dockerfile…). It
could also be run "as-is" but the user then needs to install all these
tools and guile manually.

# Done

That's it. You can install this addon in Docspell and create a run
configuration to let it execute when you want.
