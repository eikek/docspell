{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Comp.UiSettingsMigrate exposing
    ( Model
    , Msg
    , UpdateResult
    , init
    , receiveBrowserSettings
    , update
    , view
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (StoredUiSettings, UiSettings)
import Html exposing (..)
import Html.Attributes exposing (class, href, title)
import Html.Events exposing (onClick)
import Http
import Messages.Comp.HttpError
import Ports
import Styles as S


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( Initialized
    , Cmd.batch
        [ Api.getClientSettings flags GetClientSettingsResp
        , requestBrowserSettings flags
        ]
    )


type Model
    = Initialized
    | WaitingForHttp StoredUiSettings
    | WaitingForBrowser
    | MigrateActive StoredUiSettings
    | MigrateDone
    | MigrateRequestRunning
    | MigrateRequestFailed String


type Msg
    = GetClientSettingsResp (Result Http.Error UiSettings)
    | GetBrowserSettings StoredUiSettings
    | MigrateSettings StoredUiSettings
    | SaveSettingsResp UiSettings (Result Http.Error BasicResult)


receiveBrowserSettings : StoredUiSettings -> Msg
receiveBrowserSettings sett =
    GetBrowserSettings sett



--- Update


requestBrowserSettings : Flags -> Cmd Msg
requestBrowserSettings flags =
    case flags.account of
        Just acc ->
            Ports.requestUiSettings acc

        Nothing ->
            Cmd.none


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , sub : Sub Msg
    , newSettings : Maybe UiSettings
    }


update : Flags -> Msg -> Model -> UpdateResult
update flags msg model =
    let
        empty =
            { model = model
            , cmd = Cmd.none
            , sub = Sub.none
            , newSettings = Nothing
            }
    in
    case msg of
        GetClientSettingsResp (Err (Http.BadStatus 404)) ->
            case model of
                Initialized ->
                    { model = WaitingForBrowser
                    , cmd = requestBrowserSettings flags
                    , sub = Sub.none
                    , newSettings = Nothing
                    }

                WaitingForHttp sett ->
                    { empty | model = MigrateActive sett }

                _ ->
                    { empty
                        | sub = Sub.none
                        , cmd = requestBrowserSettings flags
                        , model = model
                    }

        GetBrowserSettings sett ->
            case model of
                Initialized ->
                    { empty | model = WaitingForHttp sett }

                WaitingForBrowser ->
                    { empty | model = MigrateActive sett }

                _ ->
                    empty

        GetClientSettingsResp _ ->
            { empty | model = MigrateDone }

        MigrateSettings settings ->
            let
                uiSettings =
                    Data.UiSettings.merge settings Data.UiSettings.defaults

                cmd =
                    Api.saveClientSettings flags uiSettings (SaveSettingsResp uiSettings)
            in
            { empty | model = MigrateRequestRunning, cmd = cmd }

        SaveSettingsResp settings (Ok res) ->
            if res.success then
                { empty | model = MigrateDone, newSettings = Just settings }

            else
                { empty | model = MigrateRequestFailed "Unknown error saving settings." }

        SaveSettingsResp _ (Err err) ->
            { empty | model = MigrateRequestFailed <| Messages.Comp.HttpError.gb err }



--- View
{-
   Note: this module will be removed later, it only exists for the
   transition from storing ui settings at the server. Therefore
   strings here are not externalized; translation is not necessary.

-}


view : Model -> Html Msg
view model =
    case model of
        MigrateActive sett ->
            div
                [ class (S.box ++ " px-2 py-2")
                , class S.infoMessage
                , class "flex flex-col"
                ]
                [ div [ class S.header2 ] [ text "Migrate your settings" ]
                , p [ class " mb-3" ]
                    [ text "The UI settings are now stored at the server. You have "
                    , text "settings stored at the browser that you can now move to the "
                    , text "server by clicking below."
                    ]
                , p [ class " mb-2" ]
                    [ text "Alternatively, change the default settings here and submit "
                    , text "this form. This message will disappear as soon as there are "
                    , text "settings at the server."
                    ]
                , div [ class "flex flex-row items-center justify-center" ]
                    [ a
                        [ href "#"
                        , title "Move current settings to the server"
                        , onClick (MigrateSettings sett)
                        , class S.primaryButton
                        ]
                        [ text "Migrate current settings"
                        ]
                    ]
                ]

        _ ->
            span [ class "hidden" ] []
