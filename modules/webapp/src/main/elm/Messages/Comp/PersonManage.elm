{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.PersonManage exposing
    ( Texts
    , de
    , gb
    )

import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.Comp.PersonForm
import Messages.Comp.PersonTable


type alias Texts =
    { basics : Messages.Basics.Texts
    , personForm : Messages.Comp.PersonForm.Texts
    , personTable : Messages.Comp.PersonTable.Texts
    , httpError : Http.Error -> String
    , newPerson : String
    , createNewPerson : String
    , reallyDeletePerson : String
    , deleteThisPerson : String
    , correctFormErrors : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , personForm = Messages.Comp.PersonForm.gb
    , personTable = Messages.Comp.PersonTable.gb
    , httpError = Messages.Comp.HttpError.gb
    , newPerson = "New Person"
    , createNewPerson = "Create a new person"
    , reallyDeletePerson = "Really delete this person?"
    , deleteThisPerson = "Delete this person"
    , correctFormErrors = "Please correct the errors in the form."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , personForm = Messages.Comp.PersonForm.de
    , personTable = Messages.Comp.PersonTable.de
    , httpError = Messages.Comp.HttpError.de
    , newPerson = "Neue Person"
    , createNewPerson = "Neue Person anlegen"
    , reallyDeletePerson = "Die Person wirklich löschen?"
    , deleteThisPerson = "Person löschen"
    , correctFormErrors = "Bitte korrigiere die Fehler im Formular."
    }
