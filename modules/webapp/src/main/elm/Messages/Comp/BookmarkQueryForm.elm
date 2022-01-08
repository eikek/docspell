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
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , queryLabel = "Query"
    , userLocation = "User scope"
    , userLocationText = "The bookmarked query is just for you"
    , collectiveLocation = "Collective scope"
    , collectiveLocationText = "The bookmarked query can be used and edited by all users"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , queryLabel = "Abfrage"
    , userLocation = "Persönliches Bookmark"
    , userLocationText = "Der Bookmark ist nur für dich"
    , collectiveLocation = "Kollektiv-Bookmark"
    , collectiveLocationText = "Der Bookmark kann von allen Benutzer verwendet werden"
    }
