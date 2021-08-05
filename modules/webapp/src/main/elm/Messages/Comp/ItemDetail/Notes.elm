{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Messages.Comp.ItemDetail.Notes exposing
    ( Texts
    , de
    , gb
    )

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , notes : String
    , preview : String
    , supportsMarkdown : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , notes = "Notes"
    , preview = "Preview"
    , supportsMarkdown = "Supports Markdown"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , notes = "Notizen"
    , preview = "Vorschau"
    , supportsMarkdown = "Unterstützt Markdown"
    }
