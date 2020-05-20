module Comp.StringListInput exposing
    ( ItemAction(..)
    , Model
    , Msg
    , init
    , update
    , view
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Util.Maybe


type alias Model =
    { currentInput : String
    }


type Msg
    = AddString
    | RemoveString String
    | SetString String


init : Model
init =
    { currentInput = ""
    }



--- Update


type ItemAction
    = AddAction String
    | RemoveAction String
    | NoAction


update : Msg -> Model -> ( Model, ItemAction )
update msg model =
    case msg of
        SetString str ->
            ( { model | currentInput = str }
            , NoAction
            )

        AddString ->
            ( { model | currentInput = "" }
            , Util.Maybe.fromString model.currentInput
                |> Maybe.map AddAction
                |> Maybe.withDefault NoAction
            )

        RemoveString s ->
            ( model, RemoveAction s )



--- View


view : List String -> Model -> Html Msg
view values model =
    let
        valueItem s =
            div [ class "item" ]
                [ a
                    [ class "ui icon link"
                    , onClick (RemoveString s)
                    , href "#"
                    ]
                    [ i [ class "delete icon" ] []
                    ]
                , text s
                ]
    in
    div [ class "string-list-input" ]
        [ div [ class "ui list" ]
            (List.map valueItem values)
        , div [ class "ui icon input" ]
            [ input
                [ placeholder ""
                , type_ "text"
                , onInput SetString
                , value model.currentInput
                ]
                []
            , i
                [ class "circular add link icon"
                , onClick AddString
                ]
                []
            ]
        ]
