module Comp.ScanMailboxList exposing
    ( Action(..)
    , Model
    , Msg
    , init
    , update
    , view
    )

import Api.Model.ScanMailboxSettings exposing (ScanMailboxSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Util.Html


type alias Model =
    {}


type Msg
    = EditSettings ScanMailboxSettings


type Action
    = NoAction
    | EditAction ScanMailboxSettings


init : Model
init =
    {}


update : Msg -> Model -> ( Model, Action )
update msg model =
    case msg of
        EditSettings settings ->
            ( model, EditAction settings )


view : Model -> List ScanMailboxSettings -> Html Msg
view _ items =
    div []
        [ table [ class "ui very basic center aligned table" ]
            [ thead []
                [ tr []
                    [ th [ class "collapsing" ] []
                    , th [ class "collapsing" ]
                        [ i [ class "check icon" ] []
                        ]
                    , th [] [ text "Schedule" ]
                    , th [] [ text "Connection" ]
                    , th [] [ text "Folders" ]
                    , th [] [ text "Received Since" ]
                    , th [] [ text "Target" ]
                    , th [] [ text "Delete" ]
                    ]
                ]
            , tbody []
                (List.map viewItem items)
            ]
        ]


viewItem : ScanMailboxSettings -> Html Msg
viewItem item =
    tr []
        [ td [ class "collapsing" ]
            [ a
                [ href "#"
                , class "ui basic small blue label"
                , onClick (EditSettings item)
                ]
                [ i [ class "edit icon" ] []
                , text "Edit"
                ]
            ]
        , td [ class "collapsing" ]
            [ Util.Html.checkbox item.enabled
            ]
        , td []
            [ code []
                [ text item.schedule
                ]
            ]
        , td []
            [ text item.imapConnection
            ]
        , td []
            [ String.join ", " item.folders |> text
            ]
        , td []
            [ Maybe.map String.fromInt item.receivedSinceHours
                |> Maybe.withDefault "-"
                |> text
            , text " h"
            ]
        , td []
            [ Maybe.withDefault "-" item.targetFolder
                |> text
            ]
        , td []
            [ Util.Html.checkbox item.deleteMail
            ]
        ]
