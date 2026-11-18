{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Login.Data exposing
    ( AuthStep(..)
    , FormState(..)
    , Model
    , Msg(..)
    , ToastState(..)
    , emptyModel
    , init
    )

import Api
import Api.Model.AuthResult exposing (AuthResult)
import Data.Flags exposing (Flags)
import Http
import Page exposing (LoginData, Page(..))


type alias Model =
    { username : String
    , password : String
    , otp : String
    , rememberMe : Bool
    , formState : FormState
    , authStep : AuthStep
    , authenticating : Bool
    , toastState : ToastState
    , toastGen : Int
    }


type FormState
    = AuthSuccess AuthResult
    | AuthFailed AuthResult
    | HttpError Http.Error
    | FormInitial
    | OidcLogoutPending


type ToastState
    = ToastHidden
    | ToastVisible
    | ToastFadingOut


type AuthStep
    = StepLogin
    | StepOtp String


emptyModel : Model
emptyModel =
    { username = ""
    , password = ""
    , otp = ""
    , rememberMe = False
    , formState = FormInitial
    , authStep = StepLogin
    , authenticating = False
    , toastState = ToastHidden
    , toastGen = 0
    }


init : Flags -> LoginData -> ( Model, Cmd Msg )
init flags ld =
    let
        cmd =
            if ld.openid > 0 then
                Api.loginSession flags AuthResp

            else
                Cmd.none
    in
    ( emptyModel, cmd )


type Msg
    = SetUsername String
    | SetPassword String
    | ToggleRememberMe
    | Authenticate
    | AuthResp (Result Http.Error AuthResult)
    | SetOtp String
    | AuthOtp String
    | StartToastFadeOut Int
    | HideToast Int
    | CompleteLoginRedirect
