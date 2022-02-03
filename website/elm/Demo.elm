module Demo exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Markdown


type alias Demo =
    { title : String
    , url : String
    , info : String
    }


demo : Demo -> Html msg
demo data =
    div [ class "px-4 py-4 mx-2 sm:mx-8 rounded border shadow-lg flex flex-col" ]
        [ h2 [ class "text-3xl font-bold py-2 font-serif" ]
            [ text data.title
            ]
        , if data.info == "" then
            span [] []

          else
            Markdown.toHtml [ class "text-lg" ] data.info
        , div [ class "mt-6 self-center" ]
            [ video
                [ src data.url
                , controls True
                ]
                []
            ]
        ]


navigateDemo =
    { title = "Navigation"
    , url = "/videos/docspell-navigate-2021-02-19.mp4"
    , info = "Shows basic navigation through documents using tags and tag categories."
    }


processDemo =
    { title = "Processing"
    , url = "/videos/docspell-process-2021-02-19-dark.mp4"
    , info = "Presents the basic idea: maintain an address book and let docspell find matches for new uploaded documents and attach them automatically."
    }
