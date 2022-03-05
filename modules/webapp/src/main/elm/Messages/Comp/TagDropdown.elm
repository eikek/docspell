{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.TagDropdown exposing
    ( Texts
    , de
    , gb
    , fr
    )

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , placeholder : String
    , noCategory : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , placeholder = "Search…"
    , noCategory = "No category"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , placeholder = "Suche…"
    , noCategory = "Keine Kategorie"
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , placeholder = "Rechercher…"
    , noCategory = "Aucune catégorie"
    }