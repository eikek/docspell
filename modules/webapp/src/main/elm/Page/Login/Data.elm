{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Page.Login.Data exposing
    ( AuthStep(..)
    , FormState(..)
    , Model
    , Msg(..)
    , emptyModel
    , init
    )

import Api
import Api.Model.AuthResult exposing (AuthResult)
import Data.Flags exposing (Flags)
import Http
import Page exposing (Page(..))


type alias Model =
    { username : String
    , password : String
    , otp : String
    , rememberMe : Bool
    , formState : FormState
    , authStep : AuthStep
    }


type FormState
    = AuthSuccess AuthResult
    | AuthFailed AuthResult
    | HttpError Http.Error
    | FormInitial


type AuthStep
    = StepLogin
    | StepOtp AuthResult


emptyModel : Model
emptyModel =
    { username = ""
    , password = ""
    , otp = ""
    , rememberMe = False
    , formState = FormInitial
    , authStep = StepLogin
    }


init : Flags -> Bool -> ( Model, Cmd Msg )
init flags oauth =
    let
        cmd =
            if oauth then
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
    | AuthOtp AuthResult
