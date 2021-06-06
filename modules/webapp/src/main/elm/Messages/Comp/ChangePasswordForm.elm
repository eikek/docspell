module Messages.Comp.ChangePasswordForm exposing
    ( Texts
    , de
    , gb
    )

import Http
import Messages.Basics
import Messages.Comp.HttpError


type alias Texts =
    { basics : Messages.Basics.Texts
    , httpError : Http.Error -> String
    , currentPassword : String
    , newPassword : String
    , repeatPassword : String
    , currentPasswordPlaceholder : String
    , newPasswordPlaceholder : String
    , repeatPasswordPlaceholder : String
    , passwordMismatch : String
    , fillRequiredFields : String
    , passwordChangeSuccessful : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , httpError = Messages.Comp.HttpError.gb
    , currentPassword = "Current Password"
    , newPassword = "New Password"
    , repeatPassword = "New Password (repeat)"
    , currentPasswordPlaceholder = "Password"
    , newPasswordPlaceholder = "Password"
    , repeatPasswordPlaceholder = "Password"
    , passwordMismatch = "The passwords do not match."
    , fillRequiredFields = "Please fill required fields."
    , passwordChangeSuccessful = "Password has been changed."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , httpError = Messages.Comp.HttpError.de
    , currentPassword = "Passwort ändern"
    , newPassword = "Neues Passwort"
    , repeatPassword = "Neues Passwort (Wiederholung)"
    , currentPasswordPlaceholder = "Passwort"
    , newPasswordPlaceholder = "Passwort"
    , repeatPasswordPlaceholder = "Passwort"
    , passwordMismatch = "Die Passwörter stimmen nicht überein."
    , fillRequiredFields = "Bitte die erforderlichen Felder ausfüllen."
    , passwordChangeSuccessful = "Das Passwort wurde geändert."
    }
