module Comp.CustomFieldTable exposing
    ( Action(..)
    , Model
    , Msg
    , init
    , update
    , view
    )

import Api.Model.CustomField exposing (CustomField)
import Api.Model.CustomFieldList exposing (CustomFieldList)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Util.Html
import Util.Time


type alias Model =
    {}


type Msg
    = EditItem CustomField


type Action
    = NoAction
    | EditAction CustomField


init : Model
init =
    {}


update : Msg -> Model -> ( Model, Action )
update msg model =
    case msg of
        EditItem item ->
            ( model, EditAction item )


view : Model -> List CustomField -> Html Msg
view _ items =
    div []
        [ table [ class "ui very basic center aligned table" ]
            [ thead []
                [ tr []
                    [ th [ class "collapsing" ] []
                    , th [] [ text "Name/Label" ]
                    , th [] [ text "Type" ]
                    , th [] [ text "#Usage" ]
                    , th [] [ text "Created" ]
                    ]
                ]
            , tbody []
                (List.map viewItem items)
            ]
        ]


viewItem : CustomField -> Html Msg
viewItem item =
    tr []
        [ td [ class "collapsing" ]
            [ a
                [ href "#"
                , class "ui basic small blue label"
                , onClick (EditItem item)
                ]
                [ i [ class "edit icon" ] []
                , text "Edit"
                ]
            ]
        , td []
            [ text <| Maybe.withDefault item.name item.label
            ]
        , td []
            [ text item.ftype
            ]
        , td []
            [ String.fromInt item.usages
                |> text
            ]
        , td []
            [ Util.Time.formatDateShort item.created
                |> text
            ]
        ]
