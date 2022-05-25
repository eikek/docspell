{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


port module Ports exposing
    ( checkSearchQueryString
    , initClipboard
    , printElement
    , receiveCheckQueryResult
    , receiveServerEvent
    , refreshFileView
    , removeAccount
    , setAccount
    , setUiTheme
    )

import Api.Model.AuthResult exposing (AuthResult)
import Data.QueryParseResult exposing (QueryParseResult)
import Data.ServerEvent exposing (ServerEvent)
import Data.UiTheme exposing (UiTheme)
import Json.Decode as D


{-| Save the result of authentication to local storage.
-}
port setAccount : AuthResult -> Cmd msg


port removeAccount : () -> Cmd msg


port internalSetUiTheme : String -> Cmd msg


port checkSearchQueryString : String -> Cmd msg


port receiveCheckQueryResult : (QueryParseResult -> msg) -> Sub msg


port initClipboard : ( String, String ) -> Cmd msg


{-| Creates a new window/tab, writes the contents of the given element
and calls the print dialog.
-}
port printElement : String -> Cmd msg


{-| Receives messages from the websocket.
-}
port receiveWsMessage : (D.Value -> msg) -> Sub msg


{-| Given an ID of an element that is either EMBED or IFRAME the js will reload its src
-}
port refreshFileView : String -> Cmd msg



--- Higher level functions based on ports


setUiTheme : UiTheme -> Cmd msg
setUiTheme theme =
    internalSetUiTheme (Data.UiTheme.toString theme)


receiveServerEvent : (Result String ServerEvent -> msg) -> Sub msg
receiveServerEvent tagger =
    receiveWsMessage (Data.ServerEvent.decode >> tagger)
