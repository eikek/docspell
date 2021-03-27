module Messages.LoginPage exposing
    ( Texts
    , de
    , fr
    , gb
    )


type alias Texts =
    { username : String
    , password : String
    , loginPlaceholder : String
    , passwordPlaceholder : String
    , loginButton : String
    , loginSuccessful : String
    , noAccount : String
    , signupLink : String
    }


gb : Texts
gb =
    { username = "Username"
    , password = "Password"
    , loginPlaceholder = "Login"
    , passwordPlaceholder = "Password"
    , loginButton = "Login"
    , loginSuccessful = "Login successful"
    , noAccount = "No account?"
    , signupLink = "Sign up!"
    }


de : Texts
de =
    { username = "Benutzer"
    , password = "Passwort"
    , loginPlaceholder = "Benutzer"
    , passwordPlaceholder = "Passwort"
    , loginButton = "Anmelden"
    , loginSuccessful = "Anmeldung erfolgreich"
    , noAccount = "Kein Konto?"
    , signupLink = "Hier registrieren!"
    }


fr : Texts
fr =
    { username = "Identifiant"
    , password = "Mot de passe"
    , loginPlaceholder = "Utilisateur"
    , passwordPlaceholder = "Mot de passe"
    , loginButton = "Connexion"
    , loginSuccessful = "Identification réussie"
    , noAccount = "Pas de compte ?"
    , signupLink = "S'inscrire"
    }
