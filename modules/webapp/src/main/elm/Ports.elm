port module Ports exposing
    ( checkSearchQueryString
    , initClipboard
    , receiveCheckQueryResult
    , receiveUiSettings
    , removeAccount
    , requestUiSettings
    , setAccount
    , setUiTheme
    )

import Api.Model.AuthResult exposing (AuthResult)
import Data.QueryParseResult exposing (QueryParseResult)
import Data.UiSettings exposing (StoredUiSettings)
import Data.UiTheme exposing (UiTheme)


{-| Save the result of authentication to local storage.
-}
port setAccount : AuthResult -> Cmd msg


port removeAccount : () -> Cmd msg


port internalSetUiTheme : String -> Cmd msg


port checkSearchQueryString : String -> Cmd msg


port receiveCheckQueryResult : (QueryParseResult -> msg) -> Sub msg


port initClipboard : ( String, String ) -> Cmd msg


port receiveUiSettings : (StoredUiSettings -> msg) -> Sub msg


port requestUiSettings : AuthResult -> Cmd msg


setUiTheme : UiTheme -> Cmd msg
setUiTheme theme =
    internalSetUiTheme (Data.UiTheme.toString theme)
