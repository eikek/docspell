module Page.Register.Data exposing
    ( Model
    , Msg(..)
    , emptyModel
    )

import Api.Model.BasicResult exposing (BasicResult)
import Http


type alias Model =
    { result : Maybe BasicResult
    , collId : String
    , login : String
    , pass1 : String
    , pass2 : String
    , showPass1 : Bool
    , showPass2 : Bool
    , errorMsg : List String
    , loading : Bool
    , successMsg : String
    , invite : Maybe String
    }


emptyModel : Model
emptyModel =
    { result = Nothing
    , collId = ""
    , login = ""
    , pass1 = ""
    , pass2 = ""
    , showPass1 = False
    , showPass2 = False
    , errorMsg = []
    , successMsg = ""
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
