module Page.UserSettings.Data exposing
    ( Model
    , Msg(..)
    , Tab(..)
    , emptyModel
    )

import Comp.ChangePasswordForm
import Comp.EmailSettingsManage
import Comp.NotificationForm


type alias Model =
    { currentTab : Maybe Tab
    , changePassModel : Comp.ChangePasswordForm.Model
    , emailSettingsModel : Comp.EmailSettingsManage.Model
    , notificationModel : Comp.NotificationForm.Model
    }


emptyModel : Model
emptyModel =
    { currentTab = Nothing
    , changePassModel = Comp.ChangePasswordForm.emptyModel
    , emailSettingsModel = Comp.EmailSettingsManage.emptyModel
    , notificationModel = Comp.NotificationForm.init
    }


type Tab
    = ChangePassTab
    | EmailSettingsTab
    | NotificationTab


type Msg
    = SetTab Tab
    | ChangePassMsg Comp.ChangePasswordForm.Msg
    | EmailSettingsMsg Comp.EmailSettingsManage.Msg
    | NotificationMsg Comp.NotificationForm.Msg
