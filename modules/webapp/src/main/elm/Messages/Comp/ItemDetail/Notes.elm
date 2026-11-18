{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ItemDetail.Notes exposing
    ( Texts
    , de
    , fr
    , gb
    , pt
    )

import Messages.Basics
import Messages.Comp.MarkdownInput


type alias Texts =
    { basics : Messages.Basics.Texts
    , notes : String
    , preview : String
    , supportsMarkdown : String
    , markdownInput : Messages.Comp.MarkdownInput.Texts
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , notes = "Notes"
    , preview = "Preview"
    , supportsMarkdown = "Supports Markdown"
    , markdownInput = Messages.Comp.MarkdownInput.gb
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , notes = "Notizen"
    , preview = "Vorschau"
    , supportsMarkdown = "Unterstützt Markdown"
    , markdownInput = Messages.Comp.MarkdownInput.de
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , notes = "Notes"
    , preview = "Aperçu"
    , supportsMarkdown = "Markdown supporté"
    , markdownInput = Messages.Comp.MarkdownInput.fr
    }


pt : Texts
pt =
    { basics = Messages.Basics.pt
    , notes = "Notas"
    , preview = "Pré-visualização"
    , supportsMarkdown = "Suporta Markdown"
    , markdownInput = Messages.Comp.MarkdownInput.pt
    }
