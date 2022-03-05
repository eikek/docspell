{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Page.Upload exposing
    ( Texts
    , de
    , gb
    , fr
    )

import Messages.Comp.UploadForm


type alias Texts =
    { uploadForm : Messages.Comp.UploadForm.Texts
    }


gb : Texts
gb =
    { uploadForm = Messages.Comp.UploadForm.gb
    }


de : Texts
de =
    { uploadForm = Messages.Comp.UploadForm.de
    }


fr : Texts
fr =
    { uploadForm = Messages.Comp.UploadForm.fr
    }
