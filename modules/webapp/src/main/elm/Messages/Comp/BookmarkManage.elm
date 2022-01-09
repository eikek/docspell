{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.BookmarkManage exposing
    ( Texts
    , de
    , gb
    )

import Http
import Messages.Basics
import Messages.Comp.BookmarkQueryForm
import Messages.Comp.BookmarkTable
import Messages.Comp.HttpError


type alias Texts =
    { basics : Messages.Basics.Texts
    , bookmarkTable : Messages.Comp.BookmarkTable.Texts
    , bookmarkForm : Messages.Comp.BookmarkQueryForm.Texts
    , httpError : Http.Error -> String
    , newBookmark : String
    , reallyDeleteBookmark : String
    , createNewBookmark : String
    , deleteThisBookmark : String
    , correctFormErrors : String
    , userBookmarks : String
    , collectiveBookmarks : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , bookmarkTable = Messages.Comp.BookmarkTable.gb
    , bookmarkForm = Messages.Comp.BookmarkQueryForm.gb
    , httpError = Messages.Comp.HttpError.gb
    , newBookmark = "New bookmark"
    , reallyDeleteBookmark = "Really delete this bookmark?"
    , createNewBookmark = "Create new bookmark"
    , deleteThisBookmark = "Delete this bookmark"
    , correctFormErrors = "Please correct the errors in the form."
    , userBookmarks = "Personal bookmarks"
    , collectiveBookmarks = "Collective bookmarks"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , bookmarkTable = Messages.Comp.BookmarkTable.de
    , bookmarkForm = Messages.Comp.BookmarkQueryForm.de
    , httpError = Messages.Comp.HttpError.de
    , newBookmark = "Neue Freigabe"
    , reallyDeleteBookmark = "Diese Freigabe wirklich entfernen?"
    , createNewBookmark = "Neue Freigabe erstellen"
    , deleteThisBookmark = "Freigabe löschen"
    , correctFormErrors = "Bitte korrigiere die Fehler im Formular."
    , userBookmarks = "Persönliche Bookmarks"
    , collectiveBookmarks = "Kollektivbookmarks"
    }
