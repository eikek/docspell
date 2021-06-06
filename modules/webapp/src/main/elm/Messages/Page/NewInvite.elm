module Messages.Page.NewInvite exposing
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
    , createNewInvitations : String
    , invitationKey : String
    , password : String
    , reset : String
    , newInvitationCreated : String
    , inviteInfo : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , httpError = Messages.Comp.HttpError.gb
    , createNewInvitations = "Create new invitations"
    , invitationKey = "Invitation Key"
    , password = "Password"
    , reset = "Reset"
    , newInvitationCreated = "New invitation created."
    , inviteInfo =
        """
Docspell requires an invite when signing up. You can
create these invites here and send them to friends so
they can signup with docspell.

Each invite can only be used once. You'll need to
create one key for each person you want to invite.

Creating an invite requires providing the password
from the configuration.
"""
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , httpError = Messages.Comp.HttpError.de
    , createNewInvitations = "Neue Einladung erstellen"
    , invitationKey = "Einladungs-ID"
    , password = "Passwort"
    , reset = "Zurücksetzen"
    , newInvitationCreated = "Neue Einladung erstellt."
    , inviteInfo =
        """
Docspell erfordert eine Einladung, wenn ein neues Konto registriert
wird. Diese Einladungen können hier erstellt und dann an
Freunde/Bekannte versendet werden, damit diese sich ein Konto
erstellen können.

Jede Einladung kann genau einmal verwendet werden und läuft nach
einiger Zeit ab. Es muss also für jede Person eine neue Einladung
generiert werden.

Um eine Einladung zu erstellen, wird das Passwort aus der
Konfiguration benötigt.

"""
    }
