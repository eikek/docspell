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
    div [ class "columns is-vcentered box mb-5" ]
        [ div [ class "column" ]
            [ h2 [ class "title" ]
                [ text data.title
                ]
            , if data.info == "" then
                span [] []

              else
                p []
                    [ Markdown.toHtml [] data.info
                    ]
            , div [ class "mt-5" ]
                [ video
                    [ src data.url
                    , controls True
                    ]
                    []
                ]
            ]
        ]


navigateDemo =
    { title = "Navigation"
    , url = "/videos/docspell-dd-2020-08-09.mp4"
    , info = "Shows navigating through documents using tags and tag categories."
    }


processDemo =
    { title = "Processing"
    , url = "/videos/docspell-process-2020-08-09.mp4"
    , info = "Presents the basic idea: maintain an address book and let docspell find matches."
    }
