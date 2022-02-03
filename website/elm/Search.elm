port module Search exposing (..)

import Browser
import Html as H exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
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


type SearchState
    = Initial
    | Found (List SearchEntry)


type alias Model =
    { searchInput : String
    , results : SearchState
    , searchVisible : Bool
    }


type Msg
    = SetSearch String
    | ToggleBar
    | SubmitSearch
    | GetSearchResults (List SearchEntry)



--- Init


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { searchInput = ""
      , results = Initial
      , searchVisible = False
      }
    , Cmd.none
    )



--- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleBar ->
            ( { model | searchVisible = not model.searchVisible }
            , Cmd.none
            )

        SetSearch str ->
            ( { model | searchInput = str }
            , Cmd.none
            )

        SubmitSearch ->
            ( model, doSearch model.searchInput )

        GetSearchResults list ->
            ( { model | results = Found <| List.take 20 list }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    receiveSearch GetSearchResults



--- View


view : Model -> Html Msg
view model =
    div
        [ class " inline-flex px-4 items-center hover:bg-amber-600 hover:bg-opacity-10  dark:hover:bg-stone-800"
        ]
        [ a
            [ href "#"
            , class "h-full w-full inline-flex items-center"
            , onClick ToggleBar
            ]
            [ i [ class "fa fa-search" ] []
            ]
        , div
            [ class "absolute px-2 mx-2 right-0 max-w-screen-md rounded top-12 w-full border-l border-r border-b bg-white h-12 dark:bg-stone-800 dark:border-stone-700"
            , classList [ ( "hidden", not model.searchVisible ) ]
            ]
            [ H.form [ onSubmit SubmitSearch ]
                [ input
                    [ type_ "text"
                    , value model.searchInput
                    , autofocus True
                    , placeholder "Search …"
                    , class "w-full block h-8 border-0 border-b border-stone-400 mt-2 focus:ring-0 focus:border-indigo-500 dark:bg-stone-800 dark:focus:border-cyan-400"
                    , onInput SetSearch
                    ]
                    []
                ]
            , viewResults model.results
            ]
        ]


viewResults : SearchState -> Html Msg
viewResults state =
    case state of
        Initial ->
            span [ class "hidden" ] []

        Found [] ->
            div
                [ class "bg-white dark:bg-stone-800 mt-2 w-full"
                ]
                [ div [ class "flex flex-row items-center h-14 justify-center text-xl" ]
                    [ i [ class "fa fa-meh font-thin mr-2" ]
                        []
                    , text "No results."
                    ]
                ]

        Found entries ->
            div
                [ class "bg-white dark:bg-stone-800 mt-2 w-screen sm:w-full h-screen-12 md:h-fit md:max-h-96 overflow-auto shadow-lg border-l border-r border-b dark:border-stone-700"
                ]
                [ div [ class "px-2 pt-2 pb-1 flex flex-col divide-y dark:divide-stone-700 " ]
                    (List.map viewResult entries)
                ]


viewResult : SearchEntry -> Html Msg
viewResult result =
    div [ class "py-2 content" ]
        [ a
            [ class "text-lg font-semibold"
            , href result.ref
            ]
            [ text result.doc.title
            ]
        , Markdown.toHtml [ class "content" ] result.doc.body
        ]


textInput : String
textInput =
    " placeholder-gray-400 w-full dark:text-slate-200 dark:bg-slate-800 dark:border-slate-500 border-gray-400 rounded " ++ formFocusRing


formFocusRing : String
formFocusRing =
    " focus:ring focus:ring-black focus:ring-opacity-50 focus:ring-offset-0 dark:focus:ring-slate-400 "



--- Ports


port receiveSearch : (List SearchEntry -> msg) -> Sub msg


port doSearch : String -> Cmd msg
