module Feature exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Markdown


type alias Feature =
    { image : String
    , header : String
    , description : String
    }


featureBox : Int -> Feature -> Html msg
featureBox index f =
    let
        titleCss =
            "text-3xl font-bold font-serif mb-3"

        boxCss =
            [ class "flex-col space-y-2"
            , class "sm:flex-row sm:space-y-0 sm-space-x-4"
            , class "flex px-8 py-8 border rounded mb-5 shadow-lg mx-2 sm:mx-8"
            ]

        descrCss =
            "flex flex-col text-xl "
    in
    if isOdd index then
        div boxCss
            [ div [ class "sm:w-1/2" ]
                [ figure [ class "block my-auto" ]
                    [ img
                        [ src f.image
                        , class "w-full"
                        , style "min-width" "4rem"
                        ]
                        []
                    ]
                ]
            , div
                [ class descrCss
                , class "pl-4 sm:w-1/2"
                ]
                [ h2 [ class titleCss ]
                    [ text f.header
                    ]
                , Markdown.toHtml []
                    f.description
                ]
            ]

    else
        div
            boxCss
            [ div
                [ class descrCss
                , class "pr-4 sm:w-1/2"
                ]
                [ h2 [ class titleCss ]
                    [ text f.header
                    ]
                , Markdown.toHtml []
                    f.description
                ]
            , div [ class "sm:w-1/2" ]
                [ figure [ class "block my-auto " ]
                    [ img
                        [ src f.image
                        , class "w-full"
                        ]
                        []
                    ]
                ]
            ]


features : List Feature
features =
    [ { image = "img/user-feature.png"
      , header = "Multi-User per Account"
      , description = """
Each account (a *collective*) can have multiple users that share the
same files. For example, everyone in your family can work with your
files while using their own account with their own settings.
"""
      }
    , { image = "img/ocr-feature.png"
      , header = "Text Extraction with OCR"
      , description = """
Text is extracted from all files. For scanned documents/images, OCR is used by utilising tesseract. The text is analysed and is available for full-text search.
"""
      }
    , { image = "img/analyze-feature.png"
      , header = "Text Analysis"
      , description = """
The extracted text is analyzed using ML algorithms to find properties that can be annotated to your documents automatically.
"""
      }
    , { image = "img/filetype-feature.svg"
      , header = "Support for many files"
      , description = """
Docspell can read many file types. ZIP and EML (e-mail file format) files are extracted and their contents imported.
"""
      }
    , { image = "img/convertpdf-feature.svg"
      , header = "Conversion to PDF"
      , description = """
All files are converted to PDF. Don't worry about the originals. Original files are stored, too and can be downloaded untouched. When creating PDFs from image data (often returned from scanners), the resulting PDF contains the extracted text and is searchable.
"""
      }
    , { image = "img/fts-feature.png"
      , header = "Full-Text Search"
      , description = """
The extracted text of all files and some properties, like names and notes, are available for full-text search. Full-text search can also be used to further constrain the results of the search-menu where you can search by tags, correspondent, etc.
"""
      }
    , { image = "img/sendmail-feature.png"
      , header = "Send via E-Mail"
      , description = """

Users can define SMTP settings in the app and are then able to send items out via E-Mail. This is often useful to share with other people. There is e-mail-address completion from your address book, of course.

"""
      }
    , { image = "img/scanmailbox-feature.png"
      , header = "Import Mailboxes"
      , description = """
Users can define IMAP settings so that docspell can import their e-mails. This can be done periodically based on a schedule. Imported mails can be moved away into another folder or deleted.
"""
      }
    , { image = "img/notify-feature.png"
      , header = "Notifications"
      , description = """
Users can be notified by e-mail, Matrix or Gotify with documents resulting from a query that is executed periodically. Notifications can also be configured for specific events.
"""
      }
    ]


isOdd : Int -> Bool
isOdd num =
    modBy 2 num == 1
