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
import Styles as S
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



--- View2


view2 : Model -> Html Msg
view2 model =
    case model.selected of
        Just mail ->
            div [ class "flex flex-col" ]
                [ div [ class "text-sm flex-flex-col" ]
                    [ div [ class "flex flex-row" ]
                        [ span [ class "font-bold" ]
                            [ text "From:"
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
                            [ text "Date:"
                            ]
                        , div [ class "ml-2" ]
                            [ Util.Time.formatDateTime mail.created |> text
                            ]
                        ]
                    , div [ class "flex flex-row" ]
                        [ span [ class "font-bold" ]
                            [ text "Recipients:"
                            ]
                        , div [ class "ml-2" ]
                            [ String.join ", " mail.recipients |> text
                            ]
                        ]
                    , div [ class "flex flex-row" ]
                        [ span [ class "font-bold" ]
                            [ text "Subject:"
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
                , div [ class "flex flex-row items-center border-t dark:border-bluegray-600 justify-end text-sm " ]
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
                        , th [ class "text-left" ] [ text "Recipients" ]
                        , th [ class "hidden" ] [ text "Subject" ]
                        , th [ class "hidden text-center xl:table-cell" ] [ text "Sent" ]
                        , th [ class "hidden" ] [ text "Sender" ]
                        ]
                    ]
                , tbody [] <|
                    List.map
                        renderLine2
                        model.mails
                ]


renderLine2 : SentMail -> Html Msg
renderLine2 mail =
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
            [ Util.Time.formatDateTime mail.created |> text
            ]
        , td [ class "hidden" ] [ text mail.sender ]
        ]
