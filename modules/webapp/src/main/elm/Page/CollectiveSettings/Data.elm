{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Page.CollectiveSettings.Data exposing
    ( FormState(..)
    , Model
    , Msg(..)
    , Tab(..)
    , init
    )

import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.CollectiveSettings exposing (CollectiveSettings)
import Api.Model.ItemInsights exposing (ItemInsights)
import Comp.CollectiveSettingsForm
import Comp.SourceManage
import Comp.UserManage
import Data.Flags exposing (Flags)
import Http


type alias Model =
    { currentTab : Maybe Tab
    , sourceModel : Comp.SourceManage.Model
    , userModel : Comp.UserManage.Model
    , settingsModel : Comp.CollectiveSettingsForm.Model
    , insights : ItemInsights
    , formState : FormState
    }


type FormState
    = InitialState
    | SubmitSuccessful
    | SubmitFailed String
    | SubmitError Http.Error


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( sm, sc ) =
            Comp.SourceManage.init flags

        ( cm, cc ) =
            Comp.CollectiveSettingsForm.init flags Api.Model.CollectiveSettings.empty
    in
    ( { currentTab = Just InsightsTab
      , sourceModel = sm
      , userModel = Comp.UserManage.emptyModel
      , settingsModel = cm
      , insights = Api.Model.ItemInsights.empty
      , formState = InitialState
      }
    , Cmd.batch
        [ Cmd.map SourceMsg sc
        , Cmd.map SettingsFormMsg cc
        ]
    )


type Tab
    = SourceTab
    | UserTab
    | InsightsTab
    | SettingsTab


type Msg
    = SetTab Tab
    | SourceMsg Comp.SourceManage.Msg
    | UserMsg Comp.UserManage.Msg
    | SettingsFormMsg Comp.CollectiveSettingsForm.Msg
    | Init
    | GetInsightsResp (Result Http.Error ItemInsights)
    | CollectiveSettingsResp (Result Http.Error CollectiveSettings)
    | SubmitResp (Result Http.Error BasicResult)
