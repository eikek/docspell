{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Page.NewInvite.View2 exposing (viewContent, viewSidebar)

import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Markdown
import Messages.Page.NewInvite exposing (Texts)
import Page.NewInvite.Data exposing (..)
import Styles as S


viewSidebar : Bool -> Flags -> UiSettings -> Model -> Html Msg
viewSidebar _ _ _ _ =
    div
        [ id "sidebar"
        , class "hidden"
        ]
        []


viewContent : Texts -> Flags -> UiSettings -> Model -> Html Msg
viewContent texts flags _ model =
    div
        [ id "content"
        , class "flex flex-col md:w-3/5 px-2"
        , class S.content
        ]
        [ h1 [ class S.header1 ] [ text texts.createNewInvitations ]
        , inviteMessage texts flags
        , div [ class " py-2 mt-6 rounded" ]
            [ Html.form
                [ action "#"
                , onSubmit GenerateInvite
                , autocomplete False
                ]
                [ div [ class "flex flex-col" ]
                    [ label
                        [ for "invitekey"
                        , class "mb-1 text-xs sm:text-sm tracking-wide "
                        ]
                        [ text texts.password
                        ]
                    , div [ class "relative" ]
                        [ div
                            [ class "inline-flex items-center justify-center"
                            , class "absolute left-0 top-0 h-full w-10"
                            , class "text-gray-400 dark:text-bluegray-400"
                            ]
                            [ i [ class "fa fa-key" ] []
                            ]
                        , input
                            [ id "email"
                            , type_ "password"
                            , name "invitekey"
                            , autocomplete False
                            , onInput SetPassword
                            , value model.password
                            , autofocus True
                            , class ("pl-10 pr-4 py-2 rounded-lg" ++ S.textInput)
                            , placeholder texts.password
                            ]
                            []
                        ]
                    ]
                , div [ class "flex flex-col my-3" ]
                    [ div [ class "flex flex-row space-x-2" ]
                        [ button
                            [ type_ "submit"
                            , class (S.primaryButton ++ "inline-flex")
                            ]
                            [ text texts.basics.submit
                            ]
                        , a
                            [ class S.secondaryButton
                            , href "#"
                            , onClick Reset
                            ]
                            [ text texts.reset
                            ]
                        ]
                    ]
                , resultMessage texts model
                ]
            ]
        ]


resultMessage : Texts -> Model -> Html Msg
resultMessage texts model =
    div
        [ classList
            [ ( S.errorMessage, isFailed model.result )
            , ( S.successMessage, isSuccess model.result )
            , ( "hidden", model.result == Empty )
            ]
        ]
        [ case model.result of
            Failed err ->
                text (texts.httpError err)

            GenericFail m ->
                text m

            Success r ->
                div [ class "" ]
                    [ p []
                        [ text texts.newInvitationCreated
                        , text (" " ++ texts.invitationKey ++ ":")
                        ]
                    , pre [ class "text-center font-mono mt-4" ]
                        [ Maybe.withDefault "" r.key |> text
                        ]
                    ]

            Empty ->
                span [ class "hidden" ] []
        ]


inviteMessage : Texts -> Flags -> Html Msg
inviteMessage texts flags =
    div
        [ class S.message
        , class "markdown-preview"
        , classList
            [ ( "hidden", flags.config.signupMode /= "invite" )
            ]
        ]
        [ Markdown.toHtml [] texts.inviteInfo
        ]
