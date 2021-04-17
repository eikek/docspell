module Messages.Page.Register exposing (Texts, gb)

import Http
import Messages.Basics
import Messages.Comp.HttpError


type alias Texts =
    { basics : Messages.Basics.Texts
    , httpError : Http.Error -> String
    , signupToDocspell : String
    , collectiveId : String
    , collective : String
    , userLogin : String
    , username : String
    , password : String
    , passwordRepeat : String
    , invitationKey : String
    , alreadySignedUp : String
    , signIn : String
    , registrationSuccessful : String
    , passwordsDontMatch : String
    , allFieldsRequired : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , httpError = Messages.Comp.HttpError.gb
    , signupToDocspell = "Signup to Docspell"
    , collectiveId = "Collective ID"
    , collective = "Collective"
    , userLogin = "User Login"
    , username = "Username"
    , password = "Password"
    , passwordRepeat = "Password (repeat)"
    , invitationKey = "Invitation Key"
    , alreadySignedUp = "Already signed up?"
    , signIn = "Sign in"
    , registrationSuccessful = "Registration successful."
    , passwordsDontMatch = "The passwords do not match."
    , allFieldsRequired = "All fields are required!"
    }
