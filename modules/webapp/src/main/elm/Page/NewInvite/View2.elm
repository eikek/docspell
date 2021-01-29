module Page.NewInvite.View2 exposing (viewContent, viewSidebar)

import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Page.NewInvite.Data exposing (..)
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
        , class "flex flex-col md:w-3/5 px-2"
        , class S.content
        ]
        [ h1 [ class S.header1 ] [ text "Create new invitations" ]
        , inviteMessage flags
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
                        [ text "Invitation key"
                        ]
                    , div [ class "relative" ]
                        [ div [ class "inline-flex items-center justify-center absolute left-0 top-0 h-full w-10 text-gray-400 dark:text-bluegray-400  " ]
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
                            , placeholder "Password"
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
                            [ text "Submit"
                            ]
                        , a
                            [ class S.secondaryButton
                            , href "#"
                            , onClick Reset
                            ]
                            [ text "Reset"
                            ]
                        ]
                    ]
                , resultMessage model
                ]
            ]
        ]


resultMessage : Model -> Html Msg
resultMessage model =
    div
        [ classList
            [ ( S.errorMessage, isFailed model.result )
            , ( S.successMessage, isSuccess model.result )
            , ( "hidden", model.result == Empty )
            ]
        ]
        [ case model.result of
            Failed m ->
                p [] [ text m ]

            Success r ->
                div [ class "" ]
                    [ p []
                        [ text r.message
                        , text " Invitation Key:"
                        ]
                    , pre [ class "text-center font-mono mt-4" ]
                        [ Maybe.withDefault "" r.key |> text
                        ]
                    ]

            Empty ->
                span [ class "hidden" ] []
        ]


inviteMessage : Flags -> Html Msg
inviteMessage flags =
    div
        [ class (S.message ++ "text-sm")
        , classList
            [ ( "hidden", flags.config.signupMode /= "invite" )
            ]
        ]
        [ p []
            [ text
                """Docspell requires an invite when signing up. You can
             create these invites here and send them to friends so
             they can signup with docspell."""
            ]
        , p []
            [ text
                """Each invite can only be used once. You'll need to
             create one key for each person you want to invite."""
            ]
        , p []
            [ text
                """Creating an invite requires providing the password
             from the configuration."""
            ]
        ]
