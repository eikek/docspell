{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Page.Register.Update exposing (update)

import Api
import Data.Flags exposing (Flags)
import Page exposing (Page(..))
import Page.Register.Data exposing (..)


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        RegisterSubmit ->
            case model.formState of
                InputValid ->
                    let
                        reg =
                            { collectiveName = model.collId
                            , login = model.login
                            , password = model.pass1
                            , invite = model.invite
                            }
                    in
                    ( model, Api.register flags reg SubmitResp )

                _ ->
                    ( model, Cmd.none )

        SetCollId str ->
            let
                m =
                    { model | collId = str }

                err =
                    validateForm m
            in
            ( { m | formState = err }, Cmd.none )

        SetLogin str ->
            let
                m =
                    { model | login = str }

                err =
                    validateForm m
            in
            ( { m | formState = err }, Cmd.none )

        SetPass1 str ->
            let
                m =
                    { model | pass1 = str }

                err =
                    validateForm m
            in
            ( { m | formState = err }, Cmd.none )

        SetPass2 str ->
            let
                m =
                    { model | pass2 = str }

                err =
                    validateForm m
            in
            ( { m | formState = err }, Cmd.none )

        SetInvite str ->
            ( { model
                | invite =
                    if str == "" then
                        Nothing

                    else
                        Just str
              }
            , Cmd.none
            )

        ToggleShowPass1 ->
            ( { model | showPass1 = not model.showPass1 }, Cmd.none )

        ToggleShowPass2 ->
            ( { model | showPass2 = not model.showPass2 }, Cmd.none )

        SubmitResp (Ok r) ->
            let
                m =
                    emptyModel

                cmd =
                    if r.success then
                        Page.goto (LoginPage ( Nothing, False ))

                    else
                        Cmd.none
            in
            ( { m
                | formState =
                    if r.success then
                        RegistrationSuccessful

                    else
                        GenericError r.message
              }
            , cmd
            )

        SubmitResp (Err err) ->
            ( { model | formState = HttpError err }, Cmd.none )


validateForm : Model -> FormState
validateForm model =
    if
        model.collId
            == ""
            || model.login
            == ""
            || model.pass1
            == ""
            || model.pass2
            == ""
    then
        FormEmpty

    else if model.pass1 /= model.pass2 then
        PasswordMismatch

    else
        InputValid
