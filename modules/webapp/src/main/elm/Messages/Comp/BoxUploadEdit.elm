{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.BoxUploadEdit exposing (Texts, de, gb)


type alias Texts =
    { sourceLabel : String
    , sourcePlaceholder : String
    , infoText : String
    }


gb : Texts
gb =
    { sourceLabel = "Source"
    , sourcePlaceholder = "Choose source…"
    , infoText = "Optionally choose a source otherwise default settings apply to all uploads."
    }


de : Texts
de =
    { sourceLabel = "Quelle"
    , sourcePlaceholder = "Quelle…"
    , infoText = "Optional kann eine Quelle als Einstellung gewählt werden, sonst werden Standardeinstellungen verwendet."
    }
