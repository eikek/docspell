module Data.Flags exposing (..)

import Api.Model.AuthResult exposing (AuthResult)

type alias Config =
    { appName: String
    , baseUrl: String
    }

type alias Flags =
    { account: Maybe AuthResult
    , config: Config
    }

getToken: Flags -> Maybe String
getToken flags =
    flags.account
        |> Maybe.andThen (\a -> a.token)

withAccount: Flags -> AuthResult -> Flags
withAccount flags acc =
    { flags | account = Just acc }
