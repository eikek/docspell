module Messages.Comp.TagSelect exposing
    ( Texts
    , de
    , gb
    )

import Messages.Comp.ExpandCollapse


type alias Texts =
    { expandCollapse : Messages.Comp.ExpandCollapse.Texts
    , hideEmpty : String
    , showEmpty : String
    , filterPlaceholder : String
    }


gb : Texts
gb =
    { expandCollapse = Messages.Comp.ExpandCollapse.gb
    , hideEmpty = "Hide empty"
    , showEmpty = "Show empty"
    , filterPlaceholder = "Filter …"
    }


de : Texts
de =
    { expandCollapse = Messages.Comp.ExpandCollapse.de
    , hideEmpty = "Leere ausblenden"
    , showEmpty = "Leere anzeigen"
    , filterPlaceholder = "Filter …"
    }
