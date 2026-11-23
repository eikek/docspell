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
import Process
import Task


toastDisplayMs : Float
toastDisplayMs =
    4000


toastFadeMs : Float
toastFadeMs =
    300


authSuccessDelayMs : Float
authSuccessDelayMs =
    500


scheduleToastDismiss : Int -> Cmd Msg
scheduleToastDismiss gen =
    Process.sleep toastDisplayMs
        |> Task.perform (\_ -> StartToastFadeOut gen)


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
            if model.authenticating then
                ( model, Cmd.none, Nothing )

            else
                let
                    userPass =
                        { account = model.username
                        , password = model.password
                        , rememberMe = Just model.rememberMe
                        }

                    nextGen =
                        model.toastGen + 1
                in
                ( { model
                    | authenticating = True
                    , formState = FormInitial
                    , toastState = ToastHidden
                    , toastGen = nextGen
                  }
                , Api.login flags userPass AuthResp
                , Nothing
                )

        AuthOtp token ->
            if model.authenticating then
                ( model, Cmd.none, Nothing )

            else
                let
                    sf =
                        { rememberMe = model.rememberMe
                        , token = token
                        , otp = model.otp
                        }

                    nextGen =
                        model.toastGen + 1
                in
                ( { model
                    | authenticating = True
                    , formState = FormInitial
                    , toastState = ToastHidden
                    , toastGen = nextGen
                  }
                , Api.twoFactor flags sf AuthResp
                , Nothing
                )

        AuthResp (Ok lr) ->
            let
                nextGen =
                    model.toastGen + 1
            in
            if lr.success && not lr.requireSecondFactor then
                ( { model
                    | authenticating = True
                    , formState = AuthSuccess lr
                    , password = ""
                    , otp = ""
                    , toastState = ToastVisible
                    , toastGen = nextGen
                  }
                , Cmd.batch
                    [ setAccount lr
                    , Process.sleep authSuccessDelayMs
                        |> Task.perform (\_ -> CompleteLoginRedirect)
                    ]
                , Just lr
                )

            else if lr.success && lr.requireSecondFactor then
                ( { model
                    | authenticating = False
                    , formState = FormInitial
                    , authStep = StepOtp <| Maybe.withDefault "" lr.token
                    , password = ""
                    , otp = ""
                    , toastState = ToastHidden
                    , toastGen = nextGen
                  }
                , Cmd.none
                , Nothing
                )

            else
                ( { model
                    | authenticating = False
                    , formState = AuthFailed lr
                    , password = ""
                    , otp = ""
                    , toastState = ToastVisible
                    , toastGen = nextGen
                  }
                , Cmd.batch
                    [ Ports.removeAccount ()
                    , scheduleToastDismiss nextGen
                    ]
                , Just lr
                )

        AuthResp (Err err) ->
            let
                empty =
                    Api.Model.AuthResult.empty

                session =
                    Maybe.withDefault "" loginData.session

                nextGen =
                    model.toastGen + 1
            in
            if loginData.openid == 2 then
                -- A value of 2 indicates that TOTP is required
                ( { model
                    | authenticating = False
                    , formState = FormInitial
                    , authStep = StepOtp session
                    , password = ""
                    , toastState = ToastHidden
                    , toastGen = nextGen
                  }
                , Cmd.none
                , Nothing
                )

            else if loginData.openid == 3 then
                -- A valuo of 3 indicates a logout when a single
                -- openid provider is configured with
                -- oidcAutoredirect=true that doesn't have a logout
                -- url configured
                ( { model
                    | authenticating = False
                    , password = ""
                    , formState = OidcLogoutPending
                    , toastState = ToastVisible
                    , toastGen = nextGen
                  }
                , Ports.removeAccount ()
                , Just empty
                )

            else
                ( { model
                    | authenticating = False
                    , password = ""
                    , formState = HttpError err
                    , toastState = ToastVisible
                    , toastGen = nextGen
                  }
                , Cmd.batch
                    [ Ports.removeAccount ()
                    , scheduleToastDismiss nextGen
                    ]
                , Just empty
                )

        StartToastFadeOut gen ->
            if gen == model.toastGen && model.toastState == ToastVisible then
                ( { model | toastState = ToastFadingOut }
                , Process.sleep toastFadeMs
                    |> Task.perform (\_ -> HideToast gen)
                , Nothing
                )

            else
                ( model, Cmd.none, Nothing )

        HideToast gen ->
            if gen == model.toastGen then
                ( { model | toastState = ToastHidden, formState = FormInitial }
                , Cmd.none
                , Nothing
                )

            else
                ( model, Cmd.none, Nothing )

        CompleteLoginRedirect ->
            let
                gotoRef =
                    Maybe.withDefault DashboardPage loginData.referrer |> Page.goto
            in
            ( model, gotoRef, Nothing )


setAccount : AuthResult -> Cmd msg
setAccount result =
    if result.success then
        Ports.setAccount result

    else
        Ports.removeAccount ()
