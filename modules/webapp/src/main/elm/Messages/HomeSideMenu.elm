module Messages.HomeSideMenu exposing (..)

import Messages.MultiEditComp
import Messages.SearchMenuComp


type alias Texts =
    { searchMenu : Messages.SearchMenuComp.Texts
    , multiEdit : Messages.MultiEditComp.Texts
    , editMode : String
    , resetSearchForm : String
    , multiEditHeader : String
    , multiEditInfo : String
    , close : String
    }


gb : Texts
gb =
    { searchMenu = Messages.SearchMenuComp.gb
    , multiEdit = Messages.MultiEditComp.gb
    , editMode = "Edit Mode"
    , resetSearchForm = "Reset search form"
    , multiEditHeader = "Multi-Edit"
    , multiEditInfo = "Note that a change here immediatly affects all selected items on the right!"
    , close = "Close"
    }
