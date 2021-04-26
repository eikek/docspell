module Messages.Comp.TagSelect exposing (Texts, gb)

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
