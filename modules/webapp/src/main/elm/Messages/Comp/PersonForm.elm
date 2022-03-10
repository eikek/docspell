{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.PersonForm exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Data.ContactType exposing (ContactType)
import Data.PersonUse exposing (PersonUse)
import Messages.Basics
import Messages.Comp.AddressForm
import Messages.Data.ContactType
import Messages.Data.PersonUse


type alias Texts =
    { basics : Messages.Basics.Texts
    , addressForm : Messages.Comp.AddressForm.Texts
    , personUseLabel : PersonUse -> String
    , useOfPerson : String
    , useAsConcerningOnly : String
    , useAsCorrespondentOnly : String
    , useAsBoth : String
    , dontUseForSuggestions : String
    , chooseAnOrg : String
    , address : String
    , contacts : String
    , contactTypeLabel : ContactType -> String
    , notes : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , addressForm = Messages.Comp.AddressForm.gb
    , personUseLabel = Messages.Data.PersonUse.gb
    , useOfPerson = "Use of this person"
    , useAsConcerningOnly = "Use as concerning person only"
    , useAsCorrespondentOnly = "Use as correspondent person only"
    , useAsBoth = "Use as both concerning or correspondent person"
    , dontUseForSuggestions = "Do not use for suggestions."
    , chooseAnOrg = "Choose an organization"
    , address = "Address"
    , contacts = "Contacts"
    , contactTypeLabel = Messages.Data.ContactType.gb
    , notes = "Notes"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , addressForm = Messages.Comp.AddressForm.de
    , personUseLabel = Messages.Data.PersonUse.de
    , useOfPerson = "Wie diese Person verwendet werden soll"
    , useAsConcerningOnly = "Nur als betreffende Person verwenden"
    , useAsCorrespondentOnly = "Nur als Korrespondent verwenden"
    , useAsBoth = "Als Betreffend und Korrespondent verwenden"
    , dontUseForSuggestions = "Nicht für Vorschläge verwenden"
    , chooseAnOrg = "Wähle eine Organisation"
    , address = "Addresse"
    , contacts = "Kontakte"
    , contactTypeLabel = Messages.Data.ContactType.de
    , notes = "Notizen"
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , addressForm = Messages.Comp.AddressForm.fr
    , personUseLabel = Messages.Data.PersonUse.fr
    , useOfPerson = "Rôle de cette personne"
    , useAsConcerningOnly = "Concernée uniquement"
    , useAsCorrespondentOnly = "Correspondante uniquement"
    , useAsBoth = "Concernée et correspondante"
    , dontUseForSuggestions = "ignorer des suggestions."
    , chooseAnOrg = "Choisir une organisation"
    , address = "Addresse"
    , contacts = "Contacts"
    , contactTypeLabel = Messages.Data.ContactType.fr
    , notes = "Notes"
    }
