module Messages.ChangePasswordFormComp exposing (..)


type alias Texts =
    { currentPassword : String
    , newPassword : String
    , repeatPassword : String
    , currentPasswordPlaceholder : String
    , newPasswordPlaceholder : String
    , repeatPasswordPlaceholder : String
    }


gb : Texts
gb =
    { currentPassword = "Current Password"
    , newPassword = "New Password"
    , repeatPassword = "New Password (repeat)"
    , currentPasswordPlaceholder = "Password"
    , newPasswordPlaceholder = "Password"
    , repeatPasswordPlaceholder = "Password"
    }
