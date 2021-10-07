{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Page.Share exposing (..)

import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.Comp.ItemCardList
import Messages.Comp.SearchMenu
import Messages.Comp.SharePasswordForm


type alias Texts =
    { searchMenu : Messages.Comp.SearchMenu.Texts
    , basics : Messages.Basics.Texts
    , itemCardList : Messages.Comp.ItemCardList.Texts
    , passwordForm : Messages.Comp.SharePasswordForm.Texts
    , httpError : Http.Error -> String
    , authFailed : String
    }


gb : Texts
gb =
    { searchMenu = Messages.Comp.SearchMenu.gb
    , basics = Messages.Basics.gb
    , itemCardList = Messages.Comp.ItemCardList.gb
    , passwordForm = Messages.Comp.SharePasswordForm.gb
    , authFailed = "This share does not exist."
    , httpError = Messages.Comp.HttpError.gb
    }


de : Texts
de =
    { searchMenu = Messages.Comp.SearchMenu.de
    , basics = Messages.Basics.de
    , itemCardList = Messages.Comp.ItemCardList.de
    , passwordForm = Messages.Comp.SharePasswordForm.de
    , authFailed = "Diese Freigabe existiert nicht."
    , httpError = Messages.Comp.HttpError.de
    }
