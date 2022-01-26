module Messages.Comp.BoxView exposing (Texts, de, gb)

import Messages.Comp.BoxQueryView
import Messages.Comp.BoxSummaryView


type alias Texts =
    { queryView : Messages.Comp.BoxQueryView.Texts
    , summaryView : Messages.Comp.BoxSummaryView.Texts
    }


gb : Texts
gb =
    { queryView = Messages.Comp.BoxQueryView.gb
    , summaryView = Messages.Comp.BoxSummaryView.gb
    }


de : Texts
de =
    { queryView = Messages.Comp.BoxQueryView.de
    , summaryView = Messages.Comp.BoxSummaryView.de
    }
