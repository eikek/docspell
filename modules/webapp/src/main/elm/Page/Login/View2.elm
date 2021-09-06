{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Page.Login.View2 exposing (viewContent, viewSidebar)

import Api
import Api.Model.AuthResult exposing (AuthResult)
import Api.Model.VersionInfo exposing (VersionInfo)
import Comp.Basic as B
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onInput, onSubmit)
import Messages.Page.Login exposing (Texts)
import Page exposing (Page(..))
import Page.Login.Data exposing (..)
import Styles as S


viewSidebar : Bool -> Flags -> UiSettings -> Model -> Html Msg
viewSidebar _ _ _ _ =
    div
        [ id "sidebar"
        , class "hidden"
        ]
        []


viewContent : Texts -> Flags -> VersionInfo -> UiSettings -> Model -> Html Msg
viewContent texts flags versionInfo _ model =
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
                [ text texts.loginToDocspell
                ]
            , case model.authStep of
                StepOtp token ->
                    otpForm texts flags model token

                StepLogin ->
                    loginForm texts flags model
            , openIdLinks texts flags
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


openIdLinks : Texts -> Flags -> Html Msg
openIdLinks texts flags =
    let
        renderLink prov =
            a
                [ href (Api.openIdAuthLink flags prov.provider)
                , class S.link
                ]
                [ i [ class "fab fa-openid mr-1" ] []
                , text prov.name
                ]
    in
    case flags.config.openIdAuth of
        [] ->
            span [ class "hidden" ] []

        provs ->
            div [ class "mt-3" ]
                [ B.horizontalDivider
                    { label = texts.or
                    , topCss = "w-2/3 mb-4 hidden md:inline-flex w-full"
                    , labelCss = "px-4 bg-gray-200 bg-opacity-50"
                    , lineColor = "bg-gray-300 dark:bg-bluegray-600"
                    }
                , div [ class "flex flex-row space-x-4 items-center justify-center" ]
                    (List.map renderLink provs)
                ]


otpForm : Texts -> Flags -> Model -> String -> Html Msg
otpForm texts flags model token =
    Html.form
        [ action "#"
        , onSubmit (AuthOtp token)
        , autocomplete False
        ]
        [ div [ class "flex flex-col mt-6" ]
            [ label
                [ for "otp"
                , class S.inputLabel
                ]
                [ text texts.otpCode
                ]
            , div [ class "relative" ]
                [ div [ class S.inputIcon ]
                    [ i [ class "fa fa-key" ] []
                    ]
                , input
                    [ type_ "text"
                    , name "otp"
                    , autocomplete False
                    , onInput SetOtp
                    , value model.otp
                    , autofocus True
                    , class ("pl-10 pr-4 py-2 rounded-lg" ++ S.textInput)
                    , placeholder "123456"
                    ]
                    []
                ]
            , div [ class "flex flex-col my-3" ]
                [ button
                    [ type_ "submit"
                    , class S.primaryButton
                    ]
                    [ text texts.loginButton
                    ]
                ]
            , resultMessage texts model
            ]
        ]


loginForm : Texts -> Flags -> Model -> Html Msg
loginForm texts flags model =
    Html.form
        [ action "#"
        , onSubmit Authenticate
        , autocomplete False
        ]
        [ div [ class "flex flex-col mt-6" ]
            [ label
                [ for "username"
                , class S.inputLabel
                ]
                [ text texts.username
                ]
            , div [ class "relative" ]
                [ div [ class S.inputIcon ]
                    [ i [ class "fa fa-user" ] []
                    ]
                , input
                    [ type_ "text"
                    , name "username"
                    , autocomplete False
                    , onInput SetUsername
                    , value model.username
                    , autofocus True
                    , class ("pl-10 pr-4 py-2 rounded-lg" ++ S.textInput)
                    , placeholder texts.collectiveSlashLogin
                    ]
                    []
                ]
            ]
        , div [ class "flex flex-col my-3" ]
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
                    , onInput SetPassword
                    , value model.password
                    , class ("pl-10 pr-4 py-2 rounded-lg" ++ S.textInput)
                    , placeholder texts.password
                    ]
                    []
                ]
            ]
        , div [ class "flex flex-col my-3" ]
            [ label
                [ class "inline-flex items-center"
                , for "rememberme"
                ]
                [ input
                    [ id "rememberme"
                    , type_ "checkbox"
                    , onCheck (\_ -> ToggleRememberMe)
                    , checked model.rememberMe
                    , name "rememberme"
                    , class S.checkboxInput
                    ]
                    []
                , span
                    [ class "mb-1 ml-2 text-xs sm:text-sm tracking-wide my-1"
                    ]
                    [ text texts.rememberMe
                    ]
                ]
            ]
        , div [ class "flex flex-col my-3" ]
            [ button
                [ type_ "submit"
                , class S.primaryButton
                ]
                [ text texts.loginButton
                ]
            ]
        , resultMessage texts model
        , div
            [ class "flex justify-end text-sm pt-4"
            , classList [ ( "hidden", flags.config.signupMode == "closed" ) ]
            ]
            [ span []
                [ text texts.noAccount
                ]
            , a
                [ Page.href RegisterPage
                , class ("ml-2" ++ S.link)
                ]
                [ i [ class "fa fa-user-plus mr-1" ] []
                , text texts.signupLink
                ]
            ]
        ]


resultMessage : Texts -> Model -> Html Msg
resultMessage texts model =
    case model.formState of
        AuthSuccess _ ->
            div [ class ("my-2" ++ S.successMessage) ]
                [ text texts.loginSuccessful
                ]

        AuthFailed r ->
            div [ class ("my-2" ++ S.errorMessage) ]
                [ text r.message
                ]

        HttpError err ->
            div [ class ("my-2" ++ S.errorMessage) ]
                [ text (texts.httpError err)
                ]

        FormInitial ->
            span [ class "hidden" ] []
