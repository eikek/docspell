{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.BoxMessageEdit exposing (Texts, de, fr, gb)


type alias Texts =
    { titleLabel : String
    , titlePlaceholder : String
    , bodyLabel : String
    , bodyPlaceholder : String
    , infoText : String
    }


gb : Texts
gb =
    { titleLabel = "Title"
    , titlePlaceholder = "Message title…"
    , bodyLabel = "Body"
    , bodyPlaceholder = "Message body…"
    , infoText = "Markdown can be used in both fields for simple formatting."
    }


de : Texts
de =
    { titleLabel = "Titel"
    , titlePlaceholder = "Titel…"
    , bodyLabel = "Nachricht"
    , bodyPlaceholder = "Text…"
    , infoText = "Markdown kann in beiden Feldern für einfache Formatierung verwendet werden."
    }


fr : Texts
fr =
    { titleLabel = "Titre"
    , titlePlaceholder = "Titre du message..."
    , bodyLabel = "Corps"
    , bodyPlaceholder = "Cors du message…"
    , infoText = "Markdown peut être utilisé dans les deux champs pour le formatage simple."
    }
