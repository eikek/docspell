port module Ports exposing
    ( getUiSettings
    , initClipboard
    , loadUiSettings
    , onUiSettingsSaved
    , removeAccount
    , setAccount
    , setUiTheme
    , storeUiSettings
    )

import Api.Model.AuthResult exposing (AuthResult)
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (StoredUiSettings, UiSettings)
import Data.UiTheme exposing (UiTheme)


{-| Save the result of authentication to local storage.
-}
port setAccount : AuthResult -> Cmd msg


port removeAccount : () -> Cmd msg


port saveUiSettings : ( AuthResult, StoredUiSettings ) -> Cmd msg


port receiveUiSettings : (StoredUiSettings -> msg) -> Sub msg


port requestUiSettings : ( AuthResult, StoredUiSettings ) -> Cmd msg


port uiSettingsSaved : (() -> msg) -> Sub msg


port internalSetUiTheme : String -> Cmd msg


setUiTheme : UiTheme -> Cmd msg
setUiTheme theme =
    internalSetUiTheme (Data.UiTheme.toString theme)


onUiSettingsSaved : msg -> Sub msg
onUiSettingsSaved m =
    uiSettingsSaved (\_ -> m)


storeUiSettings : Flags -> UiSettings -> Cmd msg
storeUiSettings flags settings =
    case flags.account of
        Just ar ->
            saveUiSettings
                ( ar
                , Data.UiSettings.toStoredUiSettings settings
                )

        Nothing ->
            Cmd.none


loadUiSettings : (UiSettings -> msg) -> Sub msg
loadUiSettings tagger =
    receiveUiSettings (Data.UiSettings.mergeDefaults >> tagger)


getUiSettings : Flags -> Cmd msg
getUiSettings flags =
    case flags.account of
        Just ar ->
            requestUiSettings
                ( ar
                , Data.UiSettings.toStoredUiSettings Data.UiSettings.defaults
                )

        Nothing ->
            Cmd.none


port initClipboard : ( String, String ) -> Cmd msg
