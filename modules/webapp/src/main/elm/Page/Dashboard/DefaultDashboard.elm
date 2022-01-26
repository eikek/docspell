module Page.Dashboard.DefaultDashboard exposing (..)

import Data.Box exposing (Box)
import Data.BoxContent exposing (BoxContent(..))
import Data.Dashboard exposing (Dashboard)
import Data.ItemArrange


value : Dashboard
value =
    { name = "Default"
    , columns = 2
    , boxes =
        [ messageBox
        , newDocuments
        , summary
        ]
    }


messageBox : Box
messageBox =
    { name = "Welcome Message"
    , visible = True
    , decoration = False
    , colspan = 2
    , content =
        BoxMessage
            { title = "Welcome to Docspell"
            , body = ""
            }
    }


newDocuments : Box
newDocuments =
    { name = "New Documents"
    , visible = True
    , decoration = True
    , colspan = 1
    , content =
        BoxQuery
            { query = "inbox:yes"
            , view = Data.ItemArrange.List
            }
    }


summary : Box
summary =
    { name = "Summary"
    , visible = True
    , decoration = True
    , colspan = 1
    , content =
        BoxSummary { query = "" }
    }
