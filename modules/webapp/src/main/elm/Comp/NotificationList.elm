module Comp.NotificationList exposing
    ( Action(..)
    , Model
    , Msg
    , init
    , update
    , view
    )

import Api.Model.NotificationSettings exposing (NotificationSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Util.Html


type alias Model =
    {}


type Msg
    = EditSettings NotificationSettings


type Action
    = NoAction
    | EditAction NotificationSettings


init : Model
init =
    {}


update : Msg -> Model -> ( Model, Action )
update msg model =
    case msg of
        EditSettings settings ->
            ( model, EditAction settings )


view : Model -> List NotificationSettings -> Html Msg
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
                    , th [] [ text "Recipients" ]
                    , th [] [ text "Remind Days" ]
                    ]
                ]
            , tbody []
                (List.map viewItem items)
            ]
        ]


viewItem : NotificationSettings -> Html Msg
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
            [ text item.smtpConnection
            ]
        , td []
            [ String.join ", " item.recipients |> text
            ]
        , td []
            [ String.fromInt item.remindDays
                |> text
            ]
        ]
