module Page.Login.Data exposing
    ( FormState(..)
    , Model
    , Msg(..)
    , emptyModel
    )

import Api.Model.AuthResult exposing (AuthResult)
import Http
import Page exposing (Page(..))


type alias Model =
    { username : String
    , password : String
    , rememberMe : Bool
    , formState : FormState
    }


type FormState
    = AuthSuccess AuthResult
    | AuthFailed AuthResult
    | HttpError Http.Error
    | FormInitial


emptyModel : Model
emptyModel =
    { username = ""
    , password = ""
    , rememberMe = False
    , formState = FormInitial
    }


type Msg
    = SetUsername String
    | SetPassword String
    | ToggleRememberMe
    | Authenticate
    | AuthResp (Result Http.Error AuthResult)
