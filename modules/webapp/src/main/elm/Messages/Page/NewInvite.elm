{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Page.NewInvite exposing
    ( Texts
    , de
    , fr
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


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , httpError = Messages.Comp.HttpError.fr
    , createNewInvitations = "Créer de nouvelles invitations"
    , invitationKey = "Clé d'invitation"
    , password = "Mot de passe"
    , reset = "Reset"
    , newInvitationCreated = "Nouvelle invitation créée."
    , inviteInfo =
        """
Docspell requiert une invitation pour s'inscrire. Les
invitations peuvent être créées ici et envoyées  à des
amis afin qu'ils puissent s'inscrire.

Chaque invitation peut être utilisée uniquement une
seule fois.  Chaque nouvelle personne invitée nécessitera
la création d'une nouvelle clé.

La création d'invitation requiert de fournir le mot 
de passe configuré.
"""
    }
