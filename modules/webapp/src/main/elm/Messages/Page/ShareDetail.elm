module Messages.Page.ShareDetail exposing (..)

import Messages.Comp.SharePasswordForm
import Messages.DateFormat
import Messages.UiLanguage exposing (UiLanguage(..))


type alias Texts =
    { passwordForm : Messages.Comp.SharePasswordForm.Texts
    , formatDateLong : Int -> String
    , formatDateShort : Int -> String
    }


gb : Texts
gb =
    { passwordForm = Messages.Comp.SharePasswordForm.gb
    , formatDateLong = Messages.DateFormat.formatDateLong English
    , formatDateShort = Messages.DateFormat.formatDateShort English
    }


de : Texts
de =
    { passwordForm = Messages.Comp.SharePasswordForm.de
    , formatDateLong = Messages.DateFormat.formatDateLong German
    , formatDateShort = Messages.DateFormat.formatDateShort German
    }
