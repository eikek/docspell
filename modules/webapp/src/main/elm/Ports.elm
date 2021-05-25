port module Ports exposing
    ( checkSearchQueryString
    , initClipboard
    , receiveCheckQueryResult
    , removeAccount
    , setAccount
    , setUiTheme
    )

import Api.Model.AuthResult exposing (AuthResult)
import Data.QueryParseResult exposing (QueryParseResult)
import Data.UiTheme exposing (UiTheme)


{-| Save the result of authentication to local storage.
-}
port setAccount : AuthResult -> Cmd msg


port removeAccount : () -> Cmd msg


port internalSetUiTheme : String -> Cmd msg


port checkSearchQueryString : String -> Cmd msg


port receiveCheckQueryResult : (QueryParseResult -> msg) -> Sub msg


port initClipboard : ( String, String ) -> Cmd msg


setUiTheme : UiTheme -> Cmd msg
setUiTheme theme =
    internalSetUiTheme (Data.UiTheme.toString theme)
