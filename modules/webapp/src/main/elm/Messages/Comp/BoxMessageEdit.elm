module Messages.Comp.BoxMessageEdit exposing (Texts, de, gb)


type alias Texts =
    { titleLabel : String
    , titlePlaceholder : String
    , bodyLabel : String
    , bodyPlaceholder : String
    , infoText : String
    }


gb : Texts
gb =
    { titleLabel = "Title"
    , titlePlaceholder = "Message title…"
    , bodyLabel = "Body"
    , bodyPlaceholder = "Message body…"
    , infoText = "Markdown can be used in both fields for simple formatting."
    }


de : Texts
de =
    { titleLabel = "Titel"
    , titlePlaceholder = "Titel…"
    , bodyLabel = "Nachricht"
    , bodyPlaceholder = "Text…"
    , infoText = "Markdown kann in beiden Feldern für einfache Formatierung verwendet werden."
    }
