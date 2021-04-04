module Messages.PersonFormComp exposing (..)

import Data.ContactType exposing (ContactType)
import Data.PersonUse exposing (PersonUse)
import Messages.AddressFormComp
import Messages.ContactTypeData
import Messages.PersonUseData


type alias Texts =
    { addressForm : Messages.AddressFormComp.Texts
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
    { addressForm = Messages.AddressFormComp.gb
    , personUseLabel = Messages.PersonUseData.gb
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
    , contactTypeLabel = Messages.ContactTypeData.gb
    , notes = "Notes"
    }
