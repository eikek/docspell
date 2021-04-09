module Messages.Page.Login exposing
    ( Texts
    , de
    , gb
    )


type alias Texts =
    { loginToDocspell : String
    , username : String
    , collectiveSlashLogin : String
    , password : String
    , rememberMe : String
    , loginPlaceholder : String
    , passwordPlaceholder : String
    , loginButton : String
    , loginSuccessful : String
    , noAccount : String
    , signupLink : String
    }


gb : Texts
gb =
    { loginToDocspell = "Login to Docspell"
    , username = "Username"
    , collectiveSlashLogin = "Collective / Login"
    , password = "Password"
    , rememberMe = "Remember Me"
    , loginPlaceholder = "Login"
    , passwordPlaceholder = "Password"
    , loginButton = "Login"
    , loginSuccessful = "Login successful"
    , noAccount = "No account?"
    , signupLink = "Sign up!"
    }


de : Texts
de =
    { loginToDocspell = "Docspell Anmeldung"
    , username = "Benutzer"
    , collectiveSlashLogin = "Kollektiv / Benutzer"
    , password = "Passwort"
    , rememberMe = "Anmeldung speichern"
    , loginPlaceholder = "Benutzer"
    , passwordPlaceholder = "Passwort"
    , loginButton = "Anmelden"
    , loginSuccessful = "Anmeldung erfolgreich"
    , noAccount = "Kein Konto?"
    , signupLink = "Hier registrieren!"
    }
