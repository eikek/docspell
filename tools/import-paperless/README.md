# Paperless to Docspell Importer
_by totti4ever_

:warning: **BE AWARE**  You should test this script on an empty database (backup yours) or at least an own collective :warning:

## Information
After using [Paperless](https://github.com/the-paperless-project/paperless/) for quite a while, I figured out that there is some room for improvement but only little work still done on the project, which is totally fine as it is a private and open-source project!
So I came around Docspell and found it to have quite a potential, especially regarding the AI and AI-like features growing.

Still I wanted to transfer the tagging and structure from Paperless to Docspell and not only import the files and start over the managing process once again.
This is why I put in my dirty bash scripting skills and made a script, which reads the files from the internal documents folder of Paperless and extracts tags and correspondents from Paperless and imports them to Docspell using the official API, so no dirty DB writes or something like that!

## Usage

1. Clone the project or simply copy the `import-paperless.sh` script to the machine, where Paperless is installed
2. run import-paperless.sh with the following parameters
    1. URL of Docspell, including http(s)
    2. Username for Docspell, possibly including Collective (if other name as user)
    3. Password for Docspell
    4. Path to Paperless' database file (`db.sqlite3`). When using Paperless with docker, it is in the mapped directory `/usr/src/paperless/data`
    5. Path to Paperless' document base directory. When using Paperless with docker, it is the mapped directory `/usr/src/paperless/media/documents/origin/`
3. You can use the following variables inside the script (right at the top)
    * LIMIT="LIMIT 0" (default: inactive)  
      For testing purposes, limits the number of tags and correspondents read from Paperless (this will most likely lead to warnings when processing the documents)
    * LIMIT_DOC="LIMIT 5" (default: inactive)  
      For testing purposes, limits the number of documents and document-to-tag relations read from Paperless
    * SKIP_EXISTING_DOCS=true (default: true)  
      Won't touch already existing documents. If set to `false` documents, which exist already, won't be uploaded again, but the tags, correspondent, date and title from Paperless will be applied.  
      :warning: In case you already had set these information in Docspell, they will be overwritten!
      
I found it quite useful, to start with 5 documents and no tags and then continue with óut a tag limit, but with 20-50 documents. Afterwards I removed both limits.  
