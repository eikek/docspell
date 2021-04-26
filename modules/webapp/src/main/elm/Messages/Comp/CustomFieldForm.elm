module Messages.Comp.CustomFieldForm exposing (Texts, gb)

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
