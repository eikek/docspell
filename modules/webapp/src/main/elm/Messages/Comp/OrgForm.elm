{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Messages.Comp.OrgForm exposing
    ( Texts
    , de
    , gb
    )

import Data.ContactType exposing (ContactType)
import Data.OrgUse exposing (OrgUse)
import Messages.Basics
import Messages.Comp.AddressForm
import Messages.Data.ContactType
import Messages.Data.OrgUse


type alias Texts =
    { basics : Messages.Basics.Texts
    , addressForm : Messages.Comp.AddressForm.Texts
    , orgUseLabel : OrgUse -> String
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
    { basics = Messages.Basics.gb
    , addressForm = Messages.Comp.AddressForm.gb
    , orgUseLabel = Messages.Data.OrgUse.gb
    , shortName = "Short Name"
    , use = "Use"
    , useAsCorrespondent = "Use as correspondent"
    , dontUseForSuggestions = "Do not use for suggestions."
    , address = "Address"
    , contacts = "Contacts"
    , contactTypeLabel = Messages.Data.ContactType.gb
    , notes = "Notes"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , addressForm = Messages.Comp.AddressForm.de
    , orgUseLabel = Messages.Data.OrgUse.de
    , shortName = "Kurzname"
    , use = "Art"
    , useAsCorrespondent = "Als Korrespondent verwenden"
    , dontUseForSuggestions = "Nicht für Vorschläge verwenden."
    , address = "Addresse"
    , contacts = "Kontakte"
    , contactTypeLabel = Messages.Data.ContactType.de
    , notes = "Notizen"
    }
