module Page.UserSettings.Data exposing
    ( Model
    , Msg(..)
    , Tab(..)
    , emptyModel
    )

import Comp.ChangePasswordForm
import Comp.EmailSettingsManage
import Comp.NotificationForm
import Data.Flags exposing (Flags)


type alias Model =
    { currentTab : Maybe Tab
    , changePassModel : Comp.ChangePasswordForm.Model
    , emailSettingsModel : Comp.EmailSettingsManage.Model
    , notificationModel : Comp.NotificationForm.Model
    }


emptyModel : Flags -> Model
emptyModel flags =
    { currentTab = Nothing
    , changePassModel = Comp.ChangePasswordForm.emptyModel
    , emailSettingsModel = Comp.EmailSettingsManage.emptyModel
    , notificationModel = Tuple.first (Comp.NotificationForm.init flags)
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
    | Init
