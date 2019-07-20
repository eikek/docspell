module Page.Login.Data exposing (..)

import Http
import Api.Model.AuthResult exposing (AuthResult)

type alias Model =
    { username: String
    , password: String
    , result: Maybe AuthResult
    }

empty: Model
empty =
    { username = ""
    , password = ""
    , result = Nothing
    }

type Msg
    = SetUsername String
    | SetPassword String
    | Authenticate
    | AuthResp (Result Http.Error AuthResult)
