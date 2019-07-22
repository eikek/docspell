module Page.CollectiveSettings.Data exposing (..)

import Http
import Comp.SourceManage
import Comp.UserManage
import Comp.Settings
import Data.Language
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.CollectiveSettings exposing (CollectiveSettings)
import Api.Model.ItemInsights exposing (ItemInsights)

type alias Model =
    { currentTab: Maybe Tab
    , sourceModel: Comp.SourceManage.Model
    , userModel: Comp.UserManage.Model
    , settingsModel: Comp.Settings.Model
    , insights: ItemInsights
    , submitResult: Maybe BasicResult
    }

emptyModel: Model
emptyModel =
    { currentTab = Just InsightsTab
    , sourceModel = Comp.SourceManage.emptyModel
    , userModel = Comp.UserManage.emptyModel
    , settingsModel = Comp.Settings.init Api.Model.CollectiveSettings.empty
    , insights = Api.Model.ItemInsights.empty
    , submitResult = Nothing
    }

type Tab
    = SourceTab
    | UserTab
    | InsightsTab
    | SettingsTab

type Msg
    = SetTab Tab
    | SourceMsg Comp.SourceManage.Msg
    | UserMsg Comp.UserManage.Msg
    | SettingsMsg Comp.Settings.Msg
    | Init
    | GetInsightsResp (Result Http.Error ItemInsights)
    | CollectiveSettingsResp (Result Http.Error CollectiveSettings)
    | SubmitResp (Result Http.Error BasicResult)
