module Page.UserSettings.Data exposing
    ( Model
    , Msg(..)
    , Tab(..)
    , emptyModel
    )

import Comp.ChangePasswordForm
import Comp.EmailSettingsManage


type alias Model =
    { currentTab : Maybe Tab
    , changePassModel : Comp.ChangePasswordForm.Model
    , emailSettingsModel : Comp.EmailSettingsManage.Model
    }


emptyModel : Model
emptyModel =
    { currentTab = Nothing
    , changePassModel = Comp.ChangePasswordForm.emptyModel
    , emailSettingsModel = Comp.EmailSettingsManage.emptyModel
    }


type Tab
    = ChangePassTab
    | EmailSettingsTab


type Msg
    = SetTab Tab
    | ChangePassMsg Comp.ChangePasswordForm.Msg
    | EmailSettingsMsg Comp.EmailSettingsManage.Msg
