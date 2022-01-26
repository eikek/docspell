module Messages.Comp.BoxView exposing (Texts, de, gb)

import Messages.Comp.BoxQueryView
import Messages.Comp.BoxSummaryView
import Messages.Comp.BoxUploadView


type alias Texts =
    { queryView : Messages.Comp.BoxQueryView.Texts
    , summaryView : Messages.Comp.BoxSummaryView.Texts
    , uploadView : Messages.Comp.BoxUploadView.Texts
    }


gb : Texts
gb =
    { queryView = Messages.Comp.BoxQueryView.gb
    , summaryView = Messages.Comp.BoxSummaryView.gb
    , uploadView = Messages.Comp.BoxUploadView.gb
    }


de : Texts
de =
    { queryView = Messages.Comp.BoxQueryView.de
    , summaryView = Messages.Comp.BoxSummaryView.de
    , uploadView = Messages.Comp.BoxUploadView.de
    }
