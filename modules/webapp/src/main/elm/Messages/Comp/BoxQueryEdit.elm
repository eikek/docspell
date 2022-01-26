{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.BoxQueryEdit exposing (Texts, de, gb)

import Messages.Comp.BoxSearchQueryInput
import Messages.Comp.ItemColumnDropdown


type alias Texts =
    { columnDropdown : Messages.Comp.ItemColumnDropdown.Texts
    , searchQuery : Messages.Comp.BoxSearchQueryInput.Texts
    , showColumnHeaders : String
    }


gb : Texts
gb =
    { columnDropdown = Messages.Comp.ItemColumnDropdown.gb
    , searchQuery = Messages.Comp.BoxSearchQueryInput.gb
    , showColumnHeaders = "Show column headers"
    }


de : Texts
de =
    { columnDropdown = Messages.Comp.ItemColumnDropdown.de
    , searchQuery = Messages.Comp.BoxSearchQueryInput.de
    , showColumnHeaders = "Spaltennamen anzeigen"
    }
