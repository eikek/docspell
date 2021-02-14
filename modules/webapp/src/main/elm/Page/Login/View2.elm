module Page.Login.View2 exposing (viewContent, viewSidebar)

import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onInput, onSubmit)
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


viewContent : Flags -> UiSettings -> Model -> Html Msg
viewContent flags _ model =
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
                [ text "Login to Docspell"
                ]
            , Html.form
                [ action "#"
                , onSubmit Authenticate
                , autocomplete False
                ]
                [ div [ class "flex flex-col mt-6" ]
                    [ label
                        [ for "username"
                        , class S.inputLabel
                        ]
                        [ text "Username"
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
                            , placeholder "Collective / Login"
                            ]
                            []
                        ]
                    ]
                , div [ class "flex flex-col my-3" ]
                    [ label
                        [ for "password"
                        , class S.inputLabel
                        ]
                        [ text "Password"
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
                            , placeholder "Password"
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
                            [ text "Remember Me"
                            ]
                        ]
                    ]
                , div [ class "flex flex-col my-3" ]
                    [ button
                        [ type_ "submit"
                        , class S.primaryButton
                        ]
                        [ text "Login"
                        ]
                    ]
                , resultMessage model
                , div
                    [ class "flex justify-end text-sm pt-4"
                    , classList [ ( "hidden", flags.config.signupMode == "closed" ) ]
                    ]
                    [ span []
                        [ text "No account?"
                        ]
                    , a
                        [ Page.href RegisterPage
                        , class ("ml-2" ++ S.link)
                        ]
                        [ i [ class "fa fa-user-plus mr-1" ] []
                        , text "Sign up"
                        ]
                    ]
                ]
            ]
        ]


resultMessage : Model -> Html Msg
resultMessage model =
    case model.result of
        Just r ->
            if r.success then
                div [ class ("my-2" ++ S.successMessage) ]
                    [ text "Login successful."
                    ]

            else
                div [ class ("my-2" ++ S.errorMessage) ]
                    [ text r.message
                    ]

        Nothing ->
            span [ class "hidden" ] []
