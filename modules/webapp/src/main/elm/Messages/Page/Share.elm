{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Page.Share exposing (..)

import Messages.Basics
import Messages.Comp.ItemCardList
import Messages.Comp.SearchMenu


type alias Texts =
    { searchMenu : Messages.Comp.SearchMenu.Texts
    , basics : Messages.Basics.Texts
    , itemCardList : Messages.Comp.ItemCardList.Texts
    , passwordRequired : String
    , password : String
    , passwordSubmitButton : String
    , passwordFailed : String
    }


gb : Texts
gb =
    { searchMenu = Messages.Comp.SearchMenu.gb
    , basics = Messages.Basics.gb
    , itemCardList = Messages.Comp.ItemCardList.gb
    , passwordRequired = "Password required"
    , password = "Password"
    , passwordSubmitButton = "Submit"
    , passwordFailed = "Das Passwort ist falsch"
    }


de : Texts
de =
    { searchMenu = Messages.Comp.SearchMenu.de
    , basics = Messages.Basics.de
    , itemCardList = Messages.Comp.ItemCardList.de
    , passwordRequired = "Passwort benötigt"
    , password = "Passwort"
    , passwordSubmitButton = "Submit"
    , passwordFailed = "Password is wrong"
    }
