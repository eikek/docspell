module Page.UserSettings.Data exposing
    ( Model
    , Msg(..)
    , Tab(..)
    , emptyModel
    )

import Comp.ChangePasswordForm
import Comp.EmailSettingsManage
import Comp.ImapSettingsManage
import Comp.NotificationForm
import Comp.ScanMailboxManage
import Comp.UiSettingsManage
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)


type alias Model =
    { currentTab : Maybe Tab
    , changePassModel : Comp.ChangePasswordForm.Model
    , emailSettingsModel : Comp.EmailSettingsManage.Model
    , imapSettingsModel : Comp.ImapSettingsManage.Model
    , notificationModel : Comp.NotificationForm.Model
    , scanMailboxModel : Comp.ScanMailboxManage.Model
    , uiSettingsModel : Comp.UiSettingsManage.Model
    }


emptyModel : Flags -> Model
emptyModel flags =
    { currentTab = Nothing
    , changePassModel = Comp.ChangePasswordForm.emptyModel
    , emailSettingsModel = Comp.EmailSettingsManage.emptyModel
    , imapSettingsModel = Comp.ImapSettingsManage.emptyModel
    , notificationModel = Tuple.first (Comp.NotificationForm.init flags)
    , scanMailboxModel = Tuple.first (Comp.ScanMailboxManage.init flags)
    , uiSettingsModel = Comp.UiSettingsManage.init Data.UiSettings.defaults
    }


type Tab
    = ChangePassTab
    | EmailSettingsTab
    | ImapSettingsTab
    | NotificationTab
    | ScanMailboxTab
    | UiSettingsTab


type Msg
    = SetTab Tab
    | ChangePassMsg Comp.ChangePasswordForm.Msg
    | EmailSettingsMsg Comp.EmailSettingsManage.Msg
    | NotificationMsg Comp.NotificationForm.Msg
    | ImapSettingsMsg Comp.ImapSettingsManage.Msg
    | ScanMailboxMsg Comp.ScanMailboxManage.Msg
    | GetUiSettings UiSettings
    | UiSettingsMsg Comp.UiSettingsManage.Msg
