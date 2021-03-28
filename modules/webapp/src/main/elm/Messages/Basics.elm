module Messages.Basics exposing (..)


type alias Texts =
    { incoming : String
    , outgoing : String
    , tags : String
    , items : String
    , submit : String
    , submitThisForm : String
    , cancel : String
    , delete : String
    , created : String
    , edit : String
    , back : String
    , backToList : String
    }


gb : Texts
gb =
    { incoming = "Incoming"
    , outgoing = "Outgoing"
    , tags = "Tags"
    , items = "Items"
    , submit = "Submit"
    , submitThisForm = "Submit this form"
    , cancel = "Cancel"
    , delete = "Delete"
    , created = "Created"
    , edit = "Edit"
    , back = "Back"
    , backToList = "Back to list"
    }


de : Texts
de =
    gb
