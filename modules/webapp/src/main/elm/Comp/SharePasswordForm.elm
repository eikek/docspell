{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.SharePasswordForm exposing (Model, Msg, init, update, view)

import Api
import Api.Model.ShareVerifyResult exposing (ShareVerifyResult)
import Api.Model.VersionInfo exposing (VersionInfo)
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onSubmit)
import Http
import Messages.Comp.SharePasswordForm exposing (Texts)
import Styles as S


type CompError
    = CompErrorNone
    | CompErrorPasswordFailed
    | CompErrorHttp Http.Error


type alias Model =
    { password : String
    , compError : CompError
    }


init : Model
init =
    { password = ""
    , compError = CompErrorNone
    }


type Msg
    = SetPassword String
    | SubmitPassword
    | VerifyResp (Result Http.Error ShareVerifyResult)



--- update


update : String -> Flags -> Msg -> Model -> ( Model, Cmd Msg, Maybe ShareVerifyResult )
update shareId flags msg model =
    case msg of
        SetPassword pw ->
            ( { model | password = pw }, Cmd.none, Nothing )

        SubmitPassword ->
            let
                secret =
                    { shareId = shareId
                    , password = Just model.password
                    }
            in
            ( model, Api.verifyShare flags secret VerifyResp, Nothing )

        VerifyResp (Ok res) ->
            if res.success then
                ( { model | password = "", compError = CompErrorNone }, Cmd.none, Just res )

            else
                ( { model | password = "", compError = CompErrorPasswordFailed }, Cmd.none, Nothing )

        VerifyResp (Err err) ->
            ( { model | password = "", compError = CompErrorHttp err }, Cmd.none, Nothing )



--- view


view : Texts -> Flags -> VersionInfo -> Model -> Html Msg
view texts flags versionInfo model =
    div [ class "flex flex-col items-center" ]
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
                            , value model.password
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
                , case model.compError of
                    CompErrorNone ->
                        span [ class "hidden" ] []

                    CompErrorHttp err ->
                        div [ class S.errorMessage ]
                            [ text (texts.httpError err)
                            ]

                    CompErrorPasswordFailed ->
                        div [ class S.errorMessage ]
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
