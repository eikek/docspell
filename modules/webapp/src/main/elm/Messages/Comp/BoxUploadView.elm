{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.BoxUploadView exposing (Texts, de, gb, fr)

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

fr : Texts
fr =
    { uploadForm = Messages.Comp.UploadForm.fr
    , moreOptions = "Plus d'options..."
    }
