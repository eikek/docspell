{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Upload.Data exposing
    ( Model
    , Msg(..)
    , emptyModel
    , reset
    )

import Comp.UploadForm


type alias Model =
    { uploadForm : Comp.UploadForm.Model
    }


emptyModel : Model
emptyModel =
    { uploadForm = Comp.UploadForm.init
    }


type Msg
    = UploadMsg Comp.UploadForm.Msg


reset : Msg
reset =
    UploadMsg Comp.UploadForm.reset
