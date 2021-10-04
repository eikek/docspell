{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Share.View exposing (viewContent, viewSidebar)

import Api.Model.VersionInfo exposing (VersionInfo)
import Comp.Basic as B
import Data.Flags exposing (Flags)
import Data.Items
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onSubmit)
import Messages.Page.Share exposing (Texts)
import Page.Share.Data exposing (..)
import Page.Share.Menubar as Menubar
import Page.Share.Results as Results
import Page.Share.Sidebar as Sidebar
import Styles as S


viewSidebar : Texts -> Bool -> Flags -> UiSettings -> Model -> Html Msg
viewSidebar texts visible flags settings model =
    div
        [ id "sidebar"
        , class S.sidebar
        , class S.sidebarBg
        , classList [ ( "hidden", not visible || model.mode /= ModeShare ) ]
        ]
        [ Sidebar.view texts flags settings model
        ]


viewContent : Texts -> Flags -> VersionInfo -> UiSettings -> Model -> Html Msg
viewContent texts flags versionInfo uiSettings model =
    case model.mode of
        ModeInitial ->
            div
                [ id "content"
                , class "h-full w-full flex flex-col text-5xl"
                , class S.content
                ]
                [ B.loadingDimmer
                    { active = model.pageError == PageErrorNone
                    , label = ""
                    }
                ]

        ModePassword ->
            passwordContent texts flags versionInfo model

        ModeShare ->
            mainContent texts flags uiSettings model



--- Helpers


mainContent : Texts -> Flags -> UiSettings -> Model -> Html Msg
mainContent texts _ settings model =
    div
        [ id "content"
        , class "h-full flex flex-col"
        , class S.content
        ]
        [ h1
            [ class S.header1
            , classList [ ( "hidden", model.verifyResult.name == Nothing ) ]
            ]
            [ text <| Maybe.withDefault "" model.verifyResult.name
            ]
        , Menubar.view texts model
        , Results.view texts settings model
        ]


passwordContent : Texts -> Flags -> VersionInfo -> Model -> Html Msg
passwordContent texts flags versionInfo model =
    div
        [ id "content"
        , class "h-full flex flex-col items-center justify-center w-full"
        , class S.content
        ]
        [ div [ class ("flex flex-col px-4 sm:px-6 md:px-8 lg:px-10 py-8 rounded-md " ++ S.box) ]
            [ div [ class "self-center" ]
                [ img
                    [ class "w-16 py-2"
                    , src (flags.config.docspellAssetPath ++ "/img/logo-96.png")
                    ]
                    []
                ]
            , div [ class "font-medium self-center text-xl sm:text-2xl" ]
                [ text texts.passwordRequired
                ]
            , Html.form
                [ action "#"
                , onSubmit SubmitPassword
                , autocomplete False
                ]
                [ div [ class "flex flex-col my-3" ]
                    [ label
                        [ for "password"
                        , class S.inputLabel
                        ]
                        [ text texts.password
                        ]
                    , div [ class "relative" ]
                        [ div [ class S.inputIcon ]
                            [ i [ class "fa fa-lock" ] []
                            ]
                        , input
                            [ type_ "password"
                            , name "password"
                            , autocomplete False
                            , autofocus True
                            , tabindex 1
                            , onInput SetPassword
                            , value model.passwordModel.password
                            , class ("pl-10 pr-4 py-2 rounded-lg" ++ S.textInput)
                            , placeholder texts.password
                            ]
                            []
                        ]
                    ]
                , div [ class "flex flex-col my-3" ]
                    [ button
                        [ type_ "submit"
                        , class S.primaryButton
                        ]
                        [ text texts.passwordSubmitButton
                        ]
                    ]
                , div
                    [ class S.errorMessage
                    , classList [ ( "hidden", not model.passwordModel.passwordFailed ) ]
                    ]
                    [ text texts.passwordFailed
                    ]
                ]
            ]
        , a
            [ class "inline-flex items-center mt-4 text-xs opacity-50 hover:opacity-90"
            , href "https://docspell.org"
            , target "_new"
            ]
            [ img
                [ src (flags.config.docspellAssetPath ++ "/img/logo-mc-96.png")
                , class "w-3 h-3 mr-1"
                ]
                []
            , span []
                [ text "Docspell "
                , text versionInfo.version
                ]
            ]
        ]
