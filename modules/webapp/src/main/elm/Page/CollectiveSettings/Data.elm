module Page.CollectiveSettings.Data exposing
    ( Model
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
    , submitResult : Maybe BasicResult
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( sm, sc ) =
            Comp.SourceManage.init flags
    in
    ( { currentTab = Just InsightsTab
      , sourceModel = sm
      , userModel = Comp.UserManage.emptyModel
      , settingsModel = Comp.CollectiveSettingsForm.init Api.Model.CollectiveSettings.empty
      , insights = Api.Model.ItemInsights.empty
      , submitResult = Nothing
      }
    , Cmd.map SourceMsg sc
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
