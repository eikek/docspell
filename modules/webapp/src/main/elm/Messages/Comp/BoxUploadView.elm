module Messages.Comp.BoxUploadView exposing (Texts, de, gb)

import Messages.Comp.UploadForm


type alias Texts =
    { uploadForm : Messages.Comp.UploadForm.Texts
    , moreOptions : String
    }


gb : Texts
gb =
    { uploadForm = Messages.Comp.UploadForm.gb
    , moreOptions = "More options…"
    }


de : Texts
de =
    { uploadForm = Messages.Comp.UploadForm.de
    , moreOptions = "More options…"
    }
