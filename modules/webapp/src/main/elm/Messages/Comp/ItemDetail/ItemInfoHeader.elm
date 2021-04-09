module Messages.Comp.ItemDetail.ItemInfoHeader exposing (..)


type alias Texts =
    { itemDate : String
    , dueDate : String
    , correspondent : String
    , concerning : String
    , folder : String
    , source : String
    , new : String
    }


gb : Texts
gb =
    { itemDate = "Item Date"
    , dueDate = "Due Date"
    , correspondent = "Correspondent"
    , concerning = "Concerning"
    , folder = "Folder"
    , source = "Source"
    , new = "New"
    }
