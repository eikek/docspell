{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.TagManage exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.Comp.TagForm
import Messages.Comp.TagTable


type alias Texts =
    { basics : Messages.Basics.Texts
    , tagTable : Messages.Comp.TagTable.Texts
    , tagForm : Messages.Comp.TagForm.Texts
    , httpError : Http.Error -> String
    , createNewTag : String
    , newTag : String
    , reallyDeleteTag : String
    , deleteThisTag : String
    , correctFormErrors : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , tagTable = Messages.Comp.TagTable.gb
    , tagForm = Messages.Comp.TagForm.gb
    , httpError = Messages.Comp.HttpError.gb
    , createNewTag = "Create a new tag"
    , newTag = "New Tag"
    , reallyDeleteTag = "Really delete this tag?"
    , deleteThisTag = "Delete this tag"
    , correctFormErrors = "Please correct the errors in the form."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , tagTable = Messages.Comp.TagTable.de
    , tagForm = Messages.Comp.TagForm.de
    , httpError = Messages.Comp.HttpError.de
    , createNewTag = "Neuen Tag erstellen"
    , newTag = "Neuer Tag"
    , reallyDeleteTag = "Den Tag wirklich löschen?"
    , deleteThisTag = "Tag löschen"
    , correctFormErrors = "Bitte korrigiere die Fehler im Formular."
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , tagTable = Messages.Comp.TagTable.fr
    , tagForm = Messages.Comp.TagForm.fr
    , httpError = Messages.Comp.HttpError.fr
    , createNewTag = "Créer un nouveau tag"
    , newTag = "Nouveau tag"
    , reallyDeleteTag = "Confirmer la suppression du tag ?"
    , deleteThisTag = "Supprimer ce tag"
    , correctFormErrors = "Merci de corriger les erreurs du formulaire"
    }
