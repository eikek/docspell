module Messages.Page.ShareDetail exposing (..)

import Messages.Comp.SharePasswordForm


type alias Texts =
    { passwordForm : Messages.Comp.SharePasswordForm.Texts
    }


gb : Texts
gb =
    { passwordForm = Messages.Comp.SharePasswordForm.gb
    }


de : Texts
de =
    { passwordForm = Messages.Comp.SharePasswordForm.de
    }
