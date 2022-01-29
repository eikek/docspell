{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages exposing
    ( Messages
    , fromIso2
    , get
    , toIso2
    )

import Messages.App
import Messages.Page.CollectiveSettings
import Messages.Page.Dashboard
import Messages.Page.ItemDetail
import Messages.Page.Login
import Messages.Page.ManageData
import Messages.Page.NewInvite
import Messages.Page.Queue
import Messages.Page.Register
import Messages.Page.Search
import Messages.Page.Share
import Messages.Page.ShareDetail
import Messages.Page.Upload
import Messages.Page.UserSettings
import Messages.UiLanguage exposing (UiLanguage(..))


{-| The messages record contains all strings used in the application.
-}
type alias Messages =
    { lang : UiLanguage
    , iso2 : String
    , label : String
    , flagIcon : String
    , app : Messages.App.Texts
    , collectiveSettings : Messages.Page.CollectiveSettings.Texts
    , login : Messages.Page.Login.Texts
    , register : Messages.Page.Register.Texts
    , newInvite : Messages.Page.NewInvite.Texts
    , upload : Messages.Page.Upload.Texts
    , itemDetail : Messages.Page.ItemDetail.Texts
    , queue : Messages.Page.Queue.Texts
    , userSettings : Messages.Page.UserSettings.Texts
    , manageData : Messages.Page.ManageData.Texts
    , search : Messages.Page.Search.Texts
    , share : Messages.Page.Share.Texts
    , shareDetail : Messages.Page.ShareDetail.Texts
    , dashboard : Messages.Page.Dashboard.Texts
    }


get : UiLanguage -> Messages
get lang =
    case lang of
        English ->
            gb

        German ->
            de


{-| Get a ISO-3166-1 code of the given lanugage.
-}
toIso2 : UiLanguage -> String
toIso2 lang =
    get lang |> .iso2


{-| Return the UiLanguage from given iso2 code. If the iso2 code is not
known, return Nothing.
-}
readIso2 : String -> Maybe UiLanguage
readIso2 iso =
    let
        isIso lang =
            iso == toIso2 lang
    in
    List.filter isIso Messages.UiLanguage.all
        |> List.head


{-| return the language from the given iso2 code. if the iso2 code is
not known, return English as a default.
-}
fromIso2 : String -> UiLanguage
fromIso2 iso =
    readIso2 iso
        |> Maybe.withDefault English



--- Messages Definitions
-- for flag icons, see https://github.com/lipis/flag-icon-css
-- use two classes: flag-icon flag-icon-xx where xx is the two-letter country code


gb : Messages
gb =
    { lang = English
    , iso2 = "gb"
    , label = "English"
    , flagIcon = "flag-icon flag-icon-gb"
    , app = Messages.App.gb
    , collectiveSettings = Messages.Page.CollectiveSettings.gb
    , login = Messages.Page.Login.gb
    , register = Messages.Page.Register.gb
    , newInvite = Messages.Page.NewInvite.gb
    , upload = Messages.Page.Upload.gb
    , itemDetail = Messages.Page.ItemDetail.gb
    , queue = Messages.Page.Queue.gb
    , userSettings = Messages.Page.UserSettings.gb
    , manageData = Messages.Page.ManageData.gb
    , search = Messages.Page.Search.gb
    , share = Messages.Page.Share.gb
    , shareDetail = Messages.Page.ShareDetail.gb
    , dashboard = Messages.Page.Dashboard.gb
    }


de : Messages
de =
    { lang = German
    , iso2 = "de"
    , label = "Deutsch"
    , flagIcon = "flag-icon flag-icon-de"
    , app = Messages.App.de
    , collectiveSettings = Messages.Page.CollectiveSettings.de
    , login = Messages.Page.Login.de
    , register = Messages.Page.Register.de
    , newInvite = Messages.Page.NewInvite.de
    , upload = Messages.Page.Upload.de
    , itemDetail = Messages.Page.ItemDetail.de
    , queue = Messages.Page.Queue.de
    , userSettings = Messages.Page.UserSettings.de
    , manageData = Messages.Page.ManageData.de
    , search = Messages.Page.Search.de
    , share = Messages.Page.Share.de
    , shareDetail = Messages.Page.ShareDetail.de
    , dashboard = Messages.Page.Dashboard.de
    }
