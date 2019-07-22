module Page.NewInvite.Data exposing (..)

import Http
import Api.Model.InviteResult exposing (InviteResult)

type alias Model =
    { password: String
    , result: State
    }

type State
    = Empty
    | Failed String
    | Success InviteResult


isFailed: State -> Bool
isFailed state =
    case state of
        Failed _ -> True
        _ -> False

isSuccess: State -> Bool
isSuccess state =
    case state of
        Success _ -> True
        _ -> False

emptyModel: Model
emptyModel =
    { password = ""
    , result = Empty
    }

type Msg
    = SetPassword String
    | GenerateInvite
    | Reset
    | InviteResp (Result Http.Error InviteResult)
