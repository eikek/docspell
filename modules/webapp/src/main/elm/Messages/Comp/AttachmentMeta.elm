module Messages.Comp.AttachmentMeta exposing (..)

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
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
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
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
    }
