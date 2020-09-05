module Data.Flags exposing
    ( Config
    , Flags
    , getToken
    , withAccount
    , withoutAccount
    )

import Api.Model.AuthResult exposing (AuthResult)


type alias Config =
    { appName : String
    , baseUrl : String
    , signupMode : String
    , docspellAssetPath : String
    , integrationEnabled : Bool
    , fullTextSearchEnabled : Bool
    , maxPageSize : Int
    , maxNoteLength : Int
    , showClassificationSettings : Bool
    }


type alias Flags =
    { account : Maybe AuthResult
    , config : Config
    }


getToken : Flags -> Maybe String
getToken flags =
    flags.account
        |> Maybe.andThen (\a -> a.token)


withAccount : Flags -> AuthResult -> Flags
withAccount flags acc =
    { flags | account = Just acc }


withoutAccount : Flags -> Flags
withoutAccount flags =
    { flags | account = Nothing }
