module Messages.Basics exposing (Texts, gb)


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
    , searchPlaceholder : String
    , selectPlaceholder : String
    , id : String
    , ok : String
    , yes : String
    , no : String
    , chooseTag : String
    , loading : String
    , name : String
    , organization : String
    , person : String
    , equipment : String
    , folder : String
    , date : String
    , correspondent : String
    , concerning : String
    , customFields : String
    , direction : String
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
    , searchPlaceholder = "Search…"
    , selectPlaceholder = "Select…"
    , id = "Id"
    , ok = "Ok"
    , yes = "Yes"
    , no = "No"
    , chooseTag = "Choose a tag…"
    , loading = "Loading…"
    , name = "Name"
    , organization = "Organization"
    , person = "Person"
    , equipment = "Equipment"
    , folder = "Folder"
    , date = "Date"
    , correspondent = "Correspondent"
    , concerning = "Concerning"
    , customFields = "Custom Fields"
    , direction = "Direction"
    }
