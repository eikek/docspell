{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.CustomFieldForm exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Data.CustomFieldType exposing (CustomFieldType)
import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.Data.CustomFieldType


type alias Texts =
    { basics : Messages.Basics.Texts
    , reallyDeleteField : String
    , fieldTypeLabel : CustomFieldType -> String
    , httpError : Http.Error -> String
    , createCustomField : String
    , modifyTypeWarning : String
    , nameInfo : String
    , fieldFormat : String
    , fieldFormatInfo : String
    , label : String
    , labelInfo : String
    , deleteThisField : String
    , fieldNameRequired : String
    , fieldTypeRequired : String
    , updateSuccessful : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , reallyDeleteField = "Really delete this custom field?"
    , fieldTypeLabel = Messages.Data.CustomFieldType.gb
    , httpError = Messages.Comp.HttpError.gb
    , createCustomField = "Create a new custom field."
    , modifyTypeWarning =
        "Note that changing the format may "
            ++ "result in invisible values in the ui, if they don't comply to the new format!"
    , nameInfo =
        "The name uniquely identifies this field. It must be a valid "
            ++ "identifier, not contain spaces or weird characters."
    , fieldFormat = "Field Format"
    , fieldFormatInfo =
        "A field must have a format. Values are validated "
            ++ "according to this format."
    , label = "Label"
    , labelInfo =
        "The user defined label for this field. This is used to represent "
            ++ "this field in the ui. If not present, the name is used."
    , deleteThisField = "Delete this field"
    , fieldNameRequired = "A name is required."
    , fieldTypeRequired = "A type is required."
    , updateSuccessful = "Field has been saved."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , reallyDeleteField = "Das Benutzerfeld wirklich löschen?"
    , fieldTypeLabel = Messages.Data.CustomFieldType.de
    , httpError = Messages.Comp.HttpError.de
    , createCustomField = "Ein neues Benutzerfeld erstellen."
    , modifyTypeWarning =
        "Beachte, dass eine Änderung im Format zu nicht sichtbaren Werten führen kann, falls diese dem "
            ++ "neuen Format nicht entsprechen!"
    , nameInfo =
        "Der Name des Feldes identifiziert es eindeutig und wird in erweiterten Suchanfragen "
            ++ "verwendet. Es muss eine gültige ID sein, darf also keine Leerzeichen oder "
            ++ "Sonderzeichen enthalten."
    , fieldFormat = "Feldformat"
    , fieldFormatInfo =
        "Ein Feld muss ein Format haben. Werte werden dagegen validiert."
    , label = "Bezeichnung"
    , labelInfo =
        "Diese Bezeichnung erscheint in der Benutzeroberfläche für dieses Feld. Es kann im Gegensatz zum Namen "
            ++ "Leer- und Sonderzeichen enthalten. Falls nicht angegeben, wird der Name verwendet."
    , deleteThisField = "Dieses Feld löschen"
    , fieldNameRequired = "Ein Name ist erforderlich."
    , fieldTypeRequired = "Ein Format ist erforderlich."
    , updateSuccessful = "Das Feld wurde gespeichert."
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , reallyDeleteField = "Confirmer la suppression de ce champs ?"
    , fieldTypeLabel = Messages.Data.CustomFieldType.fr
    , httpError = Messages.Comp.HttpError.fr
    , createCustomField = "Créer un champs personnalisé."
    , modifyTypeWarning =
        "Le changement de format peut rendre certaines valeurs invisibles"
            ++ " si elles ne respectent pas le nouveau format !"
    , nameInfo =
        "Le nom propre de ce champs. Cela doit être un identifiant "
            ++ "valide et ne contenir ni espace ni charactères spéciaux."
    , fieldFormat = "Format du champs"
    , fieldFormatInfo =
        "Un champs doit avoir un format. Les valeurs sont validées"
            ++ " selon ce format."
    , label = "Label"
    , labelInfo =
        "Label utilisateur de ce champs. Utilisé dans l'UI."
            ++ "si absent, le nom est utilisé"
    , deleteThisField = "Supprimer ce champs"
    , fieldNameRequired = "Nom  requis."
    , fieldTypeRequired = "Type requis."
    , updateSuccessful = "Champs enregistré."
    }
