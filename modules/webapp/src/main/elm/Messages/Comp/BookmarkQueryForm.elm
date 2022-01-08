{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.BookmarkQueryForm exposing
    ( Texts
    , de
    , gb
    )

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , queryLabel : String
    , userLocation : String
    , userLocationText : String
    , collectiveLocation : String
    , collectiveLocationText : String
    , nameExistsWarning : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , queryLabel = "Query"
    , userLocation = "User scope"
    , userLocationText = "The bookmarked query is just for you"
    , collectiveLocation = "Collective scope"
    , collectiveLocationText = "The bookmarked query can be used and edited by all users"
    , nameExistsWarning = "A bookmark with this name exists, it is overwritten on save!"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , queryLabel = "Abfrage"
    , userLocation = "Persönliches Bookmark"
    , userLocationText = "Der Bookmark ist nur für dich"
    , collectiveLocation = "Kollektiv-Bookmark"
    , collectiveLocationText = "Der Bookmark kann von allen Benutzer verwendet werden"
    , nameExistsWarning = "Der Bookmark existiert bereits. Er wird beim Speichern überschrieben."
    }
