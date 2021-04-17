module Messages.Comp.AttachmentMeta exposing (Texts, gb)

import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.DateFormat as DF
import Messages.UiLanguage


type alias Texts =
    { basics : Messages.Basics.Texts
    , httpError : Http.Error -> String
    , extractedMetadata : String
    , content : String
    , labels : String
    , proposals : String
    , correspondentOrg : String
    , correspondentPerson : String
    , concerningPerson : String
    , concerningEquipment : String
    , itemDate : String
    , itemDueDate : String
    , formatDateShort : Int -> String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , httpError = Messages.Comp.HttpError.gb
    , extractedMetadata = "Extracted Meta Data"
    , content = "Content"
    , labels = "Labels"
    , proposals = "Proposals"
    , correspondentOrg = "Correspondent Organization"
    , correspondentPerson = "Correspondent Person"
    , concerningPerson = "Concerning Person"
    , concerningEquipment = "Concerning Equipment"
    , itemDate = "Item Date"
    , itemDueDate = "Item Due Date"
    , formatDateShort = DF.formatDateShort Messages.UiLanguage.English
    }
