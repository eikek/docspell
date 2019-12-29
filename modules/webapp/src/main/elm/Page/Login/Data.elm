module Page.Login.Data exposing
    ( Model
    , Msg(..)
    , emptyModel
    )

import Api.Model.AuthResult exposing (AuthResult)
import Http
import Page exposing (Page(..))


type alias Model =
    { username : String
    , password : String
    , result : Maybe AuthResult
    }


emptyModel : Model
emptyModel =
    { username = ""
    , password = ""
    , result = Nothing
    }


type Msg
    = SetUsername String
    | SetPassword String
    | Authenticate
    | AuthResp (Result Http.Error AuthResult)
