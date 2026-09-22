{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.BookmarkQueryForm exposing
    ( Texts
    , de
    , fr
    , ja
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
    , nameExistsWarning = "A bookmark with this name exists! Choose another name."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , queryLabel = "Abfrage"
    , userLocation = "Persönliches Bookmark"
    , userLocationText = "Der Bookmark ist nur für dich"
    , collectiveLocation = "Kollektiv-Bookmark"
    , collectiveLocationText = "Der Bookmark kann von allen Benutzer verwendet werden"
    , nameExistsWarning = "Der Bookmark existiert bereits! Verwende einen anderen Namen."
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , queryLabel = "requête"
    , userLocation = "Favoris personnels"
    , userLocationText = "Utilisé et édité que par vous"
    , collectiveLocation = "Favoris du groupe"
    , collectiveLocationText = "Utilisé et édité par tous les utilisateurs du groupe"
    , nameExistsWarning = "Un favoris avec ce nom existe déjà !"
    }


ja : Texts
ja =
    { basics = Messages.Basics.ja
    , queryLabel = "検索"
    , userLocation = "ユーザー範囲"
    , userLocationText = "ブックマークした検索はあなたのみが利用できます"
    , collectiveLocation = "共通範囲"
    , collectiveLocationText = "ブックマークした検索はすべてのユーザーが利用および編集できます"
    , nameExistsWarning = "この名前のブックマークは既に存在します。別の名前を選択してください。"
    }
