{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.FolderSelect exposing
    ( Texts
    , de
    , fr
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


fr : Texts
fr =
    { expandCollapse = Messages.Comp.ExpandCollapse.fr
    }
