module Messages.Page.NewInvite exposing (..)

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , createNewInvitations : String
    , invitationKey : String
    , password : String
    , reset : String
    , inviteInfo : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , createNewInvitations = "Create new invitations"
    , invitationKey = "Invitation Key"
    , password = "Password"
    , reset = "Reset"
    , inviteInfo =
        """Docspell requires an invite when signing up. You can
         create these invites here and send them to friends so
         they can signup with docspell.

         Each invite can only be used once. You'll need to
         create one key for each person you want to invite.

         Creating an invite requires providing the password
         from the configuration."""
    }


de : Texts
de =
    gb
