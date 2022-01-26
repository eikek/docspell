{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Login.Update exposing (update)

import Api
import Api.Model.AuthResult exposing (AuthResult)
import Data.Flags exposing (Flags)
import Page exposing (LoginData, Page(..))
import Page.Login.Data exposing (..)
import Ports


update : LoginData -> Flags -> Msg -> Model -> ( Model, Cmd Msg, Maybe AuthResult )
update loginData flags msg model =
    case msg of
        SetUsername str ->
            ( { model | username = str }, Cmd.none, Nothing )

        SetPassword str ->
            ( { model | password = str }, Cmd.none, Nothing )

        SetOtp str ->
            ( { model | otp = str }, Cmd.none, Nothing )

        ToggleRememberMe ->
            ( { model | rememberMe = not model.rememberMe }, Cmd.none, Nothing )

        Authenticate ->
            let
                userPass =
                    { account = model.username
                    , password = model.password
                    , rememberMe = Just model.rememberMe
                    }
            in
            ( model, Api.login flags userPass AuthResp, Nothing )

        AuthOtp token ->
            let
                sf =
                    { rememberMe = model.rememberMe
                    , token = token
                    , otp = model.otp
                    }
            in
            ( model, Api.twoFactor flags sf AuthResp, Nothing )

        AuthResp (Ok lr) ->
            let
                gotoRef =
                    Maybe.withDefault DashboardPage loginData.referrer |> Page.goto
            in
            if lr.success && not lr.requireSecondFactor then
                ( { model | formState = AuthSuccess lr, password = "" }
                , Cmd.batch [ setAccount lr, gotoRef ]
                , Just lr
                )

            else if lr.success && lr.requireSecondFactor then
                ( { model
                    | formState = FormInitial
                    , authStep = StepOtp <| Maybe.withDefault "" lr.token
                    , password = ""
                  }
                , Cmd.none
                , Nothing
                )

            else
                ( { model | formState = AuthFailed lr, password = "" }
                , Ports.removeAccount ()
                , Just lr
                )

        AuthResp (Err err) ->
            let
                empty =
                    Api.Model.AuthResult.empty

                session =
                    Maybe.withDefault "" loginData.session
            in
            -- A value of 2 indicates that TOTP is required
            if loginData.openid == 2 then
                ( { model | formState = FormInitial, authStep = StepOtp session, password = "" }
                , Cmd.none
                , Nothing
                )

            else
                ( { model | password = "", formState = HttpError err }
                , Ports.removeAccount ()
                , Just empty
                )


setAccount : AuthResult -> Cmd msg
setAccount result =
    if result.success then
        Ports.setAccount result

    else
        Ports.removeAccount ()
