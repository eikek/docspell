port module Search exposing (..)

import Browser exposing (Document)
import Browser.Navigation exposing (Key)
import Html as H exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Json.Decode as D
import Markdown



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



--- Model


type alias Flags =
    {}


type alias Doc =
    { body : String
    , title : String
    , id : String
    }


type alias SearchEntry =
    { ref : String
    , score : Float
    , doc : Doc
    }


type alias Model =
    { searchInput : String
    , results : List SearchEntry
    }


type Msg
    = SetSearch String
    | SubmitSearch
    | GetSearchResults (List SearchEntry)



--- Init


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { searchInput = ""
      , results = []
      }
    , Cmd.none
    )



--- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetSearch str ->
            ( { model | searchInput = str }
            , Cmd.none
            )

        SubmitSearch ->
            ( model, doSearch model.searchInput )

        GetSearchResults list ->
            ( { model | results = List.take 8 list }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    receiveSearch GetSearchResults



--- View


view : Model -> Html Msg
view model =
    H.form
        [ class "form"
        , onSubmit SubmitSearch
        ]
        [ div [ class "dropdown field is-active is-fullwidth has-addons" ]
            [ div [ class "control is-fullwidth" ]
                [ input
                    [ class "input"
                    , type_ "text"
                    , placeholder "Search docs…"
                    , onInput SetSearch
                    , value model.searchInput
                    ]
                    []
                ]
            , div [ class "control" ]
                [ button
                    [ class "button is-primary"
                    , href "#"
                    , onClick SubmitSearch
                    ]
                    [ img [ src "/icons/search-white-20.svg" ] []
                    ]
                ]
            , viewResults model.results
            ]
        ]


viewResults : List SearchEntry -> Html Msg
viewResults entries =
    div
        [ classList
            [ ( "dropdown-menu", True )
            , ( "is-hidden", entries == [] )
            ]
        ]
        [ div [ class "dropdown-content" ]
            (List.intersperse
                (div [ class "dropdown-divider" ] [])
                (List.map viewResult entries)
            )
        ]


viewResult : SearchEntry -> Html Msg
viewResult result =
    div [ class "dropdown-item" ]
        [ a
            [ class "is-size-5"
            , href result.ref
            ]
            [ text result.doc.title
            ]
        , Markdown.toHtml [ class "content" ] result.doc.body
        ]



--- Ports


port receiveSearch : (List SearchEntry -> msg) -> Sub msg


port doSearch : String -> Cmd msg
