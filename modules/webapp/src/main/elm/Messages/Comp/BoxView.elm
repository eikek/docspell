module Messages.Comp.BoxView exposing (Texts, de, gb)

import Messages.Comp.BoxQueryView
import Messages.Comp.BoxStatsView
import Messages.Comp.BoxUploadView


type alias Texts =
    { queryView : Messages.Comp.BoxQueryView.Texts
    , statsView : Messages.Comp.BoxStatsView.Texts
    , uploadView : Messages.Comp.BoxUploadView.Texts
    }


gb : Texts
gb =
    { queryView = Messages.Comp.BoxQueryView.gb
    , statsView = Messages.Comp.BoxStatsView.gb
    , uploadView = Messages.Comp.BoxUploadView.gb
    }


de : Texts
de =
    { queryView = Messages.Comp.BoxQueryView.de
    , statsView = Messages.Comp.BoxStatsView.de
    , uploadView = Messages.Comp.BoxUploadView.de
    }
