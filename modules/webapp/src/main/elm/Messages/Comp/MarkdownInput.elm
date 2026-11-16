{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.MarkdownInput exposing
    ( Texts
    , de
    , fr
    , gb
    , pt
    )


type alias Texts =
    { placeholder : String
    }


gb : Texts
gb =
    { placeholder = "Add notes here…"
    }


de : Texts
de =
    { placeholder = "Hier Notizen hinzufügen…"
    }


fr : Texts
fr =
    { placeholder = "Ajouter des notes ici…"
    }


pt : Texts
pt =
    { placeholder = "Adicionar notas aqui..."
    }
