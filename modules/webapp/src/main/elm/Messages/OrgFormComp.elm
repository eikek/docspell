module Messages.OrgFormComp exposing (..)

import Data.ContactType exposing (ContactType)
import Data.OrgUse exposing (OrgUse)
import Messages.AddressFormComp
import Messages.ContactTypeData
import Messages.OrgUseData


type alias Texts =
    { addressForm : Messages.AddressFormComp.Texts
    , orgUseLabel : OrgUse -> String
    , name : String
    , shortName : String
    , use : String
    , useAsCorrespondent : String
    , dontUseForSuggestions : String
    , address : String
    , contacts : String
    , contactTypeLabel : ContactType -> String
    , notes : String
    }


gb : Texts
gb =
    { addressForm = Messages.AddressFormComp.gb
    , orgUseLabel = Messages.OrgUseData.gb
    , name = "Name"
    , shortName = "Short Name"
    , use = "Use"
    , useAsCorrespondent = "Use as correspondent"
    , dontUseForSuggestions = "Do not use for suggestions."
    , address = "Address"
    , contacts = "Contacts"
    , contactTypeLabel = Messages.ContactTypeData.gb
    , notes = "Notes"
    }
