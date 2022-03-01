{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.CollectiveSettings.Update exposing (update)

import Api
import Comp.CollectiveSettingsForm
import Comp.ShareManage
import Comp.SourceManage
import Comp.UserManage
import Data.Environment as Env
import Data.Flags
import Messages.Page.CollectiveSettings exposing (Texts)
import Page.CollectiveSettings.Data exposing (..)


update : Texts -> Env.Update -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update texts env msg model =
    case msg of
        SetTab t ->
            let
                m =
                    { model | currentTab = Just t }
            in
            case t of
                SourceTab ->
                    update texts env (SourceMsg Comp.SourceManage.LoadSources) m

                UserTab ->
                    update texts env (UserMsg Comp.UserManage.LoadUsers) m

                InsightsTab ->
                    update texts env Init m

                SettingsTab ->
                    update texts env Init m

                ShareTab ->
                    update texts env (ShareMsg Comp.ShareManage.loadShares) m

        SourceMsg m ->
            let
                ( m2, c2 ) =
                    Comp.SourceManage.update env.flags m model.sourceModel
            in
            ( { model | sourceModel = m2 }, Cmd.map SourceMsg c2, Sub.none )

        ShareMsg lm ->
            let
                ( sm, sc, ss ) =
                    Comp.ShareManage.update texts.shareManage env.flags lm model.shareModel
            in
            ( { model | shareModel = sm }, Cmd.map ShareMsg sc, Sub.map ShareMsg ss )

        UserMsg m ->
            let
                ( m2, c2 ) =
                    Comp.UserManage.update env.flags m model.userModel
            in
            ( { model | userModel = m2 }, Cmd.map UserMsg c2, Sub.none )

        SettingsFormMsg m ->
            let
                ( m2, c2, msett ) =
                    Comp.CollectiveSettingsForm.update env.flags env.settings.timeZone m model.settingsModel

                cmd =
                    case msett of
                        Nothing ->
                            Cmd.none

                        Just sett ->
                            Api.setCollectiveSettings env.flags sett SubmitResp
            in
            ( { model | settingsModel = m2, formState = InitialState }
            , Cmd.batch [ cmd, Cmd.map SettingsFormMsg c2 ]
            , Sub.none
            )

        Init ->
            ( { model | formState = InitialState }
            , Cmd.batch
                [ Api.getInsights env.flags GetInsightsResp
                , Api.getCollectiveSettings env.flags CollectiveSettingsResp
                ]
            , Sub.none
            )

        GetInsightsResp (Ok data) ->
            ( { model | insights = data }, Cmd.none, Sub.none )

        GetInsightsResp (Err _) ->
            ( model, Cmd.none, Sub.none )

        CollectiveSettingsResp (Ok data) ->
            let
                ( cm, cc ) =
                    Comp.CollectiveSettingsForm.init env.flags data
            in
            ( { model | settingsModel = cm }
            , Cmd.map SettingsFormMsg cc
            , Sub.none
            )

        CollectiveSettingsResp (Err _) ->
            ( model, Cmd.none, Sub.none )

        SubmitResp (Ok res) ->
            ( { model
                | formState =
                    if res.success then
                        SubmitSuccessful

                    else
                        SubmitFailed res.message
              }
            , Cmd.none
            , Sub.none
            )

        SubmitResp (Err err) ->
            ( { model | formState = SubmitError err }, Cmd.none, Sub.none )
