module Page.Register.View2 exposing (viewContent, viewSidebar)

import Comp.Basic as B
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Page exposing (Page(..))
import Page.Register.Data exposing (..)
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
        [ div [ class ("flex flex-col px-4 sm:px-6 md:px-8 lg:px-10 lg:w-2/5 py-8 rounded-md " ++ S.box) ]
            [ div [ class "self-center" ]
                [ img
                    [ class "w-16 py-2"
                    , src (flags.config.docspellAssetPath ++ "/img/logo-96.png")
                    ]
                    []
                ]
            , div [ class "font-medium self-center text-xl sm:text-2xl" ]
                [ text "Signup to Docspell"
                ]
            , Html.form
                [ action "#"
                , onSubmit RegisterSubmit
                , autocomplete False
                ]
                [ div [ class "flex flex-col mt-6" ]
                    [ label
                        [ for "username"
                        , class S.inputLabel
                        ]
                        [ text "Collective ID"
                        , B.inputRequired
                        ]
                    , div [ class "relative" ]
                        [ div [ class S.inputIcon ]
                            [ i [ class "fa fa-users" ] []
                            ]
                        , input
                            [ type_ "text"
                            , name "collective"
                            , autocomplete False
                            , onInput SetCollId
                            , value model.collId
                            , autofocus True
                            , class ("pl-10 pr-4 py-2 rounded-lg" ++ S.textInput)
                            , placeholder "Collective"
                            ]
                            []
                        ]
                    ]
                , div [ class "flex flex-col my-3" ]
                    [ label
                        [ for "user"
                        , class S.inputLabel
                        ]
                        [ text "User Login"
                        , B.inputRequired
                        ]
                    , div [ class "relative" ]
                        [ div [ class S.inputIcon ]
                            [ i [ class "fa fa-user" ] []
                            ]
                        , input
                            [ type_ "text"
                            , name "user"
                            , autocomplete False
                            , onInput SetLogin
                            , value model.login
                            , class ("pl-10 pr-4 py-2 rounded-lg" ++ S.textInput)
                            , placeholder "Username"
                            ]
                            []
                        ]
                    ]
                , div [ class "flex flex-col my-3" ]
                    [ label
                        [ for "passw1"
                        , class S.inputLabel
                        ]
                        [ text "Password"
                        , B.inputRequired
                        ]
                    , div [ class "relative" ]
                        [ div [ class S.inputIcon ]
                            [ i
                                [ class "fa"
                                , if model.showPass1 then
                                    class "fa-lock-open"

                                  else
                                    class "fa-lock"
                                ]
                                []
                            ]
                        , input
                            [ type_ <|
                                if model.showPass1 then
                                    "text"

                                else
                                    "password"
                            , name "passw1"
                            , autocomplete False
                            , onInput SetPass1
                            , value model.pass1
                            , class ("pl-10 pr-10 py-2 rounded-lg" ++ S.textInput)
                            , placeholder "Password"
                            ]
                            []
                        , a
                            [ class S.inputLeftIconLink
                            , onClick ToggleShowPass1
                            , href "#"
                            ]
                            [ i [ class "fa fa-eye" ] []
                            ]
                        ]
                    ]
                , div [ class "flex flex-col my-3" ]
                    [ label
                        [ for "passw2"
                        , class S.inputLabel
                        ]
                        [ text "Password (repeat)"
                        , B.inputRequired
                        ]
                    , div [ class "relative" ]
                        [ div [ class S.inputIcon ]
                            [ i
                                [ class "fa"
                                , if model.showPass2 then
                                    class "fa-lock-open"

                                  else
                                    class "fa-lock"
                                ]
                                []
                            ]
                        , input
                            [ type_ <|
                                if model.showPass2 then
                                    "text"

                                else
                                    "password"
                            , name "passw2"
                            , autocomplete False
                            , onInput SetPass2
                            , value model.pass2
                            , class ("pl-10 pr-10 py-2 rounded-lg" ++ S.textInput)
                            , placeholder "Password (repeat)"
                            ]
                            []
                        , a
                            [ class S.inputLeftIconLink
                            , onClick ToggleShowPass2
                            , href "#"
                            ]
                            [ i [ class "fa fa-eye" ] []
                            ]
                        ]
                    ]
                , div
                    [ class "flex flex-col my-3"
                    , classList [ ( "hidden", flags.config.signupMode /= "invite" ) ]
                    ]
                    [ label
                        [ for "invitekey"
                        , class S.inputLabel
                        ]
                        [ text "Invitation Key"
                        , B.inputRequired
                        ]
                    , div [ class "relative" ]
                        [ div [ class S.inputIcon ]
                            [ i [ class "fa fa-key" ] []
                            ]
                        , input
                            [ type_ "text"
                            , name "invitekey"
                            , autocomplete False
                            , onInput SetInvite
                            , model.invite |> Maybe.withDefault "" |> value
                            , class ("pl-10 pr-4 py-2 rounded-lg" ++ S.textInput)
                            , placeholder "Invitation Key"
                            ]
                            []
                        ]
                    ]
                , div [ class "flex flex-col my-3" ]
                    [ button
                        [ type_ "submit"
                        , class S.primaryButton
                        ]
                        [ text "Submit"
                        ]
                    ]
                , resultMessage model
                , div
                    [ class "flex justify-end text-sm pt-4"
                    , classList [ ( "hidden", flags.config.signupMode == "closed" ) ]
                    ]
                    [ span []
                        [ text "Already signed up?"
                        ]
                    , a
                        [ Page.href (LoginPage Nothing)
                        , class ("ml-2" ++ S.link)
                        ]
                        [ i [ class "fa fa-user-plus mr-1" ] []
                        , text "Sign in"
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
                div [ class S.successMessage ]
                    [ text "Registration successful."
                    ]

            else
                div [ class S.errorMessage ]
                    [ text r.message
                    ]

        Nothing ->
            if List.isEmpty model.errorMsg then
                span [ class "hidden" ] []

            else
                div [ class S.errorMessage ]
                    (List.map (\s -> div [] [ text s ]) model.errorMsg)
