module Messages.Comp.FolderSelect exposing
    ( Texts
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
