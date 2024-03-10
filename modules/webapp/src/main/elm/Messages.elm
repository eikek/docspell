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

import Data.TimeZone exposing (TimeZone)
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
    , timeZone : TimeZone
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


get : UiLanguage -> TimeZone -> Messages
get lang tz =
    case lang of
        English ->
            gb tz

        German ->
            de tz

        French ->
            fr tz


{-| Get a ISO-3166-1 code of the given lanugage.
-}
toIso2 : UiLanguage -> String
toIso2 lang =
    get lang Data.TimeZone.utc |> .iso2


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


gb : TimeZone -> Messages
gb tz =
    { lang = English
    , timeZone = tz
    , iso2 = "gb"
    , label = "English"
    , flagIcon = "fi fi-gb"
    , app = Messages.App.gb
    , collectiveSettings = Messages.Page.CollectiveSettings.gb tz
    , login = Messages.Page.Login.gb
    , register = Messages.Page.Register.gb
    , newInvite = Messages.Page.NewInvite.gb
    , upload = Messages.Page.Upload.gb
    , itemDetail = Messages.Page.ItemDetail.gb tz
    , queue = Messages.Page.Queue.gb tz
    , userSettings = Messages.Page.UserSettings.gb tz
    , manageData = Messages.Page.ManageData.gb tz
    , search = Messages.Page.Search.gb tz
    , share = Messages.Page.Share.gb tz
    , shareDetail = Messages.Page.ShareDetail.gb tz
    , dashboard = Messages.Page.Dashboard.gb tz
    }


de : TimeZone -> Messages
de tz =
    { lang = German
    , timeZone = tz
    , iso2 = "de"
    , label = "Deutsch"
    , flagIcon = "fi fi-de"
    , app = Messages.App.de
    , collectiveSettings = Messages.Page.CollectiveSettings.de tz
    , login = Messages.Page.Login.de
    , register = Messages.Page.Register.de
    , newInvite = Messages.Page.NewInvite.de
    , upload = Messages.Page.Upload.de
    , itemDetail = Messages.Page.ItemDetail.de tz
    , queue = Messages.Page.Queue.de tz
    , userSettings = Messages.Page.UserSettings.de tz
    , manageData = Messages.Page.ManageData.de tz
    , search = Messages.Page.Search.de tz
    , share = Messages.Page.Share.de tz
    , shareDetail = Messages.Page.ShareDetail.de tz
    , dashboard = Messages.Page.Dashboard.de tz
    }


fr : TimeZone -> Messages
fr tz =
    { lang = French
    , timeZone = tz
    , iso2 = "fr"
    , label = "Français"
    , flagIcon = "fi fi-fr"
    , app = Messages.App.fr
    , collectiveSettings = Messages.Page.CollectiveSettings.fr tz
    , login = Messages.Page.Login.fr
    , register = Messages.Page.Register.fr
    , newInvite = Messages.Page.NewInvite.fr
    , upload = Messages.Page.Upload.fr
    , itemDetail = Messages.Page.ItemDetail.fr tz
    , queue = Messages.Page.Queue.fr tz
    , userSettings = Messages.Page.UserSettings.fr tz
    , manageData = Messages.Page.ManageData.fr tz
    , search = Messages.Page.Search.fr tz
    , share = Messages.Page.Share.fr tz
    , shareDetail = Messages.Page.ShareDetail.fr tz
    , dashboard = Messages.Page.Dashboard.fr tz
    }
