{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.CollectiveSettings.Update exposing (update)

import Api
import Comp.CollectiveSettingsForm
import Comp.SourceManage
import Comp.UserManage
import Data.Flags exposing (Flags)
import Page.CollectiveSettings.Data exposing (..)


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        SetTab t ->
            let
                m =
                    { model | currentTab = Just t }
            in
            case t of
                SourceTab ->
                    update flags (SourceMsg Comp.SourceManage.LoadSources) m

                UserTab ->
                    update flags (UserMsg Comp.UserManage.LoadUsers) m

                InsightsTab ->
                    update flags Init m

                SettingsTab ->
                    update flags Init m

        SourceMsg m ->
            let
                ( m2, c2 ) =
                    Comp.SourceManage.update flags m model.sourceModel
            in
            ( { model | sourceModel = m2 }, Cmd.map SourceMsg c2 )

        UserMsg m ->
            let
                ( m2, c2 ) =
                    Comp.UserManage.update flags m model.userModel
            in
            ( { model | userModel = m2 }, Cmd.map UserMsg c2 )

        SettingsFormMsg m ->
            let
                ( m2, c2, msett ) =
                    Comp.CollectiveSettingsForm.update flags m model.settingsModel

                cmd =
                    case msett of
                        Nothing ->
                            Cmd.none

                        Just sett ->
                            Api.setCollectiveSettings flags sett SubmitResp
            in
            ( { model | settingsModel = m2, formState = InitialState }
            , Cmd.batch [ cmd, Cmd.map SettingsFormMsg c2 ]
            )

        Init ->
            ( { model | formState = InitialState }
            , Cmd.batch
                [ Api.getInsights flags GetInsightsResp
                , Api.getCollectiveSettings flags CollectiveSettingsResp
                ]
            )

        GetInsightsResp (Ok data) ->
            ( { model | insights = data }, Cmd.none )

        GetInsightsResp (Err _) ->
            ( model, Cmd.none )

        CollectiveSettingsResp (Ok data) ->
            let
                ( cm, cc ) =
                    Comp.CollectiveSettingsForm.init flags data
            in
            ( { model | settingsModel = cm }
            , Cmd.map SettingsFormMsg cc
            )

        CollectiveSettingsResp (Err _) ->
            ( model, Cmd.none )

        SubmitResp (Ok res) ->
            ( { model
                | formState =
                    if res.success then
                        SubmitSuccessful

                    else
                        SubmitFailed res.message
              }
            , Cmd.none
            )

        SubmitResp (Err err) ->
            ( { model | formState = SubmitError err }, Cmd.none )
