module Comp.StringListInput exposing
    ( ItemAction(..)
    , Model
    , Msg
    , init
    , update
    , view2
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Styles as S
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



--- View2


view2 : List String -> Model -> Html Msg
view2 values model =
    let
        valueItem s =
            div [ class "flex flex-row items-center" ]
                [ a
                    [ class S.deleteLabel
                    , onClick (RemoveString s)
                    , href "#"
                    ]
                    [ i [ class "fa fa-trash" ] []
                    ]
                , span [ class "ml-2" ]
                    [ text s
                    ]
                ]
    in
    div [ class "flex flex-col" ]
        [ div [ class "relative" ]
            [ input
                [ placeholder ""
                , type_ "text"
                , onInput SetString
                , value model.currentInput
                , class ("pr-10 py-2 rounded" ++ S.textInput)
                ]
                []
            , a
                [ href "#"
                , onClick AddString
                , class S.inputLeftIconLink
                ]
                [ i [ class "fa fa-plus" ] []
                ]
            ]
        , div
            [ class "flex flex-col space-y-4 md:space-y-2 mt-2"
            , class "px-2 border-0 border-l dark:border-bluegray-600"
            ]
            (List.map valueItem values)
        ]
