{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.BoxUploadEdit exposing (Texts, de, fr, gb)


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


fr : Texts
fr =
    { sourceLabel = "Source"
    , sourcePlaceholder = "Choisir la source…"
    , infoText = "Choisir une source (facultatif) sinon les paramètres par défaut sont utilisés pour tous les envois"
    }
