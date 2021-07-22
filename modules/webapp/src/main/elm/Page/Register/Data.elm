{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Page.Register.Data exposing
    ( FormState(..)
    , Model
    , Msg(..)
    , emptyModel
    )

import Api.Model.BasicResult exposing (BasicResult)
import Http


type alias Model =
    { collId : String
    , login : String
    , pass1 : String
    , pass2 : String
    , showPass1 : Bool
    , showPass2 : Bool
    , formState : FormState
    , loading : Bool
    , invite : Maybe String
    }


type FormState
    = HttpError Http.Error
    | GenericError String
    | RegistrationSuccessful
    | PasswordMismatch
    | InputValid
    | FormEmpty


emptyModel : Model
emptyModel =
    { collId = ""
    , login = ""
    , pass1 = ""
    , pass2 = ""
    , showPass1 = False
    , showPass2 = False
    , formState = FormEmpty
    , loading = False
    , invite = Nothing
    }


type Msg
    = SetCollId String
    | SetLogin String
    | SetPass1 String
    | SetPass2 String
    | SetInvite String
    | RegisterSubmit
    | ToggleShowPass1
    | ToggleShowPass2
    | SubmitResp (Result Http.Error BasicResult)
