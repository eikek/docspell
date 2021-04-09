module Messages.Comp.PersonForm exposing (..)

import Data.ContactType exposing (ContactType)
import Data.PersonUse exposing (PersonUse)
import Messages.Comp.AddressForm
import Messages.Data.ContactType
import Messages.Data.PersonUse


type alias Texts =
    { addressForm : Messages.Comp.AddressForm.Texts
    , personUseLabel : PersonUse -> String
    , name : String
    , useOfPerson : String
    , useAsConcerningOnly : String
    , useAsCorrespondentOnly : String
    , useAsBoth : String
    , dontUseForSuggestions : String
    , organization : String
    , chooseAnOrg : String
    , address : String
    , contacts : String
    , contactTypeLabel : ContactType -> String
    , notes : String
    }


gb : Texts
gb =
    { addressForm = Messages.Comp.AddressForm.gb
    , personUseLabel = Messages.Data.PersonUse.gb
    , name = "Name"
    , useOfPerson = "Use of this person"
    , useAsConcerningOnly = "Use as concerning person only"
    , useAsCorrespondentOnly = "Use as correspondent person only"
    , useAsBoth = "Use as both concerning or correspondent person"
    , dontUseForSuggestions = "Do not use for suggestions."
    , organization = "Organization"
    , chooseAnOrg = "Choose an organization"
    , address = "Address"
    , contacts = "Contacts"
    , contactTypeLabel = Messages.Data.ContactType.gb
    , notes = "Notes"
    }
