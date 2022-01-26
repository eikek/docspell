module Page.Dashboard.DefaultDashboard exposing (getDefaultDashboard, value)

import Data.Box exposing (Box)
import Data.BoxContent exposing (BoxContent(..), SearchQuery(..), SummaryShow(..))
import Data.Dashboard exposing (Dashboard)
import Data.Flags exposing (Flags)
import Data.ItemColumn as IC
import Data.UiSettings exposing (UiSettings)
import Messages
import Messages.Page.DefaultDashboard exposing (Texts)
import Messages.UiLanguage


value : Texts -> Dashboard
value texts =
    { name = texts.default
    , columns = 2
    , boxes =
        [ messageBox texts
        , fieldStats
        , newDocuments texts
        , dueDocuments texts
        , upload
        , summary texts
        ]
    }


getDefaultDashboard : Flags -> UiSettings -> Dashboard
getDefaultDashboard flags settings =
    let
        lang =
            Data.UiSettings.getUiLanguage flags settings Messages.UiLanguage.English

        texts =
            Messages.get lang
    in
    value texts.dashboard.defaultDashboard



--- Boxes


messageBox : Texts -> Box
messageBox texts =
    { name = texts.welcomeName
    , visible = True
    , decoration = False
    , colspan = 2
    , content =
        BoxMessage
            { title = texts.welcomeTitle
            , body = texts.welcomeBody
            }
    }


newDocuments : Texts -> Box
newDocuments texts =
    { name = texts.newDocsName
    , visible = True
    , decoration = True
    , colspan = 1
    , content =
        BoxQuery
            { query = SearchQueryString "inbox:yes"
            , limit = 5
            , details = True
            , showHeaders = False
            , columns = []
            }
    }


dueDocuments : Texts -> Box
dueDocuments texts =
    { name = texts.dueInDays 10
    , visible = True
    , decoration = True
    , colspan = 1
    , content =
        BoxQuery
            { query = SearchQueryString "due>today;-10d due<today;+10d"
            , limit = 5
            , details = True
            , showHeaders = True
            , columns =
                [ IC.Name
                , IC.Correspondent
                , IC.DueDateShort
                ]
            }
    }


summary : Texts -> Box
summary texts =
    { name = texts.summaryName
    , visible = True
    , decoration = True
    , colspan = 1
    , content =
        BoxStats
            { query = SearchQueryString ""
            , show = SummaryShowGeneral
            }
    }


fieldStats : Box
fieldStats =
    { name = ""
    , visible = True
    , decoration = True
    , colspan = 2
    , content =
        BoxStats
            { query = SearchQueryString ""
            , show = SummaryShowFields False
            }
    }


upload : Box
upload =
    { name = ""
    , visible = True
    , decoration = True
    , colspan = 1
    , content =
        BoxUpload
            { sourceId = Nothing
            }
    }
