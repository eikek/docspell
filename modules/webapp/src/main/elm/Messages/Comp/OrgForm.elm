module Messages.Comp.OrgForm exposing (..)

import Data.ContactType exposing (ContactType)
import Data.OrgUse exposing (OrgUse)
import Messages.Comp.AddressForm
import Messages.Data.ContactType
import Messages.Data.OrgUse


type alias Texts =
    { addressForm : Messages.Comp.AddressForm.Texts
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
    { addressForm = Messages.Comp.AddressForm.gb
    , orgUseLabel = Messages.Data.OrgUse.gb
    , name = "Name"
    , shortName = "Short Name"
    , use = "Use"
    , useAsCorrespondent = "Use as correspondent"
    , dontUseForSuggestions = "Do not use for suggestions."
    , address = "Address"
    , contacts = "Contacts"
    , contactTypeLabel = Messages.Data.ContactType.gb
    , notes = "Notes"
    }
