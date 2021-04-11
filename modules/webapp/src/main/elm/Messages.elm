module Messages exposing
    ( Messages
    , fromIso2
    , get
    , toIso2
    )

import Messages.App
import Messages.Page.CollectiveSettings
import Messages.Page.Home
import Messages.Page.ItemDetail
import Messages.Page.Login
import Messages.Page.ManageData
import Messages.Page.NewInvite
import Messages.Page.Queue
import Messages.Page.Register
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
    , home : Messages.Page.Home.Texts
    }


get : UiLanguage -> Messages
get lang =
    case lang of
        English ->
            gb


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
    , home = Messages.Page.Home.gb
    }
