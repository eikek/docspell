{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Messages.Basics exposing
    ( Texts
    , de
    , gb
    )


type alias Texts =
    { incoming : String
    , outgoing : String
    , deleted : String
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
    , folderNotOwnerWarning : String
    }


gb : Texts
gb =
    { incoming = "Incoming"
    , outgoing = "Outgoing"
    , deleted = "Deleted"
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
    , folderNotOwnerWarning =
        """
You are **not a member** of this folder. This item will be **hidden**
from any search now. Use a folder where you are a member of to make this
item visible. This message will disappear then.
                      """
    }


de : Texts
de =
    { incoming = "Eingehend"
    , outgoing = "Ausgehend"
    , deleted = "Gelöscht"
    , tags = "Tags"
    , items = "Dokumente"
    , submit = "Speichern"
    , submitThisForm = "Formular abschicken"
    , cancel = "Abbrechen"
    , delete = "Löschen"
    , created = "Erstellt"
    , edit = "Ändern"
    , back = "Zurück"
    , backToList = "Zurück zur Liste"
    , searchPlaceholder = "Suche…"
    , selectPlaceholder = "Auswahl…"
    , id = "ID"
    , ok = "Ok"
    , yes = "Ja"
    , no = "Nein"
    , chooseTag = "Wähle einen Tag…"
    , loading = "Laden…"
    , name = "Name"
    , organization = "Organisation"
    , person = "Person"
    , equipment = "Ausstattung"
    , folder = "Ordner"
    , date = "Datum"
    , correspondent = "Korrespondent"
    , concerning = "Betreffend"
    , customFields = "Benutzerfelder"
    , direction = "Richtung"
    , folderNotOwnerWarning =
        """
Du bist *kein* Mitglied dieses Ordners. Dokumnte, welche durch diese
URL hochgeladen werden, sind für dich in der Suche *nicht* sichtbar.
Nutze lieber einen Ordner, dem Du als Mitglied zugeordnet bist. Diese
Nachricht verschwindet dann.
                      """
    }
