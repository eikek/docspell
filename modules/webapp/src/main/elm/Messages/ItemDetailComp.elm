module Messages.ItemDetailComp exposing (..)

import Messages.ItemDetail.AddFilesForm


type alias Texts =
    { addFilesForm : Messages.ItemDetail.AddFilesForm.Texts
    }


gb : Texts
gb =
    { addFilesForm = Messages.ItemDetail.AddFilesForm.gb
    }
