{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.TagForm exposing
    ( Texts
    , de
    , gb
    , fr
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


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , selectDefineCategory = "Choisir ou définir une catégorie..."
    , category = "Catégorie"
    }
