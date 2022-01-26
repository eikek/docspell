module Messages.Page.DefaultDashboard exposing (Texts, de, gb)

import Data.Fields exposing (Field)
import Messages.Basics
import Messages.Data.Fields


type alias Texts =
    { basics : Messages.Basics.Texts
    , default : String
    , welcomeName : String
    , welcomeTitle : String
    , welcomeBody : String
    , summaryName : String
    , dueInDays : Int -> String
    , dueHeaderColumns : List String
    , newDocsName : String
    }


gb : Texts
gb =
    let
        b =
            Messages.Basics.gb
    in
    { basics = b
    , default = "Default"
    , welcomeName = "Welcome Message"
    , welcomeTitle = "# Welcome to Docspell"
    , welcomeBody = "Docspell keeps your documents organized."
    , summaryName = "Summary"
    , dueInDays = \n -> "Due in " ++ String.fromInt n ++ " days"
    , dueHeaderColumns = dueHeaderCols b Messages.Data.Fields.gb
    , newDocsName = "New Documents"
    }


de : Texts
de =
    let
        b =
            Messages.Basics.de
    in
    { basics = b
    , default = "Standard"
    , welcomeName = "Willkommens-Nachricht"
    , welcomeTitle = "# Willkommen zu Docspell"
    , welcomeBody = "Docspell behält die Übersicht über deine Dokumene."
    , summaryName = "Zahlen"
    , dueInDays = \n -> "Fällig in " ++ String.fromInt n ++ " Tagen"
    , newDocsName = "Neue Dokumente"
    , dueHeaderColumns = dueHeaderCols b Messages.Data.Fields.de
    }


dueHeaderCols : Messages.Basics.Texts -> (Field -> String) -> List String
dueHeaderCols b d =
    [ b.name, b.correspondent, d Data.Fields.DueDate ]
