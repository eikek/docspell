{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Messages.Comp.TagForm exposing
    ( Texts
    , de
    , gb
    )

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , selectDefineCategory : String
    , category : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , selectDefineCategory = "Select or define category..."
    , category = "Category"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , selectDefineCategory = "Wähle oder erstelle eine Kategorie..."
    , category = "Kategorie"
    }
