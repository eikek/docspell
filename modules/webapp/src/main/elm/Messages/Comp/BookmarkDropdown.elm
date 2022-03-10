{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.BookmarkDropdown exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , placeholder : String
    , personal : String
    , collective : String
    , share : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , placeholder = "Bookmark…"
    , personal = "Personal"
    , collective = "Collective"
    , share = "Share"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , placeholder = "Bookmark…"
    , personal = "Persönlich"
    , collective = "Kollektiv"
    , share = "Freigabe"
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , placeholder = "Favoris…"
    , personal = "Personnel"
    , collective = "Groupe"
    , share = "Partage"
    }
