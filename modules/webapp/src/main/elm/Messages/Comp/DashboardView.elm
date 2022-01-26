module Messages.Comp.DashboardView exposing (Texts, de, gb)

import Messages.Comp.BoxView


type alias Texts =
    { boxView : Messages.Comp.BoxView.Texts
    }


gb : Texts
gb =
    { boxView = Messages.Comp.BoxView.gb
    }


de : Texts
de =
    { boxView = Messages.Comp.BoxView.de
    }
