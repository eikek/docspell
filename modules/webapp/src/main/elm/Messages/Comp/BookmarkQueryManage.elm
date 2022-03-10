{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.BookmarkQueryManage exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Http
import Messages.Basics
import Messages.Comp.BookmarkQueryForm
import Messages.Comp.HttpError


type alias Texts =
    { basics : Messages.Basics.Texts
    , form : Messages.Comp.BookmarkQueryForm.Texts
    , httpError : Http.Error -> String
    , formInvalid : String
    , saved : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , form = Messages.Comp.BookmarkQueryForm.gb
    , httpError = Messages.Comp.HttpError.gb
    , formInvalid = "Please correct errors in the form"
    , saved = "Bookmark saved"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , form = Messages.Comp.BookmarkQueryForm.de
    , httpError = Messages.Comp.HttpError.de
    , formInvalid = "Bitte korrigiere das Formular"
    , saved = "Bookmark gespeichert"
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , form = Messages.Comp.BookmarkQueryForm.fr
    , httpError = Messages.Comp.HttpError.fr
    , formInvalid = "Veuillez corriger les erreurs du formulaire"
    , saved = "Favori enregistré"
    }
