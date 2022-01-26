module Messages.Page.DefaultDashboard exposing (Texts, de, gb)

import Messages.Basics


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
    , dueHeaderColumns = dueHeaderCols b
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
    , dueHeaderColumns = dueHeaderCols b
    }


dueHeaderCols : Messages.Basics.Texts -> List String
dueHeaderCols b =
    [ b.name, b.correspondent, b.date ]
