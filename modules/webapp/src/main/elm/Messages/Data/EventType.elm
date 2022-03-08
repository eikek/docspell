{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Data.EventType exposing
    ( Texts
    , de
    , gb
    , fr
    )

import Data.EventType exposing (EventType(..))


type alias Texts =
    { name : String
    , info : String
    }


gb : EventType -> Texts
gb et =
    case et of
        TagsChanged ->
            { name = "Tags changed"
            , info = "Whenever a tag on an item is added or removed"
            }

        SetFieldValue ->
            { name = "Set field value"
            , info = "Whenever a custom field is set to a value"
            }

        DeleteFieldValue ->
            { name = "Delete field value"
            , info = "Whenever a custom field is removed"
            }

        JobSubmitted ->
            { name = "Job submitted"
            , info = "Whenever a new job is submitted"
            }

        JobDone ->
            { name = "Job done"
            , info = "Whenever a new job finished"
            }


de : EventType -> Texts
de et =
    case et of
        TagsChanged ->
            { name = "Tags geändert"
            , info = "Wenn ein tag hinzugefügt oder entfernt wird"
            }

        SetFieldValue ->
            { name = "Benutzerfeldwert ändert"
            , info = "Wenn für ein Benutzerfeld ein Wert gesetzt wird"
            }

        DeleteFieldValue ->
            { name = "Benutzerfeldwert entfernt"
            , info = "Wenn der Wert für ein Benuzterfeld entfernt wird"
            }

        JobSubmitted ->
            { name = "Auftrag gestartet"
            , info = "Wenn ein neuer Auftrag gestartet wird"
            }

        JobDone ->
            { name = "Auftrag beendet"
            , info = "Wenn ein Auftrag beendet wurde"
            }


fr : EventType -> Texts
fr et =
    case et of
        TagsChanged ->
            { name = "Tags changés"
            , info = "Quand un tag est ajouté ou supprimé d'un document"
            }

        SetFieldValue ->
            { name = "Valeur de champs affectée"
            , info = "Quand une valeur est affectée à un champs personnalisé"
            }

        DeleteFieldValue ->
            { name = "Champs supprimé"
            , info = "Quand un champs personnalisé est supprimé"
            }

        JobSubmitted ->
            { name = "Tâche soumise"
            , info = "Quand une nouvelle tâche est soumise"
            }

        JobDone ->
            { name = "Tâche terminée"
            , info = "Quand une tâche est terminée"
            }
