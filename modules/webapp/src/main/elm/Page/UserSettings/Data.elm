module Page.UserSettings.Data exposing (..)

import Comp.ChangePasswordForm

type alias Model =
    { currentTab: Maybe Tab
    , changePassModel: Comp.ChangePasswordForm.Model
    }

emptyModel: Model
emptyModel =
    { currentTab = Nothing
    , changePassModel = Comp.ChangePasswordForm.emptyModel
    }

type Tab = ChangePassTab

type Msg
    = SetTab Tab
    | ChangePassMsg Comp.ChangePasswordForm.Msg
