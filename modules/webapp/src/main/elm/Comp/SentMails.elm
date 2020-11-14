module Comp.SentMails exposing
    ( Model
    , Msg
    , init
    , initMails
    , isEmpty
    , update
    , view
    )

import Api.Model.SentMail exposing (SentMail)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Util.Time


type alias Model =
    { mails : List SentMail
    , selected : Maybe SentMail
    }


init : Model
init =
    { mails = []
    , selected = Nothing
    }


initMails : List SentMail -> Model
initMails mails =
    { init | mails = mails }


isEmpty : Model -> Bool
isEmpty model =
    List.isEmpty model.mails


type Msg
    = Show SentMail
    | Hide


update : Msg -> Model -> Model
update msg model =
    case msg of
        Hide ->
            { model | selected = Nothing }

        Show m ->
            { model | selected = Just m }


view : Model -> Html Msg
view model =
    case model.selected of
        Just mail ->
            div [ class "ui blue basic segment" ]
                [ div [ class "ui list" ]
                    [ div [ class "item" ]
                        [ text "From"
                        , div [ class "header" ]
                            [ text mail.sender
                            , text " ("
                            , text mail.connection
                            , text ")"
                            ]
                        ]
                    , div [ class "item" ]
                        [ text "Date"
                        , div [ class "header" ]
                            [ Util.Time.formatDateTime mail.created |> text
                            ]
                        ]
                    , div [ class "item" ]
                        [ text "Recipients"
                        , div [ class "header" ]
                            [ String.join ", " mail.recipients |> text
                            ]
                        ]
                    , div [ class "item" ]
                        [ text "Subject"
                        , div [ class "header" ]
                            [ text mail.subject
                            ]
                        ]
                    ]
                , div [ class "ui horizontal divider" ] []
                , div [ class "mail-body" ]
                    [ text mail.body
                    ]
                , a
                    [ class "ui right corner label"
                    , onClick Hide
                    , href "#"
                    ]
                    [ i [ class "close icon" ] []
                    ]
                ]

        Nothing ->
            table [ class "ui selectable pointer very basic table" ]
                [ thead []
                    [ tr []
                        [ th [ class "collapsing" ] [ text "Recipients" ]
                        , th [] [ text "Subject" ]
                        , th [ class "collapsible" ] [ text "Sent" ]
                        , th [ class "collapsible" ] [ text "Sender" ]
                        ]
                    ]
                , tbody [] <|
                    List.map
                        renderLine
                        model.mails
                ]


renderLine : SentMail -> Html Msg
renderLine mail =
    tr [ onClick (Show mail) ]
        [ td [ class "collapsing" ]
            [ String.join ", " mail.recipients |> text
            ]
        , td [] [ text mail.subject ]
        , td [ class "collapsing" ]
            [ Util.Time.formatDateTime mail.created |> text
            ]
        , td [ class "collapsing" ] [ text mail.sender ]
        ]
