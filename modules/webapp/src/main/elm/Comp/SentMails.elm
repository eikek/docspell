{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.SentMails exposing
    ( Model
    , Msg
    , init
    , initMails
    , isEmpty
    , update
    , view2
    )

import Api.Model.SentMail exposing (SentMail)
import Comp.Basic as B
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.Comp.SentMails exposing (Texts)
import Styles as S


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



--- View2


view2 : Texts -> Model -> Html Msg
view2 texts model =
    case model.selected of
        Just mail ->
            div [ class "flex flex-col" ]
                [ div [ class "text-sm flex-flex-col" ]
                    [ div [ class "flex flex-row" ]
                        [ span [ class "font-bold" ]
                            [ text (texts.from ++ ":")
                            ]
                        , div [ class "ml-2" ]
                            [ text mail.sender
                            , text " ("
                            , text mail.connection
                            , text ")"
                            ]
                        ]
                    , div [ class "flex flex-row" ]
                        [ span [ class "font-bold" ]
                            [ text (texts.date ++ ":")
                            ]
                        , div [ class "ml-2" ]
                            [ texts.formatDateTime mail.created |> text
                            ]
                        ]
                    , div [ class "flex flex-row" ]
                        [ span [ class "font-bold" ]
                            [ text (texts.recipients ++ ":")
                            ]
                        , div [ class "ml-2" ]
                            [ String.join ", " mail.recipients |> text
                            ]
                        ]
                    , div [ class "flex flex-row" ]
                        [ span [ class "font-bold" ]
                            [ text (texts.subject ++ ":")
                            ]
                        , div [ class "ml-2" ]
                            [ text mail.subject
                            ]
                        ]
                    ]
                , hr [ class S.border ] []
                , div [ class "py-1 whitespace-pre-wrap" ]
                    [ text mail.body
                    ]
                , div [ class "flex flex-row items-center border-t dark:border-slate-600 justify-end text-sm " ]
                    [ a
                        [ class S.secondaryBasicButton
                        , onClick Hide
                        , class "mt-1"
                        , href "#"
                        ]
                        [ i [ class "fa fa-times" ] []
                        ]
                    ]
                ]

        Nothing ->
            table [ class "border-collapse w-full" ]
                [ thead []
                    [ tr []
                        [ th [] []
                        , th [ class "text-left" ] [ text texts.recipients ]
                        , th [ class "hidden" ] [ text texts.subject ]
                        , th [ class "hidden text-center xl:table-cell" ] [ text texts.sent ]
                        , th [ class "hidden" ] [ text texts.sender ]
                        ]
                    ]
                , tbody [] <|
                    List.map
                        (renderLine2 texts)
                        model.mails
                ]


renderLine2 : Texts -> SentMail -> Html Msg
renderLine2 texts mail =
    tr [ class S.tableRow ]
        [ td []
            [ B.linkLabel
                { label = ""
                , icon = "fa fa-eye"
                , handler = Show mail
                , disabled = False
                }
            ]
        , td [ class "text-left py-4 md:py-2" ]
            [ String.join ", " mail.recipients |> text
            ]
        , td [ class "hidden" ] [ text mail.subject ]
        , td [ class "hidden text-center xl:table-cell" ]
            [ texts.formatDateTime mail.created |> text
            ]
        , td [ class "hidden" ] [ text mail.sender ]
        ]
