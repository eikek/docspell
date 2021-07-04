{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Messages.Comp.FolderSelect exposing
    ( Texts
    , de
    , gb
    )

import Messages.Comp.ExpandCollapse


type alias Texts =
    { expandCollapse : Messages.Comp.ExpandCollapse.Texts
    }


gb : Texts
gb =
    { expandCollapse = Messages.Comp.ExpandCollapse.gb
    }


de : Texts
de =
    { expandCollapse = Messages.Comp.ExpandCollapse.de
    }
