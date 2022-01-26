module Messages.Comp.DashboardEdit exposing (Texts, de, gb)

import Messages.Basics
import Messages.Comp.BoxEdit
import Messages.Data.BoxContent


type alias Texts =
    { boxView : Messages.Comp.BoxEdit.Texts
    , boxContent : Messages.Data.BoxContent.Texts
    , basics : Messages.Basics.Texts
    , namePlaceholder : String
    , columns : String
    , dashboardBoxes : String
    , newBox : String
    }


gb : Texts
gb =
    { boxView = Messages.Comp.BoxEdit.gb
    , boxContent = Messages.Data.BoxContent.gb
    , basics = Messages.Basics.gb
    , namePlaceholder = "Dashboard name"
    , columns = "Columns"
    , dashboardBoxes = "Dashboard Boxes"
    , newBox = "New box"
    }


de : Texts
de =
    { boxView = Messages.Comp.BoxEdit.de
    , boxContent = Messages.Data.BoxContent.de
    , basics = Messages.Basics.de
    , namePlaceholder = "Dashboardname"
    , columns = "Spalten"
    , dashboardBoxes = "Dashboard Kacheln"
    , newBox = "Neue Kachel"
    }
